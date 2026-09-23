#!/usr/bin/env bash
# Cambia el tamaño del escritorio del iPad en caliente y lo recuerda.
# Uso: ipad-display-res.sh size N | up | down | WxH[@Hz] | apply
#   size N   -> N% de tamaño: 100 = 1920x1440, 150 = 1280x960, 200 = 960x720...
#               Más % = íconos y letra más grandes; siempre se ve el escritorio completo.
#   up/down  -> siguiente/anterior preset de resolución
#   WxH@Hz   -> resolución a mano, ej. 2388x1668@60
#   apply    -> reaplica lo guardado (y reposiciona el iPad debajo de la pantalla principal)
# Siempre escala 1 en Hyprland: la escala fraccionaria rompe el mapeo del puntero en wayvnc.
# Se guarda en ~/.config/wayvnc/resolution; ipad-display-on.sh la usa al prender.
set -e

BASE_W=1920; BASE_H=1440
PRESETS=(960x720@60 1280x960@60 1536x1152@60 1920x1440@60 2430x1822@60)
DIR="${XDG_CONFIG_HOME:-$HOME/.config}/wayvnc"
RES_FILE="$DIR/resolution"
SCALE=1

RES=$(cat "$RES_FILE" 2>/dev/null || echo 1920x1440@60)

MON=$(hyprctl monitors -j | jq -r '[.[] | select(.name | startswith("HEADLESS"))][0].name // empty')

idx() { # posición del preset actual (o el más cercano por debajo)
    local i best=0
    for i in "${!PRESETS[@]}"; do
        [ "${PRESETS[$i]%%x*}" -le "${RES%%x*}" ] && best=$i
    done
    echo "$best"
}

case "${1:-}" in
    size)  P="${2:-}"
           [[ "$P" =~ ^[0-9]+$ ]] && [ "$P" -ge 50 ] && [ "$P" -le 300 ] || { echo "Uso: $0 size 50-300 (ej. 100, 150)"; exit 1; }
           RES="$(( BASE_W * 100 / P / 2 * 2 ))x$(( BASE_H * 100 / P / 2 * 2 ))@60" ;;
    up)    i=$(( $(idx) + 1 )); [ "$i" -ge "${#PRESETS[@]}" ] && i=$(( ${#PRESETS[@]} - 1 )); RES=${PRESETS[$i]} ;;
    down)  i=$(( $(idx) - 1 )); [ "$i" -lt 0 ] && i=0; RES=${PRESETS[$i]} ;;
    apply) ;;
    *x*)   RES="$1"; [[ "$RES" == *@* ]] || RES="$RES@60"
           [[ "$RES" =~ ^[0-9]+x[0-9]+@[0-9.]+$ ]] || { echo "Formato inválido: $RES (usá WxH@Hz)"; exit 1; } ;;
    *)     echo "Uso: $0 size N | up | down | WxH[@Hz] | apply"; exit 1 ;;
esac

mkdir -p "$DIR"
echo "$RES" > "$RES_FILE"
rm -f "$DIR/scale"

if [ -z "$MON" ]; then
    notify-send "iPad Display" "Guardado $RES (el display está apagado)" 2>/dev/null || true
    echo "Guardado $RES; se aplica al prender el display."
    exit 0
fi

# Posición: debajo de la pantalla principal (eDP-1, o la primera real), centrado.
# Así al bajar el mouse o mover ventanas hacia abajo pasan al iPad.
POS=$(hyprctl monitors -j | jq -r --argjson w "${RES%%x*}" --argjson s "$SCALE" '
    [.[] | select(.name | startswith("HEADLESS") | not)] as $real
    | (($real | map(select(.name=="eDP-1"))[0]) // $real[0]) as $r
    | "\((($r.x + ($r.width / $r.scale - $w / $s) / 2) | floor))x\((($r.y + $r.height / $r.scale) | floor))"')
hyprctl keyword monitor "$MON,$RES,$POS,$SCALE" >/dev/null
sleep 0.5
GOT=$(hyprctl monitors -j | jq -r --arg m "$MON" '.[] | select(.name==$m) | "\(.width)x\(.height) @ \(.scale)"')
notify-send "iPad Display" "$GOT" 2>/dev/null || true
echo "Aplicado: $GOT"
