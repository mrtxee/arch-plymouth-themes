#!/usr/bin/env bash
# tools/make-preview.sh - render the animated APNG previews in preview/.
#
# Copyright (C) 2026 Mr Txee (mrtxee)
# SPDX-License-Identifier: GPL-2.0-only
#
# Distributed under the GNU GPL v2; see LICENSE in the project root for the
# full text. Not affiliated with or endorsed by Arch Linux. "Arch Linux" and
# the Arch Linux logo are trademarks of the Arch Linux project.
#
# Render animated previews (APNG) that reproduce each theme's .script layout:
# black background, splash-arch.png centered 1:1, spinner at 3/7 below the logo.
# Frame delay = spin_div redraws at ~60 Hz, exactly as the script plugin does.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/preview"
W=1280 H=800 FPS=60

# theme:frame_count:spin_div
THEMES=(
  "arch-boot-spinner:24:4"
  "arch-boot-orbital-dot:36:3"
  "arch-boot-dots:9:6"
)

command -v magick  >/dev/null || { echo "ImageMagick required" >&2; exit 1; }
command -v ffmpeg  >/dev/null || { echo "ffmpeg required" >&2; exit 1; }
mkdir -p "$OUT"

for entry in "${THEMES[@]}"; do
  IFS=: read -r theme frame_count spin_div <<<"$entry"
  src="$ROOT/$theme"
  frames="$OUT/.$theme.frames"
  rm -rf "$frames"; mkdir -p "$frames"

  # Same math as the .script files (integer pixels).
  logo_w=566 logo_h=167
  logo_x=$(( (W - logo_w) / 2 ))
  logo_y=$(( (H - logo_h) / 2 ))
  logo_bottom=$(( logo_y + logo_h ))
  spin_w=$(magick identify -format '%w' "$src/spin-0.png")
  spin_h=$(magick identify -format '%h' "$src/spin-0.png")
  spin_x=$(( (W - spin_w) / 2 ))
  spin_y=$(( logo_bottom + (H - logo_bottom) * 3 / 7 ))

  tmp="$OUT/.$theme.frames"
  rm -rf "$tmp"; mkdir -p "$tmp"

  for i in $(seq 0 $(( frame_count - 1 ))); do
    magick -size "${W}x${H}" xc:black \
      "$src/splash-arch.png" -geometry +${logo_x}+${logo_y} -composite \
      "$src/spin-$i.png"   -geometry +${spin_x}+${spin_y}   -composite \
      "$tmp/$(printf '%03d' "$i").png"
  done

  rate=$(awk -v d="$spin_div" -v f="$FPS" 'BEGIN{printf "%.4f", f/d}')
  ffmpeg -hide_banner -loglevel error -y \
    -framerate "$rate" -i "$tmp/%03d.png" \
    -plays 0 "$OUT/$theme.apng"
  rm -rf "$tmp"
  echo "built preview/$theme.apng  (frames=$frame_count delay=${spin_div}x redraws @${FPS}Hz)"
done
