#!/usr/bin/env bash
if [ -f /tmp/hypridle-workspace ]; then
	hyprctl dispatch hl.dsp.focus\(\{ workspace = "$(cat /tmp/hypridle-workspace)"\}\) >/dev/null
	rm /tmp/hypridle-workspace
fi
