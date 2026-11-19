# i3Files

Meus dotfiles do Linux: começou com i3 e hoje o ambiente principal é o **Sway no Fedora**.

## O que tem aqui
| Caminho | O que é |
|---|---|
| [`sway/`](sway/README.md) | Ambiente atual (Fedora + Sway): sway, waybar, swaylock, mako, kanshi, tela de login (SDDM), wallpapers e o script de pós-instalação. Detalhes no [README do sway](sway/README.md) |
| `i3_config` | Config antiga do i3 (X11) |
| `.i3status.conf` | Barra do i3 (i3status), usada junto com o `i3_config` |
| `easy-effects/` | Presets do EasyEffects para os fones (`g506`, `g930`, `soul`). Importe pelo próprio EasyEffects |

## Começo rápido (Fedora 45 + Sway)
```bash
curl -fsSLO https://raw.githubusercontent.com/lcastropg/i3Files/main/sway/post-install-fedora45-sway.sh
chmod +x post-install-fedora45-sway.sh
./post-install-fedora45-sway.sh -c notebook   # ou -c desktop
```
A tela de login é instalada à parte, com sudo: `sway/sddm/install.sh` (veja [sway/README.md](sway/README.md#tela-de-login-sddm)).
