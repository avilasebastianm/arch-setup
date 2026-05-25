# Arch Linux Installer

Instalador interactivo y guiado para Arch Linux. Hace preguntas en cada paso, explica las opciones y ejecuta todo automáticamente.

## Requisitos

- Bootear desde el [ISO oficial de Arch Linux](https://archlinux.org/download/)
- Conexión a internet activa
- Ejecutar como root

## Uso

```bash
git clone https://github.com/avilasebastianm/arch-custom.git
cd arch-custom/archInstall
chmod +x install.sh
./install.sh
```

## Qué hace

El script recolecta toda la información primero y luego ejecuta la instalación. No toca el disco hasta que confirmás el resumen final.

### Configuración interactiva

| Paso | Qué pregunta |
|------|-------------|
| Disco | Lista los discos disponibles con modelo y tamaño. Pedís confirmación doble antes de formatear |
| Swap | Detecta tu RAM y recomienda el tamaño. Incluye guía según uso (hibernación, RAM disponible) |
| /home | Opción de partición separada. Muestra espacio disponible y recomienda tamaño de root según el entorno elegido |
| Hostname | Nombre del equipo en la red |
| Timezone | Lista de zonas comunes + opción manual |
| Locale | Inglés, Español AR/ES/MX, Portugués BR |
| Usuarios | Contraseña de root + usuario normal con sudo |
| Entorno gráfico | Hyprland, KDE Plasma, GNOME, o solo base |

### Instalación automática

```
[1/5] Particiona el disco (GPT/MBR según UEFI o BIOS)
[2/5] Formatea y monta las particiones
[3/5] Instala el sistema base con pacstrap
[4/5] Configura timezone, locale, hostname, GRUB y usuarios
[5/5] Desmonta y pregunta si reiniciás
```

## Layouts de partición

Dependiendo de lo que elegís, el disco queda así:

**UEFI + swap + /home separado**
```
/dev/sdX1  →  EFI       512 MB   fat32
/dev/sdX2  →  swap      X GB     linux-swap
/dev/sdX3  →  /         X GB     ext4
/dev/sdX4  →  /home     resto    ext4
```

**UEFI sin swap, sin /home separado**
```
/dev/sdX1  →  EFI       512 MB   fat32
/dev/sdX2  →  /         resto    ext4
```

**BIOS + swap + /home separado**
```
/dev/sdX1  →  swap      X GB     linux-swap
/dev/sdX2  →  /         X GB     ext4
/dev/sdX3  →  /home     resto    ext4
```

## Paquetes base instalados

```
base  base-devel  linux  linux-firmware  linux-headers
networkmanager  sudo  grub  os-prober  git  curl  wget  nano  vim
efibootmgr  (solo UEFI)
```

### Entorno gráfico opcional

| Opción | Paquetes principales |
|--------|---------------------|
| Hyprland | hyprland waybar kitty rofi pipewire wireplumber xdg-desktop-portal-hyprland |
| KDE Plasma | plasma-meta sddm |
| GNOME | gnome gnome-extra gdm |

## Después de instalar

Si también querés aplicar los dotfiles (Hyprland, Waybar, Neovim, etc.):

```bash
cd ../archTheme
chmod +x install.sh
./install.sh
```

## Compatibilidad

- UEFI y BIOS/Legacy
- Discos SATA (`/dev/sdX`), NVMe (`/dev/nvmeXnX`) y eMMC (`/dev/mmcblkX`)
- Bootloader: GRUB
- Filesystem: ext4
