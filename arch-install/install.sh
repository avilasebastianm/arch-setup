#!/bin/bash
# Arch Linux Interactive Installer
set -e

# ─── Colores ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ─── Helpers ─────────────────────────────────────────────────────────────────
title() {
    echo ""
    echo -e "  ${BLUE}${BOLD}┌─ $1 ${NC}"
    echo ""
}
log()  { echo -e "  ${GREEN}✓${NC}  $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC}  $1"; }
err()  { echo -e "\n  ${RED}✗  ERROR:${NC} $1\n"; exit 1; }
info() { echo -e "  ${CYAN}→${NC}  $1"; }
ask()  { echo -ne "  ${MAGENTA}?${NC}  $1 "; }
hr()   { echo -e "  ${DIM}$(printf '─%.0s' {1..54})${NC}"; }
step() { echo -e "\n  ${BLUE}[${BOLD}$1${NC}${BLUE}/${BOLD}5${NC}${BLUE}]${NC}  $2\n"; }

# ─── Variables globales ───────────────────────────────────────────────────────
DISK=""
BOOT_MODE=""
USE_SWAP=true
SWAP_SIZE=0
HOSTNAME=""
TIMEZONE=""
LOCALE="en_US.UTF-8"
ROOT_PASS=""
CREATE_USER=true
USERNAME=""
USER_PASS=""
EXTRA_PKGS=""
DM=""
USE_HOME=false
ROOT_SIZE=0
INSTALL_MODE="fresh"   # fresh | dualboot
EFI_PART=""            # partición EFI existente (solo dual boot UEFI)
FREE_START=0           # inicio del espacio libre en MiB
FREE_END=0             # fin del espacio libre en MiB
FREE_GB=0              # tamaño del espacio libre en GB
FIRST_NEW_PNUM=1       # número de la primera partición nueva (dual boot)

# ─── Helper: espacio libre más grande del disco (devuelve: start end gb) ─────
find_free_space() {
    parted -s "$DISK" unit MiB print free 2>/dev/null | \
    awk '/Free Space/ {
        s=$1; e=$2; sz=$3
        gsub(/MiB/,"",s); gsub(/MiB/,"",e); gsub(/MiB/,"",sz)
        if (sz+0 > max+0) { max=sz+0; start=s+0; end=e+0 }
    } END {
        if (max > 0) print int(start), int(end), int(max/1024)
        else         print "0 0 0"
    }'
}

