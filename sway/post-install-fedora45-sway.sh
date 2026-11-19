#!/usr/bin/env bash
# Fedora 45 Sway workstation bootstrap. Run as a normal user.
# Instala apps/ferramentas e aplica os dotfiles de https://github.com/lcastropg/i3Files (pasta sway/).
#
# Uso: ./post-install-fedora45-sway.sh -c desktop|notebook
#   notebook  configs como estao no repo (workspaces 1-5 no eDP-1, 6-10 no externo, kanshi)
#   desktop   workspaces 1-5 no DP-1 e 6-10 no HDMI-A-1, waybar sem bateria, sem kanshi
set -Eeuo pipefail

usage() { echo "Uso: $0 -c desktop|notebook"; }
PROFILE=''
while getopts ':c:h' opt; do
  case "$opt" in
    c) PROFILE="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done
case "$PROFILE" in
  desktop|notebook) ;;
  *) usage; exit 1 ;;
esac

if (( EUID == 0 )); then echo 'Execute como usuario normal (sem sudo no comando).'; exit 1; fi
if [[ ! -r /etc/os-release ]]; then echo 'Sistema nao identificado.'; exit 1; fi
source /etc/os-release
if [[ "${ID:-}" != fedora ]]; then echo 'Este script requer Fedora.'; exit 1; fi
FEDORA_VERSION="$(rpm -E '%fedora')"
if [[ "$FEDORA_VERSION" != 45 ]]; then
  echo "AVISO: este script foi preparado para Fedora 45; detectado Fedora $FEDORA_VERSION."
  read -r -p 'Continuar mesmo assim? [s/N] ' answer
  [[ "$answer" =~ ^[sS]$ ]] || exit 1
fi
if [[ "$(uname -m)" != x86_64 ]]; then
  echo 'AVISO: Chrome, VS Code e MEGAsync podem nao ter RPM para esta arquitetura.'
fi

DOTFILES_REPO='https://github.com/lcastropg/i3Files.git'
DOTFILES_DIR="$HOME/i3Files"
STAMP="$(date +%Y%m%d-%H%M%S)"

LOG_DIR="$HOME/.local/state/fedora-post-install"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install-$STAMP.log"
exec > >(tee -a "$LOG_FILE") 2>&1
FAILED=()
SUCCESS=()

log() { printf '\n[%s] %s\n' "$(date '+%F %T')" "$*"; }
step() {
  local label="$1"; shift
  log "INICIO: $label"
  if "$@"; then SUCCESS+=("$label"); log "OK: $label";
  else local rc=$?; FAILED+=("$label (codigo $rc)"); log "FALHA: $label (codigo $rc) - continuando"; fi
}
# Tenta um comando ate 3 vezes (rede instavel logo apos a instalacao)
retry() {
  local n
  for n in 1 2 3; do
    "$@" && return 0
    log "Tentativa $n falhou: $*"
    sleep 5
  done
  return 1
}
install_pkg() {
  local pkg="$1"
  if rpm -q "$pkg" >/dev/null 2>&1; then log "Ja instalado: $pkg"; return 0; fi
  # Sem pre-checagem com repoquery (escondia o erro real com 2>/dev/null);
  # se o pacote nao existir, o proprio dnf diz "No match for argument" no log.
  sudo dnf install -y "$pkg"
}
install_group() {
  local group="$1"; shift
  local pkg
  for pkg in "$@"; do step "$group / $pkg" install_pkg "$pkg"; done
}
install_flatpak() {
  local app="$1"
  if flatpak info --system "$app" >/dev/null 2>&1; then log "Flatpak ja instalado: $app"; return 0; fi
  retry sudo flatpak install --system -y --noninteractive flathub "$app"
}
write_repo() {
  local dest="$1" tmp
  tmp="$(mktemp)"
  cat > "$tmp"
  sudo install -m 0644 "$tmp" "$dest"
  rm -f "$tmp"
}

