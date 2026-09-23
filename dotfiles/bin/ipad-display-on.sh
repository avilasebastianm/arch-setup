#!/usr/bin/env bash
# Crea un monitor virtual (headless) y lo comparte por VNC con wayvnc.
# Ajustá la resolución a tu iPad exportando IPAD_RES antes de lanzarlo o cambiando
# el valor por defecto de abajo (ej. iPad Pro 11": 2388x1668@60, iPad Air: 2360x1640@60).
set -e

CFG="${XDG_CONFIG_HOME:-$HOME/.config}/wayvnc/config"

if [ ! -f "$CFG" ]; then
    notify-send "iPad Display" "Falta configurar. Corré ipad-display-setup.sh" 2>/dev/null || true
    echo "No existe $CFG. Corré primero: ipad-display-setup.sh"
    exit 1
fi

MON=$(hyprctl monitors -j | jq -r '[.[] | select(.name | startswith("HEADLESS"))][0].name // empty')

if [ -z "$MON" ]; then
    hyprctl output create headless
    sleep 0.3
    MON=$(hyprctl monitors -j | jq -r '[.[] | select(.name | startswith("HEADLESS"))][0].name')
fi

# Resolución/escala guardadas (IPAD_RES las pisa); la posición (abajo) la calcula ipad-display-res.sh
if [ -n "$IPAD_RES" ]; then ipad-display-res.sh "$IPAD_RES" >/dev/null; else ipad-display-res.sh apply >/dev/null; fi

if pgrep -x wayvnc >/dev/null; then
    pkill -x wayvnc
    sleep 0.3
fi

# Usuario, contraseña y puerto salen de ~/.config/wayvnc/config
nohup wayvnc -o "$MON" >/tmp/wayvnc.log 2>&1 &
disown

IP=$(ip -4 route get 1.1.1.1 2>/dev/null | grep -oP 'src \K[\d.]+' || true)
PORT=$(grep -oP '^port=\K\d+' "$CFG" || echo 5900)
notify-send "iPad Display" "Servidor VNC activo en ${IP:-<tu-ip>}:$PORT (output $MON)" 2>/dev/null || true
echo "wayvnc corriendo, conectate a ${IP:-<tu-ip>}:$PORT"