# ─── Helper: nombre de partición (maneja nvme y mmcblk) ─────────────────────
get_part() {
    local disk="$1" num="$2"
    if [[ "$disk" =~ (nvme|mmcblk) ]]; then
        echo "${disk}p${num}"
    else
        echo "${disk}${num}"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# BIENVENIDA
# ─────────────────────────────────────────────────────────────────────────────
welcome() {
    clear
    echo -e "${BLUE}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║                                                      ║"
    echo "  ║              Arch Linux  ·  Instalador              ║"
    echo "  ║                                                      ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    warn "El disco que elijas será formateado por completo."
    warn "Asegurate de tener backup antes de continuar."
    echo ""
    ask "Presioná ENTER para comenzar, o Ctrl+C para salir..."
    read -r
}

# ─────────────────────────────────────────────────────────────────────────────
# PREREQUISITOS
# ─────────────────────────────────────────────────────────────────────────────
check_prereqs() {
    [[ $EUID -ne 0 ]] && err "Ejecutá el script como root: sudo ./install.sh"

    title "Verificando requisitos"

    info "Verificando internet..."
    if ping -c 1 -W 3 archlinux.org &>/dev/null; then
        log "Conexión a internet OK"
    else
        err "Sin internet. Conectate primero.\n  Para WiFi: iwctl → station wlan0 connect <SSID>"
    fi

    if ls /sys/firmware/efi/efivars &>/dev/null 2>&1; then
        BOOT_MODE="UEFI"
        log "Modo de arranque: UEFI (GPT)"
    else
        BOOT_MODE="BIOS"
        log "Modo de arranque: BIOS/Legacy (MBR)"
    fi

    timedatectl set-ntp true &>/dev/null
    log "Reloj NTP sincronizado"
}

# ─────────────────────────────────────────────────────────────────────────────
# SELECCIÓN DE DISCO
# ─────────────────────────────────────────────────────────────────────────────
select_disk() {
    title "Selección de disco"

    local disks=()
    local i=1

    while IFS= read -r disk_name; do
        local size model type
        size=$(lsblk -dn -o SIZE "/dev/$disk_name" 2>/dev/null | xargs)
        model=$(lsblk -dn -o MODEL "/dev/$disk_name" 2>/dev/null | xargs)
        type=$(lsblk -dn -o TRAN "/dev/$disk_name" 2>/dev/null | xargs)
        echo -e "  ${YELLOW}[$i]${NC}  /dev/${BOLD}${disk_name}${NC}  ${BOLD}${size}${NC}  ${DIM}${model} ${type}${NC}"
        disks+=("/dev/$disk_name")
        ((i++))
    done < <(lsblk -dno NAME | grep -E '^(sd|nvme|vd|hd|mmcblk)')

    [[ ${#disks[@]} -eq 0 ]] && err "No se encontraron discos."

    echo ""
    local choice
    while true; do
        ask "¿En qué disco instalás Arch? [1-${#disks[@]}]:"
        read -r choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#disks[@]} )); then
            DISK="${disks[$((choice-1))]}"
            break
        fi
        warn "Opción inválida. Elegí un número del 1 al ${#disks[@]}."
    done

    echo ""
    hr
    info "Disco seleccionado: ${BOLD}$DISK${NC}"
    echo ""
    lsblk "$DISK"
    hr
    echo ""
    warn "TODO el contenido de $DISK será eliminado."
    echo ""
    ask "¿Confirmás que querés usar $DISK? [s/N]:"
    read -r confirm
    if [[ ! "$confirm" =~ ^[sS]$ ]]; then
        echo ""
        warn "Volviendo a la selección..."
        select_disk
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# DUAL BOOT: redimensionar Windows automáticamente
# ─────────────────────────────────────────────────────────────────────────────
shrink_windows_partition() {
    local win_part="$1"
    local arch_gb="$2"
    local win_gb="$3"

    local win_part_num
    win_part_num=$(echo "$win_part" | grep -oE '[0-9]+$')

    local new_win_gb=$(( win_gb - arch_gb ))
    local new_win_mb=$(( new_win_gb * 1024 ))

    # Instalar ntfs-3g si no está disponible
    if ! command -v ntfsresize &>/dev/null; then
        info "Instalando ntfs-3g..."
        pacman -Sy --noconfirm ntfs-3g &>/dev/null || err "No se pudo instalar ntfs-3g."
    fi

    # Verificación previa (dry-run)
    info "Verificando que la partición se pueda redimensionar..."
    local check
    check=$(ntfsresize -n -s "${new_win_mb}M" "$win_part" 2>&1)
    local check_exit=$?

    if echo "$check" | grep -qi "hiberfil\|hibernate\|dirty\|unclean"; then
        err "Windows no fue apagado correctamente (puede estar hibernado).\nIniciá Windows → Inicio → Apagar (NO Reiniciar ni modo rápido) y volvé a intentar."
    fi
    if [[ $check_exit -ne 0 ]]; then
        echo "$check"
        err "No se puede redimensionar la partición de Windows."
    fi

    # Redimensionar filesystem NTFS
    info "Redimensionando Windows: ${win_gb} GB → ${new_win_gb} GB (puede tardar unos minutos)..."
    echo "y" | ntfsresize -s "${new_win_mb}M" "$win_part" || \
        err "Falló la redimensión del sistema de archivos NTFS."

    # Obtener posición de inicio de la partición Windows
    local win_start_mb
    win_start_mb=$(parted -s "$DISK" unit MiB print | \
        awk -v n="$win_part_num" '$1==n {gsub(/MiB/,"",$2); print int($2)}')

    local new_win_end_mb=$(( win_start_mb + new_win_mb ))

    # Obtener tamaño total del disco
    local disk_end_mb
    disk_end_mb=$(parted -s "$DISK" unit MiB print | \
        awk '/^Disk / {gsub(/MiB/,"",$3); print int($3)}')

    # Actualizar tabla de particiones
    info "Actualizando tabla de particiones..."
    parted -s "$DISK" resizepart "$win_part_num" "${new_win_end_mb}MiB" || \
        err "Falló la actualización de la tabla de particiones."

    partprobe "$DISK"
    sleep 1

    # Actualizar variables de espacio libre
    FREE_START=$new_win_end_mb
    FREE_END=$disk_end_mb
    FREE_GB=$(( (FREE_END - FREE_START) / 1024 ))

    log "Windows redimensionado: ${win_gb} GB → ${new_win_gb} GB"
    log "Espacio liberado para Arch: ${FREE_GB} GB"
}

# ─────────────────────────────────────────────────────────────────────────────
# MODO DE INSTALACIÓN (disco completo o dual boot)
# ─────────────────────────────────────────────────────────────────────────────
configure_install_mode() {
    title "Modo de instalación"

    info "Particiones actuales en $DISK:"
    lsblk "$DISK" -o NAME,SIZE,FSTYPE,MOUNTPOINTS 2>/dev/null
    echo ""

    echo -e "  ${YELLOW}[1]${NC}  Disco completo  ${DIM}Borra todo el disco — instalación limpia${NC}"
    echo -e "  ${YELLOW}[2]${NC}  Dual boot       ${DIM}Redimensiona Windows automáticamente e instala junto a él${NC}"
    echo ""

    ask "¿Modo de instalación? [1-2, default 1]:"
    read -r mode_choice

    if [[ "$mode_choice" == "2" ]]; then
        INSTALL_MODE="dualboot"

        # Buscar partición NTFS (Windows)
        local win_part win_gb
        win_part=$(lsblk -o NAME,FSTYPE -lpn "$DISK" | awk '$2=="ntfs" {print $1}' | head -1)
        [[ -z "$win_part" ]] && err "No se encontró una partición de Windows (NTFS) en $DISK."

        win_gb=$(lsblk -o SIZE -dn --bytes "$win_part" | awk '{printf "%d", $1/1024/1024/1024}')
        local min_win=20   # mínimo que dejamos a Windows
        local max_arch=$(( win_gb - min_win ))

        if [[ $max_arch -lt 10 ]]; then
            err "La partición de Windows (${win_gb} GB) es demasiado pequeña.\nNecesitás al menos $((min_win + 10)) GB en Windows para hacer dual boot."
        fi

        echo ""
        info "Partición Windows: ${BOLD}$win_part${NC}  (${win_gb} GB)"
        info "Máximo para Arch:  ${BOLD}${max_arch} GB${NC}  (dejando ${min_win} GB mínimo a Windows)"
        echo ""

        local arch_gb
        while true; do
            ask "¿Cuántos GB para Arch? [10-${max_arch}]:"
            read -r arch_gb
            if [[ "$arch_gb" =~ ^[0-9]+$ ]] && (( arch_gb >= 10 && arch_gb <= max_arch )); then
                break
            fi
            warn "Ingresá un número entre 10 y ${max_arch}."
        done

        local new_win_gb=$(( win_gb - arch_gb ))
        echo ""
        info "Windows pasará de ${win_gb} GB → ${BOLD}${new_win_gb} GB${NC}"
        info "Arch usará: ${BOLD}${arch_gb} GB${NC} al final del disco"
        echo ""
        warn "Windows debe estar apagado completamente (no hibernado)."
        warn "Si usás inicio rápido, desactivalo en Windows antes de continuar."
        echo ""
        ask "¿Confirmás la redimensión automática? [s/N]:"
        read -r confirm
        [[ "$confirm" =~ ^[sS]$ ]] || { echo "Cancelado."; exit 0; }

        shrink_windows_partition "$win_part" "$arch_gb" "$win_gb"

        # UEFI: buscar partición EFI existente
        if [[ "$BOOT_MODE" == "UEFI" ]]; then
            EFI_PART=$(lsblk -o NAME,PARTTYPE -lpn "$DISK" 2>/dev/null | \
                awk '$2 == "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" {print $1}' | head -1)
            if [[ -z "$EFI_PART" ]]; then
                local efi_num
                efi_num=$(parted -s "$DISK" print 2>/dev/null | awk '/boot|esp/ {print $1}' | head -1)
                [[ -n "$efi_num" ]] && EFI_PART=$(get_part "$DISK" "$efi_num")
            fi
            [[ -n "$EFI_PART" ]] && log "Partición EFI encontrada: $EFI_PART (se reutilizará)"
        fi

        log "Modo dual boot configurado (${FREE_GB} GB para Arch)"
    else
        INSTALL_MODE="fresh"
        log "Instalación completa del disco"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# SWAP
# ─────────────────────────────────────────────────────────────────────────────
configure_swap() {
    title "Configuración de Swap"

    local ram_kb ram_gb rec
    ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    ram_gb=$(( ram_kb / 1024 / 1024 ))
    [[ $ram_gb -lt 1 ]] && ram_gb=1

    if   (( ram_gb < 2  )); then rec=$(( ram_gb * 2 )); [[ $rec -lt 2 ]] && rec=2
    elif (( ram_gb <= 8 )); then rec=$ram_gb
    else rec=$(( ram_gb / 2 )); [[ $rec -lt 4 ]] && rec=4
    fi

    info "RAM detectada: ${BOLD}${ram_gb} GB${NC}"
    echo ""
    echo -e "  ${BOLD}Guía de swap:${NC}"
    echo -e "  ${DIM}< 2 GB RAM${NC}    →  swap = RAM × 2  ${DIM}(necesario para sistemas con poca RAM)${NC}"
    echo -e "  ${DIM}2 - 8 GB RAM${NC}  →  swap = RAM      ${DIM}(buen balance rendimiento/espacio)${NC}"
    echo -e "  ${DIM}> 8 GB RAM${NC}    →  swap = RAM / 2  ${DIM}(mínimo 4 GB)${NC}"
    echo -e "  ${DIM}Hibernate${NC}     →  swap ≥ RAM      ${DIM}(necesario para suspender al disco)${NC}"
    echo ""
    info "Recomendado para tu sistema: ${BOLD}${rec} GB${NC}"
    echo ""

    ask "¿Usás partición de swap? [S/n]:"
    read -r use_swap_input

    if [[ "$use_swap_input" =~ ^[nN]$ ]]; then
        USE_SWAP=false
        log "Sin swap."
        return
    fi

    ask "Tamaño en GB [Enter = ${rec} GB]:"
    read -r swap_input

    if [[ -z "$swap_input" ]]; then
        SWAP_SIZE=$rec
    elif [[ "$swap_input" =~ ^[0-9]+$ ]] && (( swap_input > 0 )); then
        SWAP_SIZE=$swap_input
    else
        warn "Valor inválido, usando recomendado: ${rec} GB"
        SWAP_SIZE=$rec
    fi

    log "Swap: ${SWAP_SIZE} GB"
}

# ─────────────────────────────────────────────────────────────────────────────
# HOSTNAME
# ─────────────────────────────────────────────────────────────────────────────
configure_hostname() {
    title "Nombre del equipo (hostname)"

    info "El hostname identifica tu PC en la red y en la terminal."
    info "Solo letras, números y guiones. Ej: arch-pc, desktop, workstation"
    echo ""

    while true; do
        ask "Hostname:"
        read -r HOSTNAME
        if [[ "$HOSTNAME" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?$ ]]; then
            break
        fi
        warn "Hostname inválido. Solo letras, números y guiones."
    done

    log "Hostname: $HOSTNAME"
}

# ─────────────────────────────────────────────────────────────────────────────
# ZONA HORARIA
# ─────────────────────────────────────────────────────────────────────────────
configure_timezone() {
    title "Zona horaria"

    local zones=(
        "America/Argentina/Buenos_Aires"
        "America/Santiago"
        "America/Bogota"
        "America/Mexico_City"
        "America/Lima"
        "America/Sao_Paulo"
        "America/Caracas"
        "America/New_York"
        "Europe/Madrid"
        "Europe/London"
        "UTC"
    )

    local i=1
    for z in "${zones[@]}"; do
        echo -e "  ${YELLOW}[$i]${NC}  $z"
        ((i++))
    done
    echo -e "  ${YELLOW}[0]${NC}  Escribir manualmente"
    echo ""
    info "Para buscar zonas: timedatectl list-timezones | grep -i <región>"
    echo ""

    local choice
    ask "Elegí tu zona [1-${#zones[@]} / 0 para manual]:"
    read -r choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#zones[@]} )); then
        TIMEZONE="${zones[$((choice-1))]}"
    else
        while true; do
            ask "Zona horaria (ej: America/Argentina/Buenos_Aires):"
            read -r TIMEZONE
            if timedatectl list-timezones | grep -qx "$TIMEZONE"; then
                break
            fi
            warn "Zona no encontrada. Intentá de nuevo."
        done
    fi

    log "Timezone: $TIMEZONE"
}

# ─────────────────────────────────────────────────────────────────────────────
# LOCALE
# ─────────────────────────────────────────────────────────────────────────────
configure_locale() {
    title "Idioma del sistema"

    echo -e "  ${YELLOW}[1]${NC}  en_US.UTF-8  ${DIM}Inglés - mayor compatibilidad (recomendado)${NC}"
    echo -e "  ${YELLOW}[2]${NC}  es_AR.UTF-8  ${DIM}Español Argentina${NC}"
    echo -e "  ${YELLOW}[3]${NC}  es_ES.UTF-8  ${DIM}Español España${NC}"
    echo -e "  ${YELLOW}[4]${NC}  es_MX.UTF-8  ${DIM}Español México${NC}"
    echo -e "  ${YELLOW}[5]${NC}  pt_BR.UTF-8  ${DIM}Portugués Brasil${NC}"
    echo ""

    ask "Locale [1-5, default 1]:"
    read -r loc_choice

    case "$loc_choice" in
        2) LOCALE="es_AR.UTF-8" ;;
        3) LOCALE="es_ES.UTF-8" ;;
        4) LOCALE="es_MX.UTF-8" ;;
        5) LOCALE="pt_BR.UTF-8" ;;
        *) LOCALE="en_US.UTF-8" ;;
    esac

    log "Locale: $LOCALE"
}

# ─────────────────────────────────────────────────────────────────────────────
# USUARIOS
# ─────────────────────────────────────────────────────────────────────────────
configure_users() {
    title "Configuración de usuarios"

    info "Contraseña del superusuario (root)"
    echo ""

    while true; do
        ask "Contraseña de root:"
        read -rs ROOT_PASS; echo
        ask "Repetí la contraseña:"
        read -rs root_confirm; echo
        if [[ "$ROOT_PASS" == "$root_confirm" && -n "$ROOT_PASS" ]]; then
            break
        fi
        warn "Las contraseñas no coinciden o están vacías. Intentá de nuevo."
    done
    log "Contraseña de root OK"
    echo ""

    ask "¿Creás un usuario normal? [S/n]:"
    read -r create_user_input

    if [[ "$create_user_input" =~ ^[nN]$ ]]; then
        CREATE_USER=false
        warn "Sin usuario normal. Solo vas a poder entrar como root."
        return
    fi

    echo ""
    info "Solo minúsculas, números, guión y guión bajo. Ej: juan, dev_01"

    while true; do
        ask "Nombre de usuario:"
        read -r USERNAME
        if [[ "$USERNAME" =~ ^[a-z][a-z0-9_-]{0,30}$ ]]; then
            break
        fi
        warn "Nombre inválido. Empezá con letra minúscula."
    done

    while true; do
        ask "Contraseña para $USERNAME:"
        read -rs USER_PASS; echo
        ask "Repetí la contraseña:"
        read -rs user_confirm; echo
        if [[ "$USER_PASS" == "$user_confirm" && -n "$USER_PASS" ]]; then
            break
        fi
        warn "Las contraseñas no coinciden o están vacías."
    done

    log "Usuario $USERNAME OK (grupos: wheel, audio, video, storage)"
}

# ─────────────────────────────────────────────────────────────────────────────
# ENTORNO GRÁFICO
# ─────────────────────────────────────────────────────────────────────────────
configure_extras() {
    title "Entorno gráfico (opcional)"

    info "Podés instalar un entorno gráfico ahora o hacerlo después con pacman."
    echo ""
    echo -e "  ${YELLOW}[1]${NC}  Hyprland   ${DIM}Wayland compositor tiling (moderno, ligero)${NC}"
    echo -e "  ${YELLOW}[2]${NC}  KDE Plasma ${DIM}Escritorio completo con muchas opciones${NC}"
    echo -e "  ${YELLOW}[3]${NC}  GNOME      ${DIM}Escritorio simple y moderno${NC}"
    echo -e "  ${YELLOW}[4]${NC}  Solo base  ${DIM}Sin entorno gráfico, configurás después${NC}"
    echo ""

    ask "¿Qué instalás? [1-4, default 4]:"
    read -r extra_choice

    case "$extra_choice" in
        1)
            EXTRA_PKGS="hyprland waybar kitty rofi wofi hyprpaper wlogout \
                        pipewire pipewire-pulse pipewire-alsa wireplumber \
                        xdg-desktop-portal-hyprland qt5-wayland qt6-wayland \
                        polkit-kde-agent dunst grim slurp swappy \
                        thunar tumbler ffmpegthumbnailer file-roller \
                        brightnessctl playerctl pamixer"
            DM=""
            log "Hyprland + herramientas Wayland"
            ;;
        2)
            EXTRA_PKGS="plasma-meta sddm"
            DM="sddm"
            log "KDE Plasma + SDDM"
            ;;
        3)
            EXTRA_PKGS="gnome gnome-extra gdm"
            DM="gdm"
            log "GNOME + GDM"
            ;;
        *)
            EXTRA_PKGS=""
            DM=""
            log "Solo sistema base."
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────────────────────
# HOME SEPARADO
# ─────────────────────────────────────────────────────────────────────────────
configure_home() {
    title "Partición /home separada"

    info "Separar /home permite reinstalar el sistema sin perder tus archivos personales."
    info "Root (/): sistema operativo y programas."
    info "Home (/home): tus archivos, configs de usuario, descargas, etc."
    echo ""

    local avail
    if [[ "$INSTALL_MODE" == "dualboot" ]]; then
        local swap_reserved=0
        $USE_SWAP && swap_reserved=$SWAP_SIZE
        avail=$(( FREE_GB - swap_reserved ))
    else
        local disk_gb
        disk_gb=$(lsblk -dn -o SIZE --bytes "$DISK" 2>/dev/null | awk '{printf "%d", $1/1024/1024/1024}')
        local reserved=1
        $USE_SWAP && reserved=$(( reserved + SWAP_SIZE ))
        avail=$(( disk_gb - reserved ))
    fi

    info "Disco total: ${BOLD}${disk_gb} GB${NC}  |  Disponible tras EFI/swap: ${BOLD}~${avail} GB${NC}"
    echo ""

    ask "¿Usás partición /home separada? [S/n]:"
    read -r use_home_input

    if [[ "$use_home_input" =~ ^[nN]$ ]]; then
        USE_HOME=false
        log "Sin /home separado."
        return
    fi

    USE_HOME=true
    echo ""

    # Recomendación de root según entorno elegido
    local rec_root=40
    [[ -n "$EXTRA_PKGS" ]] && rec_root=50

    echo -e "  ${BOLD}Guía para el tamaño de root:${NC}"
    echo -e "  ${DIM}Solo base${NC}           →  20-30 GB  ${DIM}(sin entorno gráfico)${NC}"
    echo -e "  ${DIM}Con entorno gráfico${NC} →  40-60 GB  ${DIM}(Hyprland, KDE, GNOME)${NC}"
    echo -e "  ${DIM}Con muchos programas${NC} →  60-80 GB  ${DIM}(VMs, IDEs, juegos)${NC}"
    echo ""
    info "Recomendado para tu configuración: ${BOLD}${rec_root} GB${NC}"
    info "Home recibiría el resto: ${BOLD}~$(( avail - rec_root )) GB${NC}"
    echo ""

    while true; do
        ask "Tamaño de root en GB [Enter = ${rec_root} GB]:"
        read -r root_input

        if [[ -z "$root_input" ]]; then
            ROOT_SIZE=$rec_root
            break
        elif [[ "$root_input" =~ ^[0-9]+$ ]] && (( root_input >= 15 )) && (( root_input < avail - 5 )); then
            ROOT_SIZE=$root_input
            break
        elif [[ "$root_input" =~ ^[0-9]+$ ]] && (( root_input < 15 )); then
            warn "Mínimo recomendado: 15 GB."
        else
            warn "Valor inválido. Debe ser menor que el espacio disponible (~${avail} GB), dejando al menos 5 GB para home."
        fi
    done

    local home_gb=$(( avail - ROOT_SIZE ))
    log "Root: ${ROOT_SIZE} GB  →  Home: ~${home_gb} GB"
}

