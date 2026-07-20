#!/usr/bin/env bash
hyprctl activeworkspace | awk '/workspace ID/ {print $3}' >>/tmp/hypridle-workspace
hyprctl dispatch hl.dsp.focus\(\{ workspace = 9 \}\) >/dev/null
hyprctl dispatch hl.dsp.focus\(\{ workspace = 10 \}\) >/dev/null
