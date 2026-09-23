#!/usr/bin/env bash
# Modal (rofi) del iPad para Waybar: activar/desactivar y tamaño (100%, 150%...).
# Más % = íconos y letra más grandes; el escritorio siempre se ve completo.
# Dependencias: rofi, hyprctl, jq, ipad-display-res.sh

RES=$(cat "${XDG_CONFIG_HOME:-$HOME/.config}/wayvnc/resolution" 2>/dev/null || echo 1920x1440@60)
BASE_W=1920; BASE_H=1440
SIZES=(75 100 125 150 200)

MENU=(); ACTIONS=()
add() { MENU+=("$1"); ACTIONS+=("$2"); }

if hyprctl monitors -j | jq -e '[.[] | select(.name | startswith("HEADLESS"))] | length > 0' >/dev/null; then
    add "󰐥  Desactivar display" "ipad-display-off.sh"
else
    add "󰐥  Activar display" "ipad-display-on.sh"
fi

CUR="custom"
for p in "${SIZES[@]}"; do
    r="$(( BASE_W * 100 / p / 2 * 2 ))x$(( BASE_H * 100 / p / 2 * 2 ))@60"
    mark="  "; [ "$r" = "$RES" ] && { mark="✓ "; CUR="$p%"; }
    add "$mark Tamaño  ${p}%   (${r%@*})" "ipad-display-res.sh size $p"
done
add "   Nativo del iPad   (2430x1822)" "ipad-display-res.sh 2430x1822@60"
[ "$RES" = "2430x1822@60" ] && CUR="nativo"

IDX=$(printf '%s\n' "${MENU[@]}" | rofi -dmenu -i -format i -p "󰓶 iPad" -mesg "Actual: $CUR · ${RES%@*}") || exit 0
[ -z "$IDX" ] && exit 0

# shellcheck disable=SC2086
exec ${ACTIONS[$IDX]}
