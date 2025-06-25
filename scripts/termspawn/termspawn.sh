#!/usr/bin/env bash

# on error we cd to HOME dir, so do not abort on error
set +e
set +o pipefail

PID=$(pstree -p "$(xdotool getwindowfocus getwindowpid)" | grep -m 1 zsh | grep -Eo '[0-9]+')
DIR=$(readlink -e /proc/"${PID}"/cwd)
[[ ! -d $DIR ]] && DIR="$HOME"
exec kitty --directory "$DIR"
