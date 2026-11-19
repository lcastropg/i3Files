#!/usr/bin/env bash
# Instala o tema de login (SDDM) e o sway do greeter. Uso: ./install.sh [imagem-de-fundo]
# Sem argumento usa uma das paisagens de ~/Pictures/Wallpapers/landscapes; se não achar, fundo sólido.
set -euo pipefail
cd "$(dirname "$0")"

bg="${1:-$HOME/Pictures/Wallpapers/landscapes/07-seceda-dolomitas.jpg}"
theme=/usr/share/sddm/themes/sway-lcastro

sudo install -d "$theme" /etc/sddm.conf.d
sudo install -m 0644 theme/sway-lcastro/* "$theme"/
if [[ -f "$bg" ]]; then
  sudo install -m 0644 "$bg" "$theme/background.jpg"
else
  echo "Fundo '$bg' não encontrado: usando cor sólida."
fi
sudo install -m 0644 greeter.config /etc/sway/sddm-greeter-lcastro.config
sudo install -m 0755 sddm-compositor-sway-lcastro /usr/local/bin/sddm-compositor-sway-lcastro
sudo install -m 0644 sddm.conf.d/10-sway-lcastro.conf /etc/sddm.conf.d/10-sway-lcastro.conf
sudo restorecon -R "$theme" /etc/sway/sddm-greeter-lcastro.config \
  /usr/local/bin/sddm-compositor-sway-lcastro /etc/sddm.conf.d 2>/dev/null || true

echo "Pronto. Vale na próxima vez que a tela de login abrir (logout ou reboot)."
echo "Desfazer: sudo rm /etc/sddm.conf.d/10-sway-lcastro.conf"