# ─────────────────────────────────────────────────────────────────────────────
# RESUMEN
# ─────────────────────────────────────────────────────────────────────────────
show_summary() {
    clear
    echo -e "${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║              Resumen de instalación                  ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    hr
    if [[ "$INSTALL_MODE" == "dualboot" ]]; then
        printf "  ${CYAN}%-12s${NC} %s\n" "Disco:"    "${BOLD}$DISK${NC}  ${YELLOW}(solo espacio libre — Windows se conserva)${NC}"
    else
        printf "  ${CYAN}%-12s${NC} %s\n" "Disco:"    "${BOLD}$DISK${NC}  ${RED}(será formateado completo)${NC}"
    fi
    printf "  ${CYAN}%-12s${NC} %s\n" "Modo boot:" "$BOOT_MODE"
    printf "  ${CYAN}%-12s${NC} %s\n" "Instalación:" "$( [[ $INSTALL_MODE == dualboot ]] && echo "Dual boot (${FREE_GB} GB libres)" || echo "Disco completo" )"
    if $USE_SWAP; then
        printf "  ${CYAN}%-12s${NC} %s\n" "Swap:"  "${SWAP_SIZE} GB"
    else
        printf "  ${CYAN}%-12s${NC} %s\n" "Swap:"  "Sin swap"
    fi
    if $USE_HOME; then
        printf "  ${CYAN}%-12s${NC} %s\n" "Root (/):"  "${ROOT_SIZE} GB"
        printf "  ${CYAN}%-12s${NC} %s\n" "/home:"     "resto del disco (partición separada)"
    else
        printf "  ${CYAN}%-12s${NC} %s\n" "/home:"     "incluido en root"
    fi
    printf "  ${CYAN}%-12s${NC} %s\n" "Hostname:"  "$HOSTNAME"
    printf "  ${CYAN}%-12s${NC} %s\n" "Timezone:"  "$TIMEZONE"
    printf "  ${CYAN}%-12s${NC} %s\n" "Locale:"    "$LOCALE"
    if $CREATE_USER; then
        printf "  ${CYAN}%-12s${NC} %s\n" "Usuario:"   "$USERNAME  (sudo habilitado)"
    else
        printf "  ${CYAN}%-12s${NC} %s\n" "Usuario:"   "Solo root"
    fi
    if [[ -n "$EXTRA_PKGS" ]]; then
        local first_three
        first_three=$(echo "$EXTRA_PKGS" | tr ' ' '\n' | head -3 | tr '\n' ' ')
        printf "  ${CYAN}%-12s${NC} %s\n" "Extra:"     "${first_three}..."
    else
        printf "  ${CYAN}%-12s${NC} %s\n" "Extra:"     "Solo base"
    fi
    hr
    echo ""
    echo -e "  ${RED}${BOLD}⚠  Todo el contenido de $DISK será eliminado.${NC}"
    echo ""
    ask "¿Iniciás la instalación? [s/N]:"
    read -r final
    [[ "$final" =~ ^[sS]$ ]] || { echo "Cancelado."; exit 0; }
}

