#!/bin/bash
# Uso y temperatura de la GPU. Soporta NVIDIA (nvidia-smi) y AMD (amdgpu por sysfs).
# Si no encuentra ninguna, no imprime nada y Waybar oculta el módulo.
GPU=$(printf '\xf3\xb0\xa2\xae')
THERM=$(printf '\xef\x8b\x88')
DEG=$(printf '\xc2\xb0')

if command -v nvidia-smi &>/dev/null && DATA=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,name --format=csv,noheader,nounits 2>/dev/null); then
    USAGE=$(echo "$DATA" | head -1 | cut -d',' -f1 | tr -d ' ')
    TEMP=$(echo "$DATA" | head -1 | cut -d',' -f2 | tr -d ' ')
    NAME=$(echo "$DATA" | head -1 | cut -d',' -f3 | sed 's/^ *//')
else
    for card in /sys/class/drm/card*/device; do
        [[ -r "$card/gpu_busy_percent" ]] || continue
        USAGE=$(cat "$card/gpu_busy_percent")
        TEMP_FILE=$(ls "$card"/hwmon/hwmon*/temp1_input 2>/dev/null | head -1)
        TEMP=$(( $(cat "$TEMP_FILE" 2>/dev/null || echo 0) / 1000 ))
        NAME="GPU AMD"
        break
    done
fi

[[ -z "$USAGE" ]] && exit 0
echo "{\"text\": \"${GPU} ${USAGE}% ${THERM} ${TEMP}${DEG}C\", \"tooltip\": \"${NAME}: ${USAGE}% uso | ${TEMP}${DEG}C\"}"
