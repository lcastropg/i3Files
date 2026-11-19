#!/usr/bin/env bash
# Troca o wallpaper do sway a cada WALLPAPER_INTERVAL segundos (padrão 900 = 15 min).
# Ordem aleatória, sem repetir até passar por todas. SIGUSR1 pula para a próxima.
DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers/landscapes}"
INTERVAL="${WALLPAPER_INTERVAL:-900}"
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/wallpaper-rotate.pid"

# Só uma instância (exec_always roda de novo a cada reload)
[[ -f $PIDFILE ]] && kill "$(<"$PIDFILE")" 2>/dev/null
echo $$ > "$PIDFILE"

sleep_pid=
trap '[[ -n $sleep_pid ]] && kill "$sleep_pid" 2>/dev/null' USR1
trap '[[ -n $sleep_pid ]] && kill "$sleep_pid" 2>/dev/null; exit 0' TERM INT

shopt -s nullglob nocaseglob
while :; do
  mapfile -t imgs < <(printf '%s\n' "$DIR"/*.{jpg,jpeg,png} | shuf)
  (( ${#imgs[@]} )) || exit 0          # pasta vazia: mantém o bg do config
  for img in "${imgs[@]}"; do
    swaymsg -q output '*' bg "$img" fill || exit 0   # sway saiu
    sleep "$INTERVAL" & sleep_pid=$!
    wait "$sleep_pid"
  done
done
