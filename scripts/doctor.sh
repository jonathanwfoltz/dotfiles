#!/usr/bin/env bash
# Reports prerequisites and stow links. Never installs anything.
# Usage: scripts/doctor.sh PACKAGE...
set -uo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=scripts/lib.sh
. "$root/scripts/lib.sh"

failed=0

# require NAME MIN COMMAND...: COMMAND's output holds the version.
require() {
  local name=$1 min=$2 version
  shift 2
  if ! have "$1"; then
    fail "$name: not found (need >= $min)"
    failed=1
    return
  fi
  version=$("$@" 2>&1 | first_version)
  if [ -z "$version" ]; then
    fail "$name: cannot read a version from '$*' (need >= $min)"
    failed=1
  elif version_ge "$version" "$min"; then
    ok "$name $version"
  else
    fail "$name $version: need >= $min"
    failed=1
  fi
}

require_cmd() {
  local name=$1
  shift
  local c
  for c in "$@"; do
    if have "$c"; then
      ok "$name ($c)"
      return
    fi
  done
  fail "$name: none of $* found"
  failed=1
}

optional() {
  local name=$1
  shift
  local c
  for c in "$@"; do
    if have "$c"; then
      ok "$name ($c)"
      return 0
    fi
  done
  info "$name: not installed (optional)"
  return 1
}

echo 'Required'
require nvim 0.12 nvim --version
require tmux 3.3 tmux -V
require bash 4.4 bash --version
require_cmd stow stow
require git 2.38 git --version
require tree-sitter-cli 0.26.1 tree-sitter --version
require_cmd 'C compiler' cc gcc clang
require_cmd node node
require_cmd npm npm
if have python3 && python3 -c 'import venv, ensurepip' 2>/dev/null; then
  ok 'python3 + venv'
else
  fail 'python3 + venv: need python3 with the venv and ensurepip modules (Debian: python3-venv)'
  failed=1
fi
require_cmd curl curl
require_cmd unzip unzip

echo 'Optional'
if optional fzf fzf; then
  if fzf --bash >/dev/null 2>&1; then
    ok 'fzf --bash works'
  else
    info 'fzf --bash: unsupported by this fzf (needs 0.48 or newer)'
  fi
fi
optional zoxide zoxide
optional bat bat batcat
optional fd fd fdfind
optional ripgrep rg
optional stylua stylua
optional shellcheck shellcheck

echo 'Environment'
charmap=$(locale charmap 2>/dev/null)
if [ "$charmap" = UTF-8 ]; then
  ok 'UTF-8 locale'
else
  warn "locale charmap is '${charmap:-unknown}', not UTF-8: glyphs in tmux and nvim will break"
fi

echo 'Links'
for pkg in "$@"; do
  # NOTE: without ~/.gitconfig, `git config --global` writes identity into
  # the stowed, tracked config.
  if [ "$pkg" = git ] && [ ! -e "$HOME/.gitconfig" ]; then
    warn 'git: ~/.gitconfig is missing; touch it before setting your identity'
  fi
  if [ ! -d "$root/$pkg" ]; then
    fail "$pkg: no such package in $root"
    failed=1
    continue
  fi
  linked=0 missing=0 foreign=()
  while IFS= read -r -d '' file; do
    target=$HOME/${file#"$pkg"/}
    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
      missing=$((missing + 1))
    elif [ "$(realpath "$target")" = "$(realpath "$root/$file")" ]; then
      linked=$((linked + 1))
    else
      foreign+=("${target/#"$HOME"/\~}")
    fi
  done < <(git -C "$root" ls-files -z --cached --others --exclude-standard -- "$pkg")

  if [ ${#foreign[@]} -gt 0 ]; then
    warn "$pkg: ${#foreign[@]} path(s) not from this checkout, so stow will refuse: ${foreign[*]}"
  elif [ "$linked" -eq 0 ]; then
    info "$pkg: not stowed"
  elif [ "$missing" -gt 0 ]; then
    warn "$pkg: $missing file(s) not linked; re-run make stow"
  else
    ok "$pkg: linked into $root"
  fi
done

exit "$failed"
