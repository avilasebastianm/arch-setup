#!/usr/bin/env bash
# Selector de redes wifi para Waybar: click en el ícono de red, lista las redes
# cercanas ordenadas por señal, elegís una y si hace falta te pide la contraseña
# (con rofi -password, no queda tipeada a la vista ni en el historial de shell).
# Si ya existe un perfil guardado para esa red, nmcli lo reusa y no pide nada.
#
# Dependencias: nmcli, rofi, notify-send

LOCK=$''   # nerd font: candado

declare -A SIGNAL_OF SEC_OF
CURRENT=""

# --escape no: para no lidiar con el escapado de ':' de nmcli en modo terse
while IFS=: read -r inuse ssid sec signal; do
    [ -z "$ssid" ] && continue
    [ "$inuse" = "*" ] && CURRENT="$ssid"
    # si el SSID se repite (varios APs/extensores) nos quedamos con la señal más alta
    if [ -z "${SIGNAL_OF[$ssid]}" ] || [ "$signal" -gt "${SIGNAL_OF[$ssid]}" ]; then
        SIGNAL_OF[$ssid]="$signal"
        SEC_OF[$ssid]="$sec"
    fi
done < <(nmcli --escape no -t -f IN-USE,SSID,SECURITY,SIGNAL device wifi list --rescan yes 2>/dev/null)

if [ ${#SIGNAL_OF[@]} -eq 0 ]; then
    notify-send "Wifi" "No se encontraron redes cerca"
    exit 1
fi

# armar las líneas del menú (señal<TAB>texto mostrado<TAB>ssid) y ordenar por señal
LINES=()
for ssid in "${!SIGNAL_OF[@]}"; do
    mark=" "; [ "$ssid" = "$CURRENT" ] && mark="✓"
    lock=" "; [ -n "${SEC_OF[$ssid]}" ] && lock="$LOCK"
    LINES+=("${SIGNAL_OF[$ssid]}"$'\t'"$mark $lock  $ssid  (${SIGNAL_OF[$ssid]}%)"$'\t'"$ssid")
done
mapfile -t SORTED < <(printf '%s\n' "${LINES[@]}" | sort -t$'\t' -k1,1 -rn)

DISPLAY_LIST=()
declare -A DISPLAY_TO_SSID
for line in "${SORTED[@]}"; do
    IFS=$'\t' read -r _ disp ssid <<< "$line"
    DISPLAY_LIST+=("$disp")
    DISPLAY_TO_SSID["$disp"]="$ssid"
done

CHOSEN=$(printf '%s\n' "${DISPLAY_LIST[@]}" | rofi -dmenu -p "󰖩 Wifi")
[ -z "$CHOSEN" ] && exit 0
SSID="${DISPLAY_TO_SSID[$CHOSEN]}"
[ -z "$SSID" ] && exit 0

if [ "$SSID" = "$CURRENT" ]; then
    notify-send "Wifi" "Ya estás conectado a $SSID"
    exit 0
fi

OUT=$(nmcli device wifi connect "$SSID" 2>&1)
STATUS=$?

# si pide contraseña (red nueva o perfil sin secreto guardado), la pedimos por rofi
if [ $STATUS -ne 0 ] && echo "$OUT" | grep -qi "secrets were required\|password is required"; then
    PASS=$(rofi -dmenu -p "$LOCK Contraseña de $SSID" -password)
    [ -z "$PASS" ] && exit 0
    OUT=$(nmcli device wifi connect "$SSID" password "$PASS" 2>&1)
    STATUS=$?
fi

if [ $STATUS -eq 0 ]; then
    notify-send "Wifi" "Conectado a $SSID"
else
    notify-send -u critical "Wifi" "No se pudo conectar a $SSID\n$OUT"
fi
