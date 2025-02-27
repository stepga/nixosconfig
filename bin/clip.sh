#!/usr/bin/env nix-shell
#!nix-shell --verbose -i bash -p xclip imagemagick
set -eu

TMP_FILE=/tmp/clip.png
import "${TMP_FILE}"
xclip -t image/png -selection clipboard < "${TMP_FILE}"
