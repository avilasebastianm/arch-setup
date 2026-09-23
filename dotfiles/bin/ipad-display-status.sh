#!/usr/bin/env bash
# Salida JSON para el módulo custom/ipad de Waybar.
CFG="${XDG_CONFIG_HOME:-$HOME/.config}/wayvnc/config"

if hyprctl monitors -j | jq -e '[.[] | select(.name | startswith("HEADLESS"))] | length > 0' >/dev/null; then
    IP=$(ip -4 route get 1.1.1.1 2>/dev/null | grep -oP 'src \K[\d.]+' || true)
    PORT=$(grep -oP '^port=\K\d+' "$CFG" 2>/dev/null || echo 5900)
    printf '{"text":"󰓶","tooltip":"iPad display activo — %s:%s","class":"active"}\n' "${IP:-?}" "$PORT"
else
    printf '{"text":"󰓶","tooltip":"iPad display apagado (click: menú · click derecho: activar)","class":"inactive"}\n'
fi