# ─────────────────────────────────────────────────────────────────────────────
# PARTICIONADO
# ─────────────────────────────────────────────────────────────────────────────
do_partition() {
    if [[ "$INSTALL_MODE" == "dualboot" ]]; then
        do_partition_dualboot
        return
    fi

    step "1" "Particionando $DISK"

    local swap_mb=$(( SWAP_SIZE * 1024 ))
    local root_mb=$(( ROOT_SIZE * 1024 ))

    wipefs -af "$DISK" &>/dev/null
    sgdisk -Z "$DISK" &>/dev/null || true

    if [[ "$BOOT_MODE" == "UEFI" ]]; then
        parted -s "$DISK" mklabel gpt
        parted -s "$DISK" mkpart "EFI" fat32 1MiB 513MiB
        parted -s "$DISK" set 1 esp on

        local cur=513

        if $USE_SWAP; then
            local swap_end=$(( cur + swap_mb ))
            parted -s "$DISK" mkpart "swap" linux-swap "${cur}MiB" "${swap_end}MiB"
            cur=$swap_end
        fi

        if $USE_HOME; then
            local root_end=$(( cur + root_mb ))
            parted -s "$DISK" mkpart "root" ext4 "${cur}MiB" "${root_end}MiB"
            parted -s "$DISK" mkpart "home" ext4 "${root_end}MiB" 100%
        else
            parted -s "$DISK" mkpart "root" ext4 "${cur}MiB" 100%
        fi
    else
        parted -s "$DISK" mklabel msdos

        local cur=1
        local boot_pnum=1

        if $USE_SWAP; then
            local swap_end=$(( cur + swap_mb ))
            parted -s "$DISK" mkpart primary linux-swap "${cur}MiB" "${swap_end}MiB"
            cur=$swap_end
            boot_pnum=2
        fi

        if $USE_HOME; then
            local root_end=$(( cur + root_mb ))
            parted -s "$DISK" mkpart primary ext4 "${cur}MiB" "${root_end}MiB"
            parted -s "$DISK" mkpart primary ext4 "${root_end}MiB" 100%
        else
            parted -s "$DISK" mkpart primary ext4 "${cur}MiB" 100%
        fi

        parted -s "$DISK" set $boot_pnum boot on
    fi

    partprobe "$DISK"
    sleep 2
    log "Tabla de particiones creada"
}

