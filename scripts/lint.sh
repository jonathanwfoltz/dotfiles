#!/usr/bin/env bash
# stylua, shellcheck, a tmux parse and the status-line glyph count.
# A missing tool is skipped with a warning, or fails when STRICT=1.
set -uo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=scripts/lib.sh
. "$root/scripts/lib.sh"
cd "$root" || exit 1

failed=0

missing() {
  if [ "${STRICT:-}" = 1 ]; then
    fail "$1: not installed (STRICT=1)"
    failed=1
  else
    warn "$1: not installed, skipped"
  fi
}

# Tracked plus untracked-but-not-ignored, so new files are linted before
# they are committed.
files() {
  git ls-files -z --cached --others --exclude-standard -- "$@"
}

if have stylua; then
  # NOTE: given explicitly -- `stylua .` skips hidden directories, and every
  # Lua file in the config sits under nvim/.config.
  if files '*.lua' | xargs -0 stylua --check; then
    ok stylua
  else
    fail "stylua: fix with: git ls-files -z '*.lua' | xargs -0 stylua"
    failed=1
  fi
else
  missing stylua
fi

if have shellcheck; then
  sc_ok=1
  files '*.sh' | xargs -0 -r shellcheck -x || sc_ok=0
  # The bash package's files carry no shebang.
  files 'bash/' | xargs -0 -r shellcheck -x --shell=bash || sc_ok=0
  if [ "$sc_ok" = 1 ]; then ok shellcheck; else
    fail shellcheck
    failed=1
  fi
else
  missing shellcheck
fi

conf=tmux/.config/tmux/tmux.conf
if have tmux; then
  sock=dotfiles-lint-$$
  if tmux -L "$sock" -f /dev/null start-server \; source-file "$conf"; then
    ok "tmux parses $conf"
  else
    fail "tmux: $conf"
    failed=1
  fi
  tmux -L "$sock" kill-server 2>/dev/null
else
  missing tmux
fi

# The HACK: comment in tmux.conf says why these counts are fixed.
count() { LC_ALL=C grep -o "$1" "$conf" | wc -l; }
right=$(count $'\xee\x82\xb0')
left=$(count $'\xee\x82\xb2')
if [ "$right" -eq 3 ] && [ "$left" -eq 4 ]; then
  ok 'tmux.conf glyphs: 3 U+E0B0, 4 U+E0B2'
else
  fail "tmux.conf glyphs: $right U+E0B0 (want 3), $left U+E0B2 (want 4); restore them from git"
  failed=1
fi

exit "$failed"
