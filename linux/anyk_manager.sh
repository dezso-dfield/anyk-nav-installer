#!/bin/bash
# ============================================================
#   ÁNYK – NAV Manager  |  Linux
#   zenity GUI (GTK) with terminal fallback
#   Dispatches to sub-scripts in the same directory
# ============================================================
DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$HOME/.abevjava/abevjavapath.cfg"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

HAS_ZENITY=false
command -v zenity &>/dev/null && HAS_ZENITY=true

is_installed() { [ -f "$CONFIG_FILE" ] && [ -d "$(get_dir)" ]; }
get_dir()      { [ -f "$CONFIG_FILE" ] && grep "abevjava.path" "$CONFIG_FILE" | sed 's/abevjava\.path *= *//' || echo "$HOME/abevjava"; }
get_status()   { is_installed && echo "✓ Telepítve: $(get_dir)" || echo "✗ Nincs telepítve"; }

do_launch() {
    if ! is_installed; then
        $HAS_ZENITY && zenity --error --title="ÁNYK – NAV" --text="Az ÁNYK nincs telepítve!\nFuttasd a Telepítést." 2>/dev/null \
            || echo -e "  ${RED}Az ÁNYK nincs telepítve!${NC}"
        return
    fi
    cd "$(get_dir)" && ./abevjava_start
}

show_menu() {
    local STATUS
    STATUS=$(get_status)
    if $HAS_ZENITY; then
        zenity --list \
            --title="ÁNYK – NAV Manager" \
            --text="<b>ÁNYK – NAV Manager</b>\n\nÁllapot: $STATUS\n\nVálassz műveletet:" \
            --column="Művelet" --column="Leírás" \
            --width=500 --height=320 \
            "Telepítés"   "Letöltés és telepítés a NAV szerveréről" \
            "Frissítés"   "ÁNYK frissítése a legújabb verzióra" \
            "Eltávolítás" "ÁNYK teljes eltávolítása a gépről" \
            "Indítás"     "ÁNYK elindítása" \
            2>/dev/null
    else
        clear
        echo -e "${CYAN}${BOLD}"
        echo "  ╔══════════════════════════════════════════╗"
        echo "  ║      ÁNYK – NAV Manager – Linux          ║"
        echo "  ╠══════════════════════════════════════════╣"
        printf "  ║  %-44s║\n" "$STATUS"
        echo "  ╠══════════════════════════════════════════╣"
        echo "  ║  1.  Telepítés                           ║"
        echo "  ║  2.  Frissítés                           ║"
        echo "  ║  3.  Eltávolítás                         ║"
        echo "  ║  4.  Indítás                             ║"
        echo "  ║  5.  Kilépés                             ║"
        echo "  ╚══════════════════════════════════════════╝"
        echo -e "${NC}"
        read -rp "  Választás (1-5): " OPT
        case "$OPT" in
            1) echo "Telepítés" ;; 2) echo "Frissítés" ;;
            3) echo "Eltávolítás" ;; 4) echo "Indítás" ;;
            *) echo "Kilépés" ;;
        esac
    fi
}

while true; do
    CHOICE=$(show_menu)
    case "$CHOICE" in
        "Telepítés")   bash "$DIR/install.sh" ;;
        "Frissítés")   bash "$DIR/update.sh" ;;
        "Eltávolítás") bash "$DIR/uninstall.sh" ;;
        "Indítás")     do_launch ;;
        "Kilépés"|"")  break ;;
    esac
done