do_partition_dualboot() {
    step "1" "Creando particiones en espacio libre de $DISK"

    # Contar particiones existentes para saber qué números tendrán las nuevas
    FIRST_NEW_PNUM=$(parted -s "$DISK" print 2>/dev/null | awk '/^ [0-9]/ {count++} END {print count+1}')

    local swap_mb=$(( SWAP_SIZE * 1024 ))
    local root_mb=$(( ROOT_SIZE * 1024 ))
    local cur=$FREE_START

    if $USE_SWAP; then
        local swap_end=$(( cur + swap_mb ))
        parted -s "$DISK" mkpart "swap" linux-swap "${cur}MiB" "${swap_end}MiB"
        cur=$swap_end
    fi

    if $USE_HOME; then
        local root_end=$(( cur + root_mb ))
        parted -s "$DISK" mkpart "root" ext4 "${cur}MiB" "${root_end}MiB"
        parted -s "$DISK" mkpart "home" ext4 "${root_end}MiB" "${FREE_END}MiB"
    else
        parted -s "$DISK" mkpart "root" ext4 "${cur}MiB" "${FREE_END}MiB"
    fi

    partprobe "$DISK"
    sleep 2
    log "Particiones creadas en espacio libre"
}

# ─────────────────────────────────────────────────────────────────────────────
# FORMATEO Y MONTAJE
# ─────────────────────────────────────────────────────────────────────────────
do_format_mount() {
    step "2" "Formateando y montando particiones"

    local efi_part="" swap_part="" root_part="" home_part=""

    if [[ "$INSTALL_MODE" == "dualboot" ]]; then
        # Particiones nuevas empiezan en FIRST_NEW_PNUM
        local pnum=$FIRST_NEW_PNUM
        if $USE_SWAP; then
            swap_part=$(get_part "$DISK" $pnum); (( pnum++ ))
        fi
        root_part=$(get_part "$DISK" $pnum); (( pnum++ ))
        if $USE_HOME; then
            home_part=$(get_part "$DISK" $pnum)
        fi
        # UEFI: reusar EFI existente sin formatear
        [[ "$BOOT_MODE" == "UEFI" && -n "$EFI_PART" ]] && efi_part="$EFI_PART"
    else
        local pnum=1
        if [[ "$BOOT_MODE" == "UEFI" ]]; then
            efi_part=$(get_part "$DISK" $pnum); (( pnum++ ))
        fi
        if $USE_SWAP; then
            swap_part=$(get_part "$DISK" $pnum); (( pnum++ ))
        fi
        root_part=$(get_part "$DISK" $pnum); (( pnum++ ))
        if $USE_HOME; then
            home_part=$(get_part "$DISK" $pnum)
        fi
    fi

    # Formatear
    if [[ -n "$efi_part" && "$INSTALL_MODE" != "dualboot" ]]; then
        mkfs.fat -F32 "$efi_part" &>/dev/null
        log "EFI:  $efi_part → fat32"
    elif [[ -n "$efi_part" ]]; then
        log "EFI:  $efi_part → reutilizada (sin formatear)"
    fi
    if [[ -n "$swap_part" ]]; then
        mkswap "$swap_part" &>/dev/null
        swapon "$swap_part"
        log "Swap: $swap_part → activa"
    fi
    mkfs.ext4 -F "$root_part" &>/dev/null
    log "Root: $root_part → ext4"
    if [[ -n "$home_part" ]]; then
        mkfs.ext4 -F "$home_part" &>/dev/null
        log "Home: $home_part → ext4"
    fi

    # Montar
    mount "$root_part" /mnt
    if [[ -n "$efi_part" ]]; then
        mkdir -p /mnt/boot
        mount "$efi_part" /mnt/boot
    fi
    if [[ -n "$home_part" ]]; then
        mkdir -p /mnt/home
        mount "$home_part" /mnt/home
    fi

    log "Particiones montadas en /mnt"
}

