#!/bin/bash

# Path to the mpv IPC socket we defined in Hyprland config
SOCK="/tmp/mpv-wsock"
send_mpv_cmd() {
	if [ -S "$SOCK" ]; then
		echo "$1" | socat - "$SOCK" > /dev/null 2>&1
	fi
}

socat - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
	case "$line" in
		# if any window trigger full-screen mode on (1)
		"fullscreen>>1"*)
			send_mpv_cmd '{"command": ["set_property", "pause", true]}'
			;;
		# If full-screen mode is turned off (0)
		"fullscreen>>0"*)
			send_mpv_cmd '{"command": ["set_property", "pause", false]}'
			;;
	esac
done

