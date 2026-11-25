#!/usr/bin/env bash
# macOS "Auto" appearance: when the shell switches light/dark (sunrise/sunset),
# switch GTK 3/4 apps and the kitty terminal too.
#   mac-appearance.sh          watch and follow (started at login)
#   mac-appearance.sh apply    apply once for the current mode

apply() {
  local scheme mode
  scheme=$(gsettings get org.gnome.desktop.interface color-scheme)
  [[ "$scheme" == *dark* ]] && mode=Dark || mode=Light
  local FAMILY=MacTahoe
  local T="$HOME/.themes/$FAMILY-$mode" dark=$([[ $mode == Dark ]] && echo 1 || echo 0)

  [[ "$(gsettings get org.gnome.desktop.interface gtk-theme)" == "'$FAMILY-$mode'" ]] ||
    gsettings set org.gnome.desktop.interface gtk-theme "$FAMILY-$mode"

  # GTK4 / libadwaita apps read ~/.config/gtk-4.0/gtk.css 
  local g4="$T/gtk-4.0"; [[ -d "$g4/unpacked" ]] && g4="$g4/unpacked"
  local css="$g4/gtk.css"; [[ $mode == Dark ]] && css="$g4/gtk-dark.css"
  ln -sfn "$css" "$HOME/.config/gtk-4.0/gtk.css"
  ln -sfn "$css" "$HOME/.config/gtk-4.0/gtk-dark.css"
  ln -sfn "$g4/assets" "$HOME/.config/gtk-4.0/assets"

  for v in 3.0 4.0; do
    f="$HOME/.config/gtk-$v/settings.ini"
    [[ -f $f ]] && sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$FAMILY-$mode/; s/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=$dark/" "$f"
  done

  # Qt apps (Kvantum)
  [[ -d "$HOME/.config/Kvantum" ]] &&
    printf '[General]\ntheme=%s\n' "$([[ $mode == Dark ]] && echo WhiteSurDark || echo WhiteSur)" > "$HOME/.config/Kvantum/kvantum.kvconfig"

  # kitty: macos-current.conf points at the right palette, then live-reload
  local k="$HOME/.config/kitty"
  [[ $mode == Dark ]] && ln -sfn macos.conf "$k/macos-current.conf" || ln -sfn macos-light.conf "$k/macos-current.conf"
  pkill -USR1 -x kitty 2>/dev/null || true
}

if [[ "${1:-}" == "apply" ]]; then apply; exit 0; fi

# only one watcher at a time
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/mac-appearance.lock"
flock -n 9 || exit 0

apply
gsettings monitor org.gnome.desktop.interface color-scheme | while read -r _; do apply; done
