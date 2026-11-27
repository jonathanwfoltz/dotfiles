# shellcheck shell=bash
# Login shells read only this file, so it hands over to ~/.bashrc.
if [ -r "$HOME/.bashrc" ]; then
  # shellcheck source=/dev/null
  . "$HOME/.bashrc"
fi