# ─────────────────────────────────────────────────────────────────────────────
# PACSTRAP
# ─────────────────────────────────────────────────────────────────────────────
do_pacstrap() {
    step "3" "Instalando sistema base (puede tardar varios minutos)"

    local pkgs="base base-devel linux linux-firmware linux-headers \
                networkmanager sudo nano vim git curl wget \
                grub os-prober"

    [[ "$BOOT_MODE" == "UEFI" ]] && pkgs="$pkgs efibootmgr"
    [[ -n "$EXTRA_PKGS" ]]       && pkgs="$pkgs $EXTRA_PKGS"

    # shellcheck disable=SC2086
    pacstrap -K /mnt $pkgs

    log "Paquetes instalados"

    genfstab -U /mnt >> /mnt/etc/fstab
    log "fstab generado"
}

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN EN CHROOT
# ─────────────────────────────────────────────────────────────────────────────
do_chroot_config() {
    step "4" "Configurando el sistema"

    local setup="/mnt/root/setup.sh"

    # Construir script que se ejecuta dentro del chroot
    {
        echo "#!/bin/bash"
        echo "set -e"
        echo ""

        echo "# Timezone"
        echo "ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime"
        echo "hwclock --systohc"
        echo ""

        echo "# Locale"
        echo "echo '${LOCALE} UTF-8' >> /etc/locale.gen"
        echo "locale-gen"
        echo "echo 'LANG=${LOCALE}' > /etc/locale.conf"
        echo ""

        echo "# Hostname"
        echo "echo '${HOSTNAME}' > /etc/hostname"
        echo "printf '127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t${HOSTNAME}.localdomain ${HOSTNAME}\n' >> /etc/hosts"
        echo ""

        echo "# NetworkManager"
        echo "systemctl enable NetworkManager"
        echo ""

        echo "# Contraseña root"
        echo "echo 'root:${ROOT_PASS}' | chpasswd"
        echo ""

        if $CREATE_USER; then
            echo "# Usuario $USERNAME"
            echo "useradd -m -G wheel,audio,video,storage,optical -s /bin/bash '${USERNAME}'"
            echo "echo '${USERNAME}:${USER_PASS}' | chpasswd"
            echo "sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers"
            echo ""
        fi

        echo "# Bootloader GRUB"
        if [[ "$BOOT_MODE" == "UEFI" ]]; then
            echo "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB"
        else
            echo "grub-install --target=i386-pc ${DISK}"
        fi
        echo "sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub"
        echo "grub-mkconfig -o /boot/grub/grub.cfg"
        echo ""

        if [[ -n "$DM" ]]; then
            echo "# Display manager"
            echo "systemctl enable ${DM}"
            echo ""
        fi

        echo "echo '::SETUP_DONE::'"
    } > "$setup"

    chmod +x "$setup"

    local output
    output=$(arch-chroot /mnt /root/setup.sh 2>&1) || {
        echo "$output" | tail -30
        err "Falló la configuración del sistema. Ver output arriba."
    }

    if echo "$output" | grep -q "::SETUP_DONE::"; then
        log "Timezone, locale, hostname configurados"
        log "Bootloader GRUB instalado"
        $CREATE_USER && log "Usuario $USERNAME creado con sudo"
        [[ -n "$DM" ]] && log "Display manager $DM habilitado"
    else
        echo "$output" | tail -30
        err "No se completó la configuración. Ver output arriba."
    fi

    rm -f "$setup"
}

