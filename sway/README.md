# Dotfiles – Sway (Fedora)

Configs do Sway, Waybar e Mako.

## Conteúdo
- `sway/config` – Sway (fonte, borda, workspaces por monitor, teclado US/ABNT2, atalhos)
- `waybar/` – barra (`config.jsonc` e `style.css`)
- `mako/config` – notificações

## Instalar
```bash
sudo dnf install sway waybar mako
mkdir -p ~/.config
cp -r sway waybar mako ~/.config/
swaymsg reload
```

## Ajustar na outra máquina
- **Monitores:** em `sway/config`, as regras `workspace N output ...` usam `eDP-1` (notebook) e `DP-0/DP-1/DP-2/HDMI-A-1` (externo). Veja os nomes com `swaymsg -t get_outputs`.
- **Bateria:** se o Waybar fechar sozinho por causa de baterias de dispositivos, fixe `"bat"` e `"adapter"` no módulo `battery`. Em desktop, tire `"battery"` da lista de módulos.
- **Wallpaper:** `output * bg ...` aponta para `/usr/share/backgrounds/default.jxl`.
