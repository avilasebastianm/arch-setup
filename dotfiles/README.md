# Dotfiles

Configuración de Arch Linux con Hyprland.

## Stack

- **WM**: Hyprland
- **Bar**: Waybar
- **Launcher**: Rofi
- **Terminal**: Kitty
- **Editor**: Neovim
- **Shell**: Zsh + Starship
- **File manager**: Yazi
- **Multiplexer**: Tmux

## Instalación

```bash
git clone https://github.com/avilasebastianm/arch-setup.git
cd arch-setup/dotfiles
chmod +x install.sh
./install.sh
```

## Estructura

```
.
├── install.sh          # Script de instalación
├── configs/            # Configs de ~/.config/
│   ├── hypr/
│   ├── waybar/
│   ├── rofi/
│   ├── kitty/
│   ├── nvim/
│   ├── yazi/
│   ├── tmux/
│   └── starship.toml
├── home/               # Archivos de ~/
│   └── .zshrc
├── fonts/              # Fuentes custom
└── packages/
    ├── pkglist.txt     # Paquetes oficiales
    └── pkglist-aur.txt # Paquetes AUR
```



