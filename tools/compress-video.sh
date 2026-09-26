#!/usr/bin/env bash
# Compress a background video for the invitation.
#
#   ./tools/compress-video.sh path/to/original.mp4
#
# Writes bg.mp4 (H.264, plays everywhere) and bg.webm (VP9, smaller on
# Android/Chrome) next to Index.html. Audio is removed, the short side is
# capped at 720px, frame rate at 24fps, and the mp4 is set to start playing
# before it has fully downloaded.
set -euo pipefail

IN="${1:?usage: $0 <input-video>}"
OUT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FFMPEG="${FFMPEG:-ffmpeg}"
MAX_SECONDS="${MAX_SECONDS:-20}"   # background loops, so a short clip is plenty

# short side -> 720px, keep aspect ratio, even dimensions
SCALE="scale='if(gt(iw,ih),-2,min(720,iw))':'if(gt(iw,ih),min(720,ih),-2)',fps=24"

"$FFMPEG" -y -hide_banner -loglevel error -i "$IN" -t "$MAX_SECONDS" -an \
  -vf "$SCALE" -c:v libx264 -preset slow -crf 28 -profile:v high -pix_fmt yuv420p \
  -movflags +faststart "$OUT_DIR/bg.mp4"

"$FFMPEG" -y -hide_banner -loglevel error -i "$IN" -t "$MAX_SECONDS" -an \
  -vf "$SCALE" -c:v libvpx-vp9 -crf 40 -b:v 0 -row-mt 1 -deadline good -cpu-used 2 \
  "$OUT_DIR/bg.webm"

# the page tries bg.webm first, so only keep it when it is actually smaller
if [ "$(wc -c < "$OUT_DIR/bg.webm")" -ge "$(wc -c < "$OUT_DIR/bg.mp4")" ]; then
  rm "$OUT_DIR/bg.webm"
  echo "bg.webm was not smaller than bg.mp4 — removed it"
fi

ls -lh "$IN" "$OUT_DIR"/bg.mp4 "$OUT_DIR"/bg.webm 2>/dev/null || true
