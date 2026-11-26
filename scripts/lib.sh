# shellcheck shell=bash
# Sourced by the other scripts. Output helpers and a version comparison.

ok() { printf '  ok    %s\n' "$*"; }
info() { printf '  --    %s\n' "$*"; }
warn() { printf '  warn  %s\n' "$*"; }
fail() { printf '  FAIL  %s\n' "$*"; }

have() { command -v "$1" >/dev/null 2>&1; }

# version_ge HAVE WANT: true when HAVE >= WANT, comparing dotted numbers.
version_ge() {
  [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

# The first dotted version number in stdin, e.g. "tmux 3.3a" -> 3.3.
first_version() {
  grep -oE '[0-9]+(\.[0-9]+)+' | head -n1
}