# ─────────────────────────────────────────────────────────────────────────────
# LIMPIEZA Y FINALIZACIÓN
# ─────────────────────────────────────────────────────────────────────────────
do_finish() {
    step "5" "Finalizando"

    umount -R /mnt 2>/dev/null || true
    swapoff -a 2>/dev/null || true

    log "Particiones desmontadas"
    echo ""
    hr
    echo ""
    echo -e "  ${GREEN}${BOLD}✓  Instalación completa.${NC}"
    echo ""
    echo -e "  Próximos pasos:"
    echo -e "  ${CYAN}1.${NC}  Sacá el USB/ISO de arranque"
    echo -e "  ${CYAN}2.${NC}  Reiniciá: ${BOLD}reboot${NC}"
    [[ -n "$USERNAME" ]] && echo -e "  ${CYAN}3.${NC}  Entrá con el usuario: ${BOLD}$USERNAME${NC}"
    echo ""
    hr
    echo ""

    ask "¿Reiniciás ahora? [s/N]:"
    read -r reboot_now
    [[ "$reboot_now" =~ ^[sS]$ ]] && reboot
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────
main() {
    welcome
    check_prereqs

    # Recolectar toda la info antes de tocar el disco
    select_disk
    configure_install_mode
    configure_swap
    configure_hostname
    configure_timezone
    configure_locale
    configure_users
    configure_extras
    configure_home
    show_summary

    # Ejecutar instalación
    do_partition
    do_format_mount
    do_pacstrap
    do_chroot_config
    do_finish
}

main "$@"
