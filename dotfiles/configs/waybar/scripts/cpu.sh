#!/bin/bash
read b1 t1 <<< $(awk '/^cpu /{print $2+$3+$4+$7+$8+$9, $2+$3+$4+$5+$6+$7+$8+$9}' /proc/stat)
sleep 0.5
read b2 t2 <<< $(awk '/^cpu /{print $2+$3+$4+$7+$8+$9, $2+$3+$4+$5+$6+$7+$8+$9}' /proc/stat)
USAGE=$(( (b2-b1)*100/(t2-t1) ))

# El número de hwmon cambia entre booteos y máquinas: buscamos el sensor por nombre
# (Intel: coretemp, AMD: k10temp/zenpower, ARM: cpu_thermal, fallback: acpitz)
TEMP_FILE=""
for name in coretemp k10temp zenpower cpu_thermal acpitz; do
    for hw in /sys/class/hwmon/hwmon*; do
        if [[ "$(cat "$hw/name" 2>/dev/null)" == "$name" && -r "$hw/temp1_input" ]]; then
            TEMP_FILE="$hw/temp1_input"
            break 2
        fi
    done
done
[[ -z "$TEMP_FILE" ]] && TEMP_FILE=$(ls /sys/class/thermal/thermal_zone*/temp 2>/dev/null | head -1)
TEMP=$(( $(cat "$TEMP_FILE" 2>/dev/null || echo 0) / 1000 ))

CPU=$(printf '\xef\x8b\x9b')
THERM=$(printf '\xef\x8b\x88')
DEG=$(printf '\xc2\xb0')
echo "{\"text\": \"${CPU} ${USAGE}% ${THERM} ${TEMP}${DEG}C\", \"tooltip\": \"CPU: ${USAGE}% uso | ${TEMP}${DEG}C\"}"
