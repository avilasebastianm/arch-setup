#!/bin/bash
USAGE=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | tr -d ' ')
echo "{\"text\": \"󰢮 ${USAGE}%\", \"tooltip\": \"GPU RTX 3050: ${USAGE}% uso\"}"
