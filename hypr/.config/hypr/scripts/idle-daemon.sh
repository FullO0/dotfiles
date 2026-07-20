#!/bin/bash

# --- CONFIGURATION ---
IDLE_WALLPAPER=900 # 15 minutes in seconds
IDLE_INPUT_LISTENER=/tmp/idle-daemon-listener
CHECK_INTERVAL=1 # Check input state every 1 second

# --- TRACKING VARIABLES ---
last_activity=$(date +%s)
is_idling=false

# Fucntion to read the input parralel to the time keeping
input_listner() {
	exec 3< <(cat /dev/input/mice /dev/input/by-id/usb-*-event-kbd 2>/dev/null)

	while true; do
		dd bs=1 count=1 <&3 >/dev/null 2>&1
		echo "[IDLE] Detected device activity disabling idling"
		touch "$IDLE_INPUT_LISTENER"
	done
}

# Helper function to clear state and switch workspaces back
wake_up() {
	echo "[IDLE] Physical activity detected. Waking up..."
	is_idling=false
	last_activity=$(date +%s)
	~/.dotfiles/hypr/.config/hypr/scripts/idle-off.sh
}

go_idle() {
	echo "[IDLE] System reached timeout limit. Switching to idle mode..."
	~/.dotfiles/hypr/.config/hypr/scripts/idle-on.sh
	is_idling=true
}

# --- THE MAIN EVENT LOOP ---
echo "[IDLE] Starting custom hardware idle daemon..."

while true; do
	if [ -f "$IDLE_INPUT_LISTENER" ]; then
		activity_detected=true
	fi

	# 2. Check if a browser or media player is inhibiting idle
	# (Using the new target attribute from newer Hyprland updates)
	if hyprctl clients -j | jq -e '.[] | select(.inhibitingIdle == true)' >/dev/null; then
		activity_detected=true
	fi

	if [ "$activity_detected" = true ]; then
		last_activity=$current_time
		if [ "$is_idling" = true ]; then
			wake_up
		fi
	else
		elapsed_time=$((current_time - last_activity))

		if [ "$elapsed_time" -ge "$IDLE_WALLPAPER" ] && [ "$is_idling" = false ]; then
			go_idle
		fi
	fi
done
