# Dotfiles – Sway (Fedora)

Configs do Sway, Waybar, Mako e Kanshi.

## Conteúdo
- `sway/config` – Sway (fonte, borda, workspaces por monitor, teclado US/ABNT2, atalhos)
- `waybar/` – barra (`config.jsonc` e `style.css`)
- `mako/config` – notificações
- `kanshi/config` – perfis de monitor aplicados automaticamente ao plugar/desplugar (notebook sozinho; notebook + projetor Epson)

## Atalhos extras
- `$mod+Escape` – bloquear a tela (swaylock)
- `Shift+Print` – print de uma área direto para o clipboard
- `$mod+Shift+v` – histórico do clipboard (cliphist + rofi)

## Instalar
```bash
sudo dnf install sway waybar mako kanshi cliphist wl-clipboard grimshot swaylock rofi
mkdir -p ~/.config
cp -r sway waybar mako kanshi ~/.config/
systemctl --user enable --now kanshi
swaymsg reload
```

## Ajustar na outra máquina
- **Monitores:** em `sway/config`, as regras `workspace N output ...` usam `eDP-1` (notebook) e `DP-1/DP-2/HDMI-A-1` (externo). Veja os nomes com `swaymsg -t get_outputs`.
- **Bateria:** se o Waybar fechar sozinho por causa de baterias de dispositivos, fixe `"bat"` e `"adapter"` no módulo `battery`. Em desktop, tire `"battery"` da lista de módulos.
- **Kanshi:** os perfis usam o nome/modelo dos monitores desta máquina; refaça com os dados de `swaymsg -t get_outputs`.
- **Wallpaper:** `output * bg ...` aponta para `/usr/share/backgrounds/default.jxl`.
