#!/bin/sh
# Attach to the server session, creating it if it does not exist.
exec tmux new -A -s server
