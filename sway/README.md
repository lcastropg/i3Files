# Dotfiles – Sway (Fedora)

Configs do Sway, Swaylock, Waybar, Mako e Kanshi.

## Conteúdo
- `sway/config` – Sway (fonte, borda, workspaces por monitor, teclado US/ABNT2, atalhos)
- `sway/config.d/90-swayidle.conf` – substitui o swayidle padrão do Fedora: 5 min ocioso bloqueia e apaga a tela; bloqueio manual apaga a tela após 60 s
- `sway/scripts/wallpaper-rotate.sh` – troca o wallpaper a cada 15 min entre as imagens de `~/Pictures/Wallpapers/landscapes` (ordem aleatória; `pkill -USR1 -f wallpaper-rotate.sh` pula para a próxima). As imagens não ficam no repo: o post-install baixa do Wikimedia Commons as listadas em `wallpapers/CREDITS.json` (autor e licença de cada uma); sem elas, fica o wallpaper padrão do Fedora
- `swaylock/config` – tela de bloqueio (fundo preto, cores da waybar, aviso de Caps Lock e layout)
- `waybar/` – barra (`config.jsonc` e `style.css`)
- `mako/config` – notificações
- `kanshi/config` – perfis de monitor aplicados automaticamente ao plugar/desplugar (notebook sozinho; notebook + projetor Epson)

## Atalhos extras
- `$mod+Escape` – bloquear a tela (`loginctl lock-session` → swayidle → swaylock)
- `Shift+Print` – print de uma área direto para o clipboard
- `$mod+Shift+v` – histórico do clipboard (cliphist + rofi)
- `$mod+Shift+d` – trocar de janela (rofi window)
- `$mod+Ctrl+d` – menu de energia (rofi-power-menu)
- `$mod+Ctrl+>` / `$mod+Ctrl+<` – mover o workspace para o monitor da direita/esquerda
- `$mod+Ctrl+1..6` – conectar/desconectar os dispositivos bluetooth (ímpar conecta, par desconecta)
- `$mod+r` – entra e sai do modo resize

## Instalação completa (Fedora 45 recém-instalado)
O script `post-install-fedora45-sway.sh` instala os apps e ferramentas, clona este repo e aplica as configs:
```bash
curl -fsSLO https://raw.githubusercontent.com/lcastropg/i3Files/main/sway/post-install-fedora45-sway.sh
chmod +x post-install-fedora45-sway.sh
./post-install-fedora45-sway.sh -c notebook   # ou -c desktop
```
- `notebook`: configs como estão aqui (workspaces 1–5 no `eDP-1`, 6–10 no externo, kanshi).
- `desktop`: workspaces 1–5 no `DP-1` e 6–10 no `HDMI-A-1`, waybar sem bateria, sem kanshi.

## Instalar só as configs
```bash
sudo dnf install sway waybar mako kanshi cliphist wl-clipboard grimshot swaylock rofi
mkdir -p ~/.config
cp -r sway swaylock waybar mako kanshi ~/.config/
systemctl --user enable --now kanshi

# Menu de energia (https://github.com/jluttine/rofi-power-menu)
curl -fsSL -o ~/.local/bin/rofi-power-menu https://raw.githubusercontent.com/jluttine/rofi-power-menu/master/rofi-power-menu
chmod +x ~/.local/bin/rofi-power-menu

# MEGAsync (rpmfusion) – módulos QML que o pacote não puxa; sem eles ele crasha ao abrir
sudo dnf install megasync qt5-qtgraphicaleffects qt5-qtquickcontrols qt5-qtquickcontrols2
swaymsg reload
```

## Ajustar na outra máquina
- **Monitores:** em `sway/config`, as regras `workspace N output ...` usam `eDP-1` (notebook) e `DP-1/DP-2/HDMI-A-1` (externo). Veja os nomes com `swaymsg -t get_outputs`.
- **Bateria:** se o Waybar fechar sozinho por causa de baterias de dispositivos, fixe `"bat"` e `"adapter"` no módulo `battery`. Em desktop, tire `"battery"` da lista de módulos.
- **Kanshi:** os perfis usam o nome/modelo dos monitores desta máquina; refaça com os dados de `swaymsg -t get_outputs`.
- **Bluetooth:** os atalhos `$mod+Ctrl+1..6` usam os MACs dos meus dispositivos; troque em `sway/config` (veja com `bluetoothctl devices`).
- **Wallpaper:** `output * bg ...` aponta para `/usr/share/backgrounds/default.jxl`.
