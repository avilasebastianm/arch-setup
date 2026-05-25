#!/bin/bash
TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | tr -d ' ')
echo "{\"text\": \"󰔏 ${TEMP}°C\", \"tooltip\": \"GPU RTX 3050: ${TEMP}°C\"}"
