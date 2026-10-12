#!/bin/sh

# Dynamically locate the GPU busy percent and temperature inputs
busy_file=$(find /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -n 1)
temp_file=$(find /sys/class/drm/card*/device/hwmon/hwmon*/temp1_input 2>/dev/null | head -n 1)

usage=0
temp=0

if [ -n "$busy_file" ] && [ -r "$busy_file" ]; then
    usage=$(cat "$busy_file" 2>/dev/null || echo 0)
fi

if [ -n "$temp_file" ] && [ -r "$temp_file" ]; then
    raw_temp=$(cat "$temp_file" 2>/dev/null || echo 0)
    temp=$(( raw_temp / 1000 ))
fi

class="normal"
if [ "$temp" -ge 85 ] || [ "$usage" -ge 90 ]; then
    class="critical"
elif [ "$temp" -ge 75 ] || [ "$usage" -ge 75 ]; then
    class="warning"
fi

cat <<EOF
{"text": "󰢮 ${usage}%  ${temp}°C", "tooltip": "GPU Usage: ${usage}%\nGPU Temperature: ${temp}°C", "class": "${class}"}
EOF
