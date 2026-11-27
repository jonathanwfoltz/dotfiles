#!/usr/bin/env bash
# Loads the nvim config from this checkout headless and fails on any load
# error, then checks every plugin is at its lockfile revision. Nothing is
# written outside a temporary directory except a lockfile vim.pack rewrites,
# which the last step reports.
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=scripts/lib.sh
. "$root/scripts/lib.sh"

if ! have nvim; then
  fail 'nvim: not installed'
  exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

unset NVIM_APPNAME VIMINIT
export XDG_CONFIG_HOME="$root/nvim/.config"
export XDG_DATA_HOME="$tmp/data" XDG_STATE_HOME="$tmp/state" XDG_CACHE_HOME="$tmp/cache"
# Parser builds are async and outlive the 'later' queue.
export CHECK_GRACE_MS="${CHECK_GRACE_MS:-30000}"

nvim --headless --cmd "luafile $root/scripts/nvim-check.lua"

# NOTE: vim.pack does not report a failed checkout of a locked revision.
lock="$XDG_CONFIG_HOME/nvim/nvim-pack-lock.json"
nvim --headless --clean -l "$root/scripts/nvim-revcheck.lua" \
  "$lock" "$XDG_DATA_HOME/nvim/site/pack/core/opt"
ok 'plugins at their lockfile revisions'

# A spec added without updating the lockfile makes vim.pack rewrite it.
if git -C "$root" diff --exit-code -- "$lock"; then
  ok 'lockfile unchanged'
else
  fail 'vim.pack rewrote the lockfile; commit it or fix the spec'
  exit 1
fi
