#!/bin/bash
set -e

# ─── Colores ────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}==> ${NC}$1"; }
warn() { echo -e "${YELLOW}[!] ${NC}$1"; }
err()  { echo -e "${RED}[x] ${NC}$1"; exit 1; }
info() { echo -e "${BLUE}    ${NC}$1"; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Banner ──────────────────────────────────────────────────────────────────
echo -e "${BLUE}"
echo "  ╔═══════════════════════════════════════╗"
echo "  ║        dotfiles installer             ║"
echo "  ║        Hyprland · Arch Linux          ║"
echo "  ╚═══════════════════════════════════════╝"
echo -e "${NC}"

# ─── Confirmación ────────────────────────────────────────────────────────────
warn "Esto sobreescribirá tus configs actuales en ~/.config"
read -rp "  ¿Continuar? [s/N]: " confirm
[[ "$confirm" =~ ^[sS]$ ]] || { echo "Cancelado."; exit 0; }

# ─── 1. Dependencias base ────────────────────────────────────────────────────
log "Verificando dependencias base..."
sudo pacman -S --needed --noconfirm git base-devel curl

# ─── 2. Instalar yay ─────────────────────────────────────────────────────────
if ! command -v yay &>/dev/null; then
    log "Instalando yay (AUR helper)..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay-install
    (cd /tmp/yay-install && makepkg -si --noconfirm)
    rm -rf /tmp/yay-install
else
    info "yay ya está instalado, saltando."
fi

# ─── 3. Paquetes oficiales ───────────────────────────────────────────────────
log "Instalando paquetes oficiales (${DOTFILES_DIR}/packages/pkglist.txt)..."
sudo pacman -S --needed --noconfirm - < "${DOTFILES_DIR}/packages/pkglist.txt" || \
    warn "Algunos paquetes oficiales no se pudieron instalar (puede que hayan cambiado de nombre)."

# ─── 4. Paquetes AUR ─────────────────────────────────────────────────────────
log "Instalando paquetes AUR (${DOTFILES_DIR}/packages/pkglist-aur.txt)..."
yay -S --needed --noconfirm - < "${DOTFILES_DIR}/packages/pkglist-aur.txt" || \
    warn "Algunos paquetes AUR no se pudieron instalar."

# ─── 5. Configs ──────────────────────────────────────────────────────────────
log "Copiando configuraciones a ~/.config/..."

configs=(hypr waybar rofi kitty nvim yazi tmux neofetch dunst)
for cfg in "${configs[@]}"; do
    if [[ -d "${DOTFILES_DIR}/configs/${cfg}" ]]; then
        rm -rf "${HOME}/.config/${cfg}"
        cp -r "${DOTFILES_DIR}/configs/${cfg}" "${HOME}/.config/"
        info "${cfg} ✓"
    fi
done

# starship.toml va directo en ~/.config/
if [[ -f "${DOTFILES_DIR}/configs/starship.toml" ]]; then
    cp "${DOTFILES_DIR}/configs/starship.toml" "${HOME}/.config/"
    info "starship.toml ✓"
fi

# ─── 6. Archivos home ────────────────────────────────────────────────────────
log "Copiando archivos home..."
if [[ -f "${DOTFILES_DIR}/home/.zshrc" ]]; then
    cp "${DOTFILES_DIR}/home/.zshrc" "${HOME}/"
    info ".zshrc ✓"
fi

# ─── 7. Fuentes ──────────────────────────────────────────────────────────────
log "Instalando fuentes..."
mkdir -p "${HOME}/.local/share/fonts"
cp -r "${DOTFILES_DIR}/fonts/." "${HOME}/.local/share/fonts/"
fc-cache -fv &>/dev/null
info "Caché de fuentes actualizado ✓"

# ─── 8. Permisos ─────────────────────────────────────────────────────────────
for cfg_dir in hypr waybar; do
    if [[ -d "${HOME}/.config/${cfg_dir}" ]]; then
        find "${HOME}/.config/${cfg_dir}" -name "*.sh" -exec chmod +x {} \;
    fi
done

# ─── Listo ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}  ✓ Instalación completa.${NC}"
echo -e "  Reiniciá Hyprland con ${YELLOW}Super+M${NC} o cerrá sesión para aplicar todo."
