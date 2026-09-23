#!/bin/bash
set -e

# ─── Colores ────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
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

# ─── Selección de componentes ────────────────────────────────────────────────
DO_CONFIGS=false
DO_PKGS=false
DO_AUR=false
DO_FONTS=false
DO_ZSHRC=false

echo ""
echo -e "  ${BOLD}¿Qué querés instalar?${NC}"
echo ""
echo -e "  ${YELLOW}[1]${NC}  ${BOLD}Configs${NC}       ${DIM}→ copia dotfiles a ~/.config (hypr, waybar, kitty, rofi, nvim, etc.)${NC}"
echo -e "  ${YELLOW}[2]${NC}  ${BOLD}Paquetes${NC}      ${DIM}→ instala Hyprland y paquetes oficiales (pkglist.txt)${NC}"
echo -e "  ${YELLOW}[3]${NC}  ${BOLD}Paquetes AUR${NC}  ${DIM}→ instala paquetes AUR via yay (pkglist-aur.txt)${NC}"
echo -e "  ${YELLOW}[4]${NC}  ${BOLD}Fuentes${NC}       ${DIM}→ instala fuentes al sistema${NC}"
echo -e "  ${YELLOW}[5]${NC}  ${BOLD}.zshrc${NC}        ${DIM}→ copia .zshrc al home${NC}"
echo -e "  ${YELLOW}[a]${NC}  ${BOLD}Todo${NC}"
echo ""
read -rp "  Elegí [1-5 separados por espacio, o 'a' para todo]: " choices

if [[ "$choices" =~ ^[aA]$ ]]; then
    DO_CONFIGS=true; DO_PKGS=true; DO_AUR=true; DO_FONTS=true; DO_ZSHRC=true
else
    for c in $choices; do
        case "$c" in
            1) DO_CONFIGS=true ;;
            2) DO_PKGS=true ;;
            3) DO_AUR=true ;;
            4) DO_FONTS=true ;;
            5) DO_ZSHRC=true ;;
        esac
    done
fi

echo ""
$DO_CONFIGS && info "✓ Configs"
$DO_PKGS    && info "✓ Paquetes oficiales"
$DO_AUR     && info "✓ Paquetes AUR"
$DO_FONTS   && info "✓ Fuentes"
$DO_ZSHRC   && info "✓ .zshrc"
echo ""
read -rp "  ¿Continuar? [s/N]: " confirm
[[ "$confirm" =~ ^[sS]$ ]] || { echo "Cancelado."; exit 0; }

# ─── 1. Dependencias base (siempre) ─────────────────────────────────────────
log "Verificando dependencias base..."
sudo pacman -S --needed --noconfirm git base-devel curl

# ─── 2. yay ─────────────────────────────────────────────────────────────────
if $DO_PKGS || $DO_AUR; then
    if ! command -v yay &>/dev/null; then
        log "Instalando yay (AUR helper)..."
        git clone https://aur.archlinux.org/yay.git /tmp/yay-install
        (cd /tmp/yay-install && makepkg -si --noconfirm)
        rm -rf /tmp/yay-install
    else
        info "yay ya está instalado."
    fi
fi

# ─── 3. Paquetes esenciales de Hyprland ─────────────────────────────────────
if $DO_PKGS; then
    log "Instalando Hyprland y dependencias esenciales..."
    HYPR_CORE=(
        hyprland hyprpaper
        waybar kitty rofi dunst
        pipewire pipewire-pulse pipewire-alsa wireplumber pavucontrol
        brightnessctl playerctl pamixer
        grim slurp
        xdg-desktop-portal-hyprland qt5-wayland qt6-wayland
        polkit-gnome
        noto-fonts ttf-jetbrains-mono-nerd
        yazi tmux btop starship
        neovim git curl wget
    )
    sudo pacman -S --needed --noconfirm "${HYPR_CORE[@]}" || \
        warn "Algunos paquetes esenciales no se pudieron instalar."

    log "Instalando paquetes oficiales completos (${DOTFILES_DIR}/packages/pkglist.txt)..."
    sudo pacman -S --needed --noconfirm - < "${DOTFILES_DIR}/packages/pkglist.txt" || \
        warn "Algunos paquetes opcionales no se pudieron instalar (pueden ser hardware-específicos o renombrados)."
fi

# ─── 4. Paquetes AUR ─────────────────────────────────────────────────────────
if $DO_AUR; then
    log "Instalando paquetes AUR (${DOTFILES_DIR}/packages/pkglist-aur.txt)..."
    yay -S --needed --noconfirm - < "${DOTFILES_DIR}/packages/pkglist-aur.txt" || \
        warn "Algunos paquetes AUR no se pudieron instalar."
