#!/usr/bin/env bash

set -eu

TMP_FILE=/tmp/clip.png
import "${TMP_FILE}"
xclip -t image/png -selection clipboard < "${TMP_FILE}"
