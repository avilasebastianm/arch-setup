#!/usr/bin/env bash
# Configura wayvnc para usar el iPad como monitor extra.
# Pide usuario y contraseña (los que vas a poner en la app del iPad, ej. Jump Desktop
# o bVNC) y genera tus propias claves. Nada de esto se sube al repo.
#
# Uso: ipad-display-setup.sh        (crea ~/.config/wayvnc/config)
set -euo pipefail

CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/wayvnc"
CFG="$CFG_DIR/config"

for cmd in wayvnc openssl ssh-keygen; do
    command -v "$cmd" >/dev/null || { echo "Falta '$cmd'. Instalalo (sudo pacman -S wayvnc openssl openssh)"; exit 1; }
done

if [[ -f "$CFG" ]]; then
    read -rp "Ya existe $CFG. ¿Sobrescribir? [s/N] " ans
    [[ "${ans,,}" == "s" ]] || { echo "Cancelado."; exit 0; }
fi

read -rp "Usuario para conectarte desde el iPad: " VNC_USER
[[ -n "$VNC_USER" ]] || { echo "El usuario no puede estar vacío."; exit 1; }

read -rsp "Contraseña: " VNC_PASS; echo
read -rsp "Repetí la contraseña: " VNC_PASS2; echo
[[ -n "$VNC_PASS" ]] || { echo "La contraseña no puede estar vacía."; exit 1; }
[[ "$VNC_PASS" == "$VNC_PASS2" ]] || { echo "Las contraseñas no coinciden."; exit 1; }

read -rp "Puerto [5900]: " VNC_PORT
VNC_PORT="${VNC_PORT:-5900}"
[[ "$VNC_PORT" =~ ^[0-9]+$ ]] || { echo "Puerto inválido."; exit 1; }

mkdir -p "$CFG_DIR"
chmod 700 "$CFG_DIR"

# Claves propias de esta máquina (TLS + RSA para la autenticación)
rm -f "$CFG_DIR"/tls_key.pem "$CFG_DIR"/tls_cert.pem "$CFG_DIR"/rsa_key.pem "$CFG_DIR"/rsa_key.pem.pub
openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
    -keyout "$CFG_DIR/tls_key.pem" -out "$CFG_DIR/tls_cert.pem" \
    -subj "/CN=$(hostname)" -addext "subjectAltName=DNS:$(hostname),DNS:localhost" 2>/dev/null
ssh-keygen -m pem -t rsa -b 2048 -N "" -q -f "$CFG_DIR/rsa_key.pem"
rm -f "$CFG_DIR/rsa_key.pem.pub"

umask 077
cat > "$CFG" <<CONF
address=0.0.0.0
port=$VNC_PORT
enable_auth=true
username=$VNC_USER
password=$VNC_PASS
private_key_file=$CFG_DIR/tls_key.pem
certificate_file=$CFG_DIR/tls_cert.pem
rsa_private_key_file=$CFG_DIR/rsa_key.pem
CONF
chmod 600 "$CFG" "$CFG_DIR"/*.pem

echo "Listo. Config guardada en $CFG (permisos 600)."
echo "Activá el display con Super+Shift+I y conectate desde el iPad con ese usuario y contraseña."