setup_flathub() {
  retry sudo flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}
setup_rpmfusion() {
  if rpm -q rpmfusion-free-release rpmfusion-nonfree-release >/dev/null 2>&1; then return 0; fi
  retry sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm"
}
# Troca o ffmpeg "free" do Fedora pelo completo do RPM Fusion. Sem isso, o megasync
# falha com conflito entre libswscale-free e ffmpeg-libs.
setup_ffmpeg() {
  if rpm -q ffmpeg-libs >/dev/null 2>&1; then return 0; fi
  sudo dnf install -y --allowerasing ffmpeg ffmpeg-libs
}
# O arquivo .repo que o script antigo baixava do Google da 404; escrevemos o repo direto.
setup_chrome_repo() {
  [[ "$(uname -m)" == x86_64 ]] || return 1
  [[ -f /etc/yum.repos.d/google-chrome.repo ]] && return 0
  write_repo /etc/yum.repos.d/google-chrome.repo <<'REPO'
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
REPO
}
setup_vscode_repo() {
  [[ "$(uname -m)" == x86_64 ]] || return 1
  [[ -f /etc/yum.repos.d/vscode.repo ]] && return 0
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  write_repo /etc/yum.repos.d/vscode.repo <<'REPO'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
REPO
}

# Clona (ou atualiza) o repo de dotfiles via HTTPS: funciona sem chave SSH na maquina nova.
setup_dotfiles_repo() {
  if [[ -d "$DOTFILES_DIR/.git" ]]; then
    git -C "$DOTFILES_DIR" pull --ff-only
  else
    retry git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
}
# Copia sway, swaylock, waybar, mako e kanshi para ~/.config. O que ja existir vai para <dir>.bak-<data>.
apply_dotfiles() {
  local src="$DOTFILES_DIR/sway" name
  [[ -d "$src" ]] || { log "Pasta nao encontrada: $src"; return 1; }
  mkdir -p "$HOME/.config"
  local names=(sway swaylock waybar mako)
  [[ "$PROFILE" == notebook ]] && names+=(kanshi)
  for name in "${names[@]}"; do
    [[ -d "$src/$name" ]] || continue
    if [[ -e "$HOME/.config/$name" ]]; then
      mv "$HOME/.config/$name" "$HOME/.config/$name.bak-$STAMP"
      log "Backup: ~/.config/$name -> ~/.config/$name.bak-$STAMP"
    fi
    cp -r "$src/$name" "$HOME/.config/$name"
  done
  if [[ "$PROFILE" == desktop ]]; then apply_desktop_overrides; fi
}
# Ajustes do desktop (outputs do antigo ~/desktop-config) sobre as configs do notebook
apply_desktop_overrides() {
  local sway="$HOME/.config/sway/config" waybar="$HOME/.config/waybar/config.jsonc"
  sed -i -E \
    -e 's/^([[:space:]]*workspace[[:space:]]+([1-5])[[:space:]]+output)[[:space:]].*/\1 DP-1/' \
    -e 's/^([[:space:]]*workspace[[:space:]]+([6-9]|10)[[:space:]]+output)[[:space:]].*/\1 HDMI-A-1/' \
    -e 's/^([[:space:]]*# Workspaces por monitor:).*/\1 1-5 no DP-1, 6-10 no HDMI-A-1 (desktop)/' \
    "$sway"
  # Desktop nao tem bateria
  [[ -f "$waybar" ]] && sed -i -E '/^[[:space:]]*"battery",[[:space:]]*$/d' "$waybar"
  log 'Perfil desktop aplicado: workspaces 1-5 -> DP-1, 6-10 -> HDMI-A-1; waybar sem bateria'
  grep -nE '^[[:space:]]*workspace[[:space:]]+[0-9]+[[:space:]]+output' "$sway"
}
# Menu de energia do rofi ($mod+Ctrl+d): https://github.com/jluttine/rofi-power-menu
setup_rofi_power_menu() {
  local dest="$HOME/.local/bin/rofi-power-menu" tmp
  [[ -x "$dest" ]] && return 0
  tmp="$(mktemp)"
  retry curl -fsSL -o "$tmp" https://raw.githubusercontent.com/jluttine/rofi-power-menu/master/rofi-power-menu
  install -Dm755 "$tmp" "$dest"
  rm -f "$tmp"
}
# Wallpapers do wallpaper-rotate.sh: baixa do Wikimedia Commons as imagens listadas em wallpapers/CREDITS.json
setup_wallpapers() {
  local credits="$DOTFILES_DIR/sway/wallpapers/CREDITS.json" dest="$HOME/Pictures/Wallpapers/landscapes"
  local file name width tmp fail=0
  [[ -f "$credits" ]] || { log "Arquivo nao encontrado: $credits"; return 1; }
  mkdir -p "$dest"
  cp "$credits" "$dest/CREDITS.json"
  while IFS=$'\t' read -r file name width; do
    [[ -s "$dest/$file" ]] && continue
    tmp="$(mktemp)"
    if retry curl -fsSL -A 'fedora-post-install/1.0' -o "$tmp" \
         "https://commons.wikimedia.org/wiki/Special:FilePath/$name?width=$width"; then
      mv "$tmp" "$dest/$file"; log "Wallpaper: $file"
    else
      rm -f "$tmp"; log "Falha ao baixar wallpaper: $file"; fail=1
    fi
  done < <(python3 -I -c 'import json,sys
for d in json.load(open(sys.argv[1])):
    print(d["file"], d["page"].split("/wiki/File:", 1)[1], d["w"], sep="\t")' "$credits")
  return "$fail"
}
# Perfis de monitor automaticos ao plugar/desplugar
setup_kanshi() {
  systemctl --user enable kanshi.service
  if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then systemctl --user restart kanshi.service; fi
}
setup_backup() {
  local dest="$HOME/.local/bin/backup-configs"
  mkdir -p "$HOME/.local/bin" "$HOME/Backups"
  if [[ -e "$dest" ]]; then log "Preservando script existente: $dest"; return 0; fi
  cat > "$dest" <<'BACKUP'
#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
stamp="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$HOME/Backups"
items=()
for item in .config/sway .config/swaylock .config/rofi .config/mako .config/waybar .config/kanshi .config/foot .config/alacritty .zshrc .gitconfig .ssh/config; do
  [[ -e "$HOME/$item" ]] && items+=("$item")
done
if (( ${#items[@]} == 0 )); then echo 'Nenhuma configuracao encontrada.'; exit 0; fi
tar -C "$HOME" -czf "$HOME/Backups/configs-$stamp.tar.gz" "${items[@]}"
echo "Backup criado: $HOME/Backups/configs-$stamp.tar.gz"
echo 'ATENCAO: copie o arquivo para armazenamento externo; backup local nao protege contra perda do disco.'
BACKUP
  chmod 700 "$dest"
  log "Backup manual disponivel: $dest"
}

log "Fedora $FEDORA_VERSION / $(uname -m) / perfil: $PROFILE / log: $LOG_FILE"
read -r -p "Instalar aplicativos, ferramentas e dotfiles do Sway (perfil $PROFILE)? [s/N] " answer
[[ "$answer" =~ ^[sS]$ ]] || exit 0
sudo -v
# Mantem o sudo ativo durante a instalacao (que pode passar do timeout do sudo)
while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
SUDO_KEEPALIVE=$!
trap 'kill "$SUDO_KEEPALIVE" 2>/dev/null || true' EXIT

step 'Atualizacao do sistema' sudo dnf upgrade --refresh -y
install_group 'Pre-requisitos' curl wget2-wget git ca-certificates flatpak dnf5-plugins
step 'Repositorio Flathub' setup_flathub
step 'Repositorios RPM Fusion' setup_rpmfusion
step 'FFmpeg completo (RPM Fusion)' setup_ffmpeg
step 'Repositorio Chrome' setup_chrome_repo
step 'Repositorio VS Code' setup_vscode_repo
# Baixa os metadados dos repositorios recem-adicionados antes de instalar deles
step 'Atualizar cache do dnf' sudo dnf makecache --refresh

# Fedora 45 nao tem mais java-21; 25 e o LTS atual.
install_group 'Aplicativos' \
  google-chrome-stable code java-25-openjdk-devel maven \
  wdisplays easyeffects nautilus gvfs gvfs-mtp \
  rofi btop vlc solaar \
  pavucontrol blueman bluez network-manager-applet nm-connection-editor

# MEGAsync: o pacote do RPM Fusion nao puxa estes modulos QML e crasha (SIGSEGV) sem eles.
install_group 'MEGAsync' \
  qt5-qtgraphicaleffects qt5-qtquickcontrols qt5-qtquickcontrols2 megasync

install_group 'Wayland e Sway' \
  sway swaybg swaylock swayidle waybar foot mako kanshi lxqt-policykit \
  xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
  wl-clipboard cliphist grim slurp grimshot brightnessctl playerctl

install_group 'Desenvolvimento' \
  python3 python3-pip pipx git-lfs gcc gcc-c++ make cmake \
  openssl-devel pkgconf-pkg-config jq yq ripgrep fd-find \
  ShellCheck direnv zoxide fzf tmux tree fastfetch \
  unzip 7zip zsh

install_group 'Fontes e PDF' \
  jetbrains-mono-fonts google-noto-sans-mono-fonts google-noto-emoji-fonts fontawesome-fonts-all \
  zathura zathura-pdf-mupdf

install_group 'Backup' restic borgbackup
step 'Script local de backup' setup_backup

# Um unico formato para LibreOffice: Flatpak. Spotify e Zotero tambem via Flathub.
for app in com.spotify.Client org.zotero.Zotero org.libreoffice.LibreOffice; do
  step "Flatpak / $app" install_flatpak "$app"
done

step 'Dotfiles: clonar/atualizar i3Files' setup_dotfiles_repo
step 'Dotfiles: aplicar sway/waybar/mako/kanshi' apply_dotfiles
step 'rofi-power-menu' setup_rofi_power_menu
step 'Wallpapers (Wikimedia Commons)' setup_wallpapers
if [[ "$PROFILE" == notebook ]]; then step 'kanshi (servico do usuario)' setup_kanshi; fi
if [[ -n "${SWAYSOCK:-}" ]]; then step 'Recarregar sway' swaymsg reload; fi

log 'Verificacoes finais'
for cmd in java javac code google-chrome-stable wdisplays easyeffects nautilus megasync rofi rofi-power-menu \
           btop vlc solaar zsh zathura sway waybar mako kanshi cliphist grimshot swaybg swaylock pavucontrol blueman-manager; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf 'OK      %s\n' "$cmd"
  else
    printf 'AUSENTE %s\n' "$cmd"
  fi
done
printf '\nSucessos: %s | Falhas: %s\n' "${#SUCCESS[@]}" "${#FAILED[@]}"
if (( ${#FAILED[@]} )); then
  printf 'Falhas encontradas:\n'
  printf ' - %s\n' "${FAILED[@]}"
fi
printf '\nLog completo: %s\n' "$LOG_FILE"
printf 'Shell Zsh instalada, mas NAO alterada automaticamente. Para tornar padrao: chsh -s "$(command -v zsh || echo /usr/bin/zsh)"\n'
if [[ "$PROFILE" == desktop ]]; then
  printf 'Desktop: confira os nomes dos monitores com "swaymsg -t get_outputs" (esperado DP-1 e HDMI-A-1).\n'
fi
printf 'Faca logout/login no Sway para ativar portais, cliphist e megasync.\n'
if (( ${#FAILED[@]} )); then exit 1; fi
