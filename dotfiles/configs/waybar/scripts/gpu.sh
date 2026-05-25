#!/bin/bash
DATA=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null)
USAGE=$(echo "$DATA" | cut -d',' -f1 | tr -d ' ')
TEMP=$(echo "$DATA" | cut -d',' -f2 | tr -d ' ')
GPU=$(printf '\xf3\xb0\xa2\xae')
THERM=$(printf '\xef\x8b\x88')
DEG=$(printf '\xc2\xb0')
echo "{\"text\": \"${GPU} ${USAGE}% ${THERM} ${TEMP}${DEG}C\", \"tooltip\": \"GPU RTX 3050: ${USAGE}% uso | ${TEMP}${DEG}C\"}"
