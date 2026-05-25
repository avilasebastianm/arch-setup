#!/bin/bash
read b1 t1 <<< $(awk '/^cpu /{print $2+$3+$4+$7+$8+$9, $2+$3+$4+$5+$6+$7+$8+$9}' /proc/stat)
sleep 0.5
read b2 t2 <<< $(awk '/^cpu /{print $2+$3+$4+$7+$8+$9, $2+$3+$4+$5+$6+$7+$8+$9}' /proc/stat)
USAGE=$(( (b2-b1)*100/(t2-t1) ))
TEMP=$(( $(cat /sys/class/hwmon/hwmon8/temp1_input) / 1000 ))
CPU=$(printf '\xef\x8b\x9b')
THERM=$(printf '\xef\x8b\x88')
DEG=$(printf '\xc2\xb0')
echo "{\"text\": \"${CPU} ${USAGE}% ${THERM} ${TEMP}${DEG}C\", \"tooltip\": \"CPU: ${USAGE}% uso | ${TEMP}${DEG}C\"}"
