#!/bin/sh
# Turns the animated preview of a component into the still image its page
# shows when it is shared: the middle frame, at its own size, centred on a
# 1200×630 card. The middle skips the first frames, which can be blank while
# a demo starts.
set -eu

if [ "$#" -ne 2 ]; then
  echo "Usage: scripts/make-card.sh <preview.webp> <output.jpg>" >&2
  exit 2
fi

preview=$1
output=$2
frames=$(webpmux -info "$preview" | sed -n 's/^Number of frames: *//p')
middle=$(( ${frames:-1} / 2 ))
frame=$(mktemp -d)
trap 'rm -rf "$frame"' EXIT

# Two steps, because ffmpeg composes an animated WebP over a background as blank frames.
ffmpeg -y -loglevel error -i "$preview" -vf "select=eq(n\,$middle)" -frames:v 1 "$frame/frame.png"
ffmpeg -y -loglevel error -i "$frame/frame.png" \
  -vf "scale=-2:'min(ih,580)':flags=lanczos,pad=1200:630:(ow-iw)/2:(oh-ih)/2:color=0x0b0b0c" \
  -q:v 3 "$output"
