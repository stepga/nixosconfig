#!/usr/bin/env bash

set -e errexit
set -o nounset
set -o pipefail

run_detached() {
	nohup "$@" </dev/null >/dev/null 2>&1 &
	disown
}

TERM_EXEC="kitty"
CD_PATH="$HOME"
WM_CLASS=""

XPROP_ID="$(xprop -root _NET_ACTIVE_WINDOW | awk '{print $NF}')"
if [[ "$XPROP_ID" =~ ^0x[0-9a-f]{2,}$ ]]; then
	WM_CLASS="$(xprop -id "$XPROP_ID" WM_CLASS | cut --delimiter='"' --fields=2)"
fi

if [[ "$WM_CLASS" == "$TERM_EXEC" ]]; then
	TERM_PID="$(xprop -id "$XPROP_ID" _NET_WM_PID | awk '{print $NF}')"

	# check childprocesses for running a shell
	for CHILD_PID in $(pgrep -P "$TERM_PID"); do
		CWD_PATH="$(readlink -e "/proc/$CHILD_PID/cwd")"
		if [[ -d "$CWD_PATH" ]]; then
			CD_PATH="$CWD_PATH"
			break
		fi
	done
fi

run_detached $TERM_EXEC --directory -cd "$CD_PATH"
