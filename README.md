# arch-setup

Instalador y dotfiles personalizados para **Arch Linux + Hyprland**.

```
arch-setup/
├── dotfiles/      # Configs: Hyprland, Waybar, Kitty, Neovim, Dunst, Rofi…
└── arch-install/  # Script de instalación interactivo con soporte dual boot
```

---

## dotfiles

Tema visual basado en **Dracula** para un entorno Wayland completo.

| App | Descripción |
|-----|-------------|
| Hyprland | Compositor Wayland con keybinds y animaciones |
| Waybar | Barra con módulos de audio, red, batería y workspaces |
| Kitty | Terminal con JetBrainsMono Nerd Font |
| Dunst | Notificaciones con iconos pixel art aleatorios |
| Rofi | Launcher y selector de salida de audio |
| Neovim | Editor con configuración personalizada |
| Yazi | File manager en terminal |
| Starship | Prompt minimalista |

### Instalación rápida

```bash
git clone https://github.com/avilasebastianm/arch-setup.git
cd arch-setup/dotfiles
bash install.sh
```

---

## arch-install

Instalador interactivo de Arch Linux con:

- Selección de disco y particionado automático
- Soporte **dual boot** con Windows (redimensiona partición NTFS automáticamente)
- Opciones: swap, home separado, entorno gráfico
- GRUB con detección de otros sistemas operativos

### Uso desde live ISO

```bash
# Conectarse a internet primero:
# WiFi:     iwctl station wlan0 connect "SSID"
# Ethernet: dhcpcd

curl -L https://raw.githubusercontent.com/avilasebastianm/arch-setup/main/arch-install/install.sh | bash
```

---

## Requisitos

- Arch Linux (live ISO o instalación base)
- Conexión a internet
- UEFI / GPT

## Capturas

> Hyprland · Waybar · Dunst con iconos pixel art aleatorios

---

*Hecho en Buenos Aires 🇦🇷*
