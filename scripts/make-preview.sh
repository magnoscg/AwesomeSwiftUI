#!/bin/sh
# Turns a recording into the animated WebP preview of a component, and that
# into its social card. It goes
# through PNG frames because many ffmpeg builds have no WebP encoder.
set -eu

if [ "$#" -ne 2 ]; then
  echo "Usage: scripts/make-preview.sh <recording> <output.webp>" >&2
  exit 2
fi

recording=$1
output=$2
frames=$(mktemp -d)
trap 'rm -rf "$frames"' EXIT

ffmpeg -y -loglevel error -i "$recording" \
  -vf "fps=20,scale=320:-2:flags=lanczos" "$frames/frame%04d.png"
# Frequent key frames and -exact keep gradients free of blocks and ghost rectangles.
img2webp -loop 0 -kmax 2 -lossy -q 60 -exact -d 50 "$frames"/frame*.png -o "$output"
sh "$(dirname "$0")/make-card.sh" "$output" "${output%.webp}.jpg"