fi

# ─── 5. Configs ──────────────────────────────────────────────────────────────
if $DO_CONFIGS; then
    log "Copiando configuraciones a ~/.config/..."
    mkdir -p "${HOME}/.config"

    configs=(hypr waybar rofi kitty nvim yazi tmux neofetch dunst)
    for cfg in "${configs[@]}"; do
        if [[ -d "${DOTFILES_DIR}/configs/${cfg}" ]]; then
            rm -rf "${HOME}/.config/${cfg}"
            cp -r "${DOTFILES_DIR}/configs/${cfg}" "${HOME}/.config/"
            info "${cfg} ✓"
        fi
    done

    if [[ -f "${DOTFILES_DIR}/configs/starship.toml" ]]; then
        cp "${DOTFILES_DIR}/configs/starship.toml" "${HOME}/.config/"
        info "starship.toml ✓"
    fi

    # Permisos de ejecución en scripts
    for cfg_dir in hypr waybar; do
        if [[ -d "${HOME}/.config/${cfg_dir}" ]]; then
            find "${HOME}/.config/${cfg_dir}" -name "*.sh" -exec chmod +x {} \;
        fi
    done

    # Splash de Borges
    log "Configurando splash aleatorio de Borges..."
    PROFILE_FILE="${HOME}/.bash_profile"
    [[ -f "${HOME}/.zprofile" ]] && PROFILE_FILE="${HOME}/.zprofile"

    if ! grep -q "hypr/splash.sh" "$PROFILE_FILE" 2>/dev/null; then
        echo "" >> "$PROFILE_FILE"
        echo "~/.config/hypr/splash.sh" >> "$PROFILE_FILE"
        info "Hook agregado a $PROFILE_FILE ✓"
    else
        info "Hook ya existe en $PROFILE_FILE."
    fi

    [[ -f "${HOME}/.config/hypr/splash.sh" ]] && \
        "${HOME}/.config/hypr/splash.sh" && info "current_splash.conf generado ✓"

    # Scripts propios (iPad como monitor, wifi, etc.) → ~/.local/bin
    if [[ -d "${DOTFILES_DIR}/bin" ]]; then
        mkdir -p "${HOME}/.local/bin"
        cp "${DOTFILES_DIR}/bin/"* "${HOME}/.local/bin/"
        chmod +x "${HOME}/.local/bin/"*.sh
        info "scripts en ~/.local/bin ✓"
        info "Para usar el iPad como monitor corré: ipad-display-setup.sh (te pide usuario y contraseña)"
    fi

    # Carpetas que usan los binds de captura y el wallpaper de respaldo
    mkdir -p "${HOME}/Pictures/Screenshots" "${HOME}/.local/share/wallpapers"
fi

# ─── 6. .zshrc ───────────────────────────────────────────────────────────────
if $DO_ZSHRC; then
    log "Copiando archivos home..."
    if [[ -f "${DOTFILES_DIR}/home/.zshrc" ]]; then
        cp "${DOTFILES_DIR}/home/.zshrc" "${HOME}/"
        info ".zshrc ✓"
    fi
fi

# ─── 7. Fuentes ──────────────────────────────────────────────────────────────
if $DO_FONTS; then
    log "Instalando fuentes..."
    mkdir -p "${HOME}/.local/share/fonts"
    cp -r "${DOTFILES_DIR}/fonts/." "${HOME}/.local/share/fonts/"
    fc-cache -fv &>/dev/null
    info "Caché de fuentes actualizado ✓"
fi

# ─── 8. Servicios de audio ───────────────────────────────────────────────────
if $DO_PKGS; then
    log "Habilitando servicios de audio (pipewire)..."
    if systemctl --user status &>/dev/null 2>&1; then
        systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null && \
            info "pipewire + wireplumber habilitados ✓" || \
            warn "No se pudieron habilitar los servicios de audio ahora. Ejecutá después de reiniciar:
        systemctl --user enable --now pipewire pipewire-pulse wireplumber"
    else
        warn "Sesión systemd de usuario no activa. Ejecutá después de iniciar sesión:
        systemctl --user enable --now pipewire pipewire-pulse wireplumber"
    fi
fi

# ─── Listo ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}  ✓ Instalación completa.${NC}"
echo -e "  Reiniciá Hyprland con ${YELLOW}Super+M${NC} o cerrá sesión para aplicar todo."
