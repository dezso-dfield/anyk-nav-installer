#!/bin/bash
# ============================================================
#   ÁNYK – NAV Manager  |  macOS
#   Native AppleScript GUI — dispatches to sub-scripts
# ============================================================
DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$HOME/.abevjava/abevjavapath.cfg"

is_installed() { [ -f "$CONFIG_FILE" ] && [ -d "$(get_dir)" ]; }
get_dir()      { [ -f "$CONFIG_FILE" ] && grep "abevjava.path" "$CONFIG_FILE" | sed 's/abevjava\.path *= *//' || echo "$HOME/abevjava"; }
get_status()   { is_installed && echo "✓ Telepítve: $(get_dir)" || echo "✗ Nincs telepítve"; }

do_launch() {
    is_installed || { osascript -e 'display alert "Az ÁNYK nincs telepítve!" message "Futtasd a Telepítést." as critical'; return; }
    cd "$(get_dir)" && ./abevjava_start
}

while true; do
    STATUS=$(get_status)
    CHOICE=$(osascript <<EOF
tell application "System Events"
    activate
    set d to display dialog "ÁNYK – NAV Manager

Állapot: ${STATUS}

Válassz műveletet:" ¬
        buttons {"Kilépés", "Eltávolítás", "Frissítés", "Indítás", "Telepítés"} ¬
        default button (do shell script "[ -f '$CONFIG_FILE' ] && echo 'Indítás' || echo 'Telepítés'") ¬
        with title "ÁNYK – NAV Manager" ¬
        with icon note
    return button returned of d
end tell
EOF
    )
    case "$CHOICE" in
        "Telepítés")   bash "$DIR/install.command" ;;
        "Frissítés")   bash "$DIR/update.command" ;;
        "Eltávolítás") bash "$DIR/uninstall.command" ;;
        "Indítás")     do_launch ;;
        "Kilépés"|"")  break ;;
    esac
done
