#!/bin/bash
# ============================================================
#   ÁNYK - NAV Manager for Linux
#   GUI via zenity (GTK) — falls back to terminal menu
#   Install / Update / Uninstall / Launch
# ============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

DOWNLOAD_URL="https://nav.gov.hu/pfile/programFile?path=/nyomtatvanyok/letoltesek/nyomtatvanykitolto_programok/nyomtatvany_apeh/keretprogramok/AbevJava"
CONFIG_FILE="$HOME/.abevjava/abevjavapath.cfg"
JAR_FILE="/tmp/abevjava_install.jar"
JAVA8_DIR="$HOME/.local/share/zulu-jdk8"
ZULU_URL="https://cdn.azul.com/zulu/bin/zulu8.92.0.21-ca-jdk8.0.482-linux_x64.tar.gz"
ZULU_ARM_URL="https://cdn.azul.com/zulu/bin/zulu8.92.0.21-ca-jdk8.0.482-linux_aarch64.tar.gz"

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC}  $1"; }
err()  { echo -e "  ${RED}✗${NC} $1"; }

HAS_ZENITY=false
command -v zenity &>/dev/null && HAS_ZENITY=true

is_installed() { [ -f "$CONFIG_FILE" ] && [ -d "$(get_install_dir)" ]; }
get_install_dir() {
    [ -f "$CONFIG_FILE" ] && grep "abevjava.path" "$CONFIG_FILE" | sed 's/abevjava\.path *= *//' || echo "$HOME/abevjava"
}
get_java8() {
    if [ -f "$JAVA8_DIR/bin/java" ]; then echo "$JAVA8_DIR/bin/java"
    elif java -version 2>&1 | grep -q '"1\.8\.'; then which java
    else echo ""
    fi
}

# ── GUI helpers ───────────────────────────────────────────
notify() {
    if $HAS_ZENITY; then
        zenity --notification --text="$1" 2>/dev/null
    else
        echo -e "  ${GREEN}ℹ${NC} $1"
    fi
}

confirm() {
    if $HAS_ZENITY; then
        zenity --question --title="ÁNYK – NAV" --text="$1" --width=360 2>/dev/null
        return $?
    else
        read -rp "  $1 (igen/nem): " R
        [[ "$R" == "igen" ]]
    fi
}

show_info() {
    if $HAS_ZENITY; then
        zenity --info --title="ÁNYK – NAV" --text="$1" --width=360 2>/dev/null
    else
        echo -e "\n  ${CYAN}$1${NC}\n"
        read -rp "  ENTER..."
    fi
}

show_menu() {
    local STATUS
    is_installed && STATUS="Telepítve: $(get_install_dir)" || STATUS="Nincs telepítve"

    if $HAS_ZENITY; then
        CHOICE=$(zenity --list \
            --title="ÁNYK – NAV Manager" \
            --text="<b>ÁNYK – NAV Manager</b>\n\nÁllapot: $STATUS\n\nVálassz műveletet:" \
            --column="Művelet" --column="Leírás" \
            --width=480 --height=340 \
            "Telepítés"   "Letöltés és telepítés a NAV szerveréről" \
            "Frissítés"   "ÁNYK frissítése a legújabb verzióra" \
            "Eltávolítás" "ÁNYK eltávolítása a gépről" \
            "Indítás"     "ÁNYK elindítása" \
            2>/dev/null)
        echo "$CHOICE"
    else
        # Terminal menu fallback
        clear
        echo -e "${CYAN}${BOLD}"
        echo "  ╔══════════════════════════════════════════╗"
        echo "  ║        ÁNYK – NAV Manager – Linux        ║"
        echo "  ╠══════════════════════════════════════════╣"
        printf "  ║  Állapot: %-32s║\n" "$STATUS"
        echo "  ╠══════════════════════════════════════════╣"
        echo "  ║  1. Telepítés                            ║"
        echo "  ║  2. Frissítés                            ║"
        echo "  ║  3. Eltávolítás                          ║"
        echo "  ║  4. Indítás                              ║"
        echo "  ║  5. Kilépés                              ║"
        echo "  ╚══════════════════════════════════════════╝"
        echo -e "${NC}"
        read -rp "  Választás (1-5): " OPT
        case "$OPT" in
            1) echo "Telepítés" ;;
            2) echo "Frissítés" ;;
            3) echo "Eltávolítás" ;;
            4) echo "Indítás" ;;
            5) echo "Kilépés" ;;
            *) echo "" ;;
        esac
    fi
}

# ── INSTALL ──────────────────────────────────────────────
do_install() {
    clear; echo -e "${CYAN}${BOLD}  ÁNYK – Telepítés${NC}\n"

    sudo -v || { err "sudo sikertelen."; return; }
    ( while true; do sudo -n true; sleep 50; done ) &
    SKPID=$!; trap "kill $SKPID 2>/dev/null" RETURN

    # Dependencies
    for cmd in curl tar; do
        command -v $cmd &>/dev/null || {
            command -v apt-get &>/dev/null && sudo apt-get install -y $cmd
            command -v dnf     &>/dev/null && sudo dnf install -y $cmd
            command -v pacman  &>/dev/null && sudo pacman -S --noconfirm $cmd
        }
    done

    # Java 8
    echo -e "\n  ${CYAN}Java 8 ellenőrzése...${NC}"
    if [ -z "$(get_java8)" ]; then
        [ "$(uname -m)" = "aarch64" ] && DL_URL="$ZULU_ARM_URL" || DL_URL="$ZULU_URL"
        mkdir -p "$JAVA8_DIR"
        curl -L --progress-bar -o /tmp/zulu8.tar.gz "$DL_URL"
        tar -xzf /tmp/zulu8.tar.gz -C "$JAVA8_DIR" --strip-components=1
        rm -f /tmp/zulu8.tar.gz
    fi
    JAVA8_BIN=$(get_java8)
    [ -n "$JAVA8_BIN" ] && ok "Java 8: $JAVA8_BIN" || { err "Java 8 telepítése sikertelen"; return; }

    # Download
    echo -e "\n  ${CYAN}ÁNYK letöltése...${NC}"
    curl -L --progress-bar -o "$JAR_FILE" "$DOWNLOAD_URL" || { err "Letöltés sikertelen"; return; }

    # Run installer
    show_info "A telepítő megnyílik.\n\nKönyvtár mezőbe add meg:\n$HOME/abevjava"
    JAVA_HOME="$(dirname $(dirname $JAVA8_BIN))" "$JAVA8_BIN" -jar "$JAR_FILE"
    rm -f "$JAR_FILE"

    # Fix setenv
    local IDIR=$(get_install_dir)
    local JAVA8_HOME_DIR="$(dirname $JAVA8_BIN)"
    if [ -f "$IDIR/setenv" ]; then
        grep -v "JAVA_HOME_ABEV" "$IDIR/setenv" > /tmp/sc && mv /tmp/sc "$IDIR/setenv"
        echo "JAVA_HOME_ABEV=\"$JAVA8_HOME_DIR/\"" >> "$IDIR/setenv"
    fi
    chmod +x "$IDIR/abevjava_start" 2>/dev/null || true

    # Desktop entry
    mkdir -p "$HOME/.local/share/applications"
    cat > "$HOME/.local/share/applications/anyk-nav.desktop" << DEOF
[Desktop Entry]
Version=1.0
Type=Application
Name=ÁNYK - NAV
Comment=Magyar adónyomtatvány kitöltő (Hivatalos NAV szoftver)
Exec=bash -c "cd ${IDIR} && ./abevjava_start"
Icon=${IDIR}/abevjava.png
Terminal=true
Categories=Office;Finance;
DEOF
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    ok "Asztali parancsikon létrehozva"

    notify "Az ÁNYK sikeresen telepítve!"
    show_info "Telepítés kész!\n\nIndítás: Alkalmazások → ÁNYK - NAV"
}

# ── UPDATE ───────────────────────────────────────────────
do_update() {
    clear; echo -e "${CYAN}${BOLD}  ÁNYK – Frissítés${NC}\n"
    is_installed || { show_info "Az ÁNYK nincs telepítve!"; return; }

    local IDIR=$(get_install_dir)
    local JAVA8_BIN=$(get_java8)
    [ -z "$JAVA8_BIN" ] && { show_info "Java 8 nem található!"; return; }

    sudo -v || return
    ( while true; do sudo -n true; sleep 50; done ) &
    SKPID=$!; trap "kill $SKPID 2>/dev/null" RETURN

    local BACKUP="/tmp/anyk_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP"
    for d in nyomtatvanyok nyomtatvanyok_archivum beallitasok mentesek; do
        [ -d "$IDIR/$d" ] && cp -r "$IDIR/$d" "$BACKUP/"
    done
    ok "Biztonsági mentés: $BACKUP"

    if [ -f "$IDIR/abevjava_update" ]; then
        chmod +x "$IDIR/abevjava_update"
        cd "$IDIR" && JAVA_HOME="$(dirname $(dirname $JAVA8_BIN))" ./abevjava_update
    else
        curl -L --progress-bar -o "$JAR_FILE" "$DOWNLOAD_URL"
        show_info "Könyvtár: $IDIR"
        JAVA_HOME="$(dirname $(dirname $JAVA8_BIN))" "$JAVA8_BIN" -jar "$JAR_FILE"
        rm -f "$JAR_FILE"
    fi

    for d in nyomtatvanyok nyomtatvanyok_archivum beallitasok mentesek; do
        [ -d "$BACKUP/$d" ] && cp -r "$BACKUP/$d" "$IDIR/"
    done
    rm -rf "$BACKUP"

    local JAVA8_HOME_DIR="$(dirname $JAVA8_BIN)"
    grep -v "JAVA_HOME_ABEV" "$IDIR/setenv" > /tmp/sc 2>/dev/null && mv /tmp/sc "$IDIR/setenv"
    echo "JAVA_HOME_ABEV=\"$JAVA8_HOME_DIR/\"" >> "$IDIR/setenv"
    chmod +x "$IDIR/abevjava_start" 2>/dev/null || true

    notify "Az ÁNYK sikeresen frissítve!"
    show_info "Frissítés kész!"
}

# ── UNINSTALL ────────────────────────────────────────────
do_uninstall() {
    is_installed || { show_info "Az ÁNYK nincs telepítve!"; return; }
    local IDIR=$(get_install_dir)
    confirm "Biztosan eltávolítod az ÁNYK-t?\n\nKönyvtár: $IDIR\n\nA nyomtatványok is törlődnek!" || return

    [ -d "$IDIR" ]            && rm -rf "$IDIR"           && ok "Telepítési könyvtár törölve"
    [ -d "$HOME/.abevjava" ]  && rm -rf "$HOME/.abevjava" && ok "Config törölve"
    [ -f "$HOME/.local/share/applications/anyk-nav.desktop" ] && \
        rm -f "$HOME/.local/share/applications/anyk-nav.desktop" && ok ".desktop fájl törölve"
    [ -f "$HOME/.local/bin/anyk-nav" ] && rm -f "$HOME/.local/bin/anyk-nav"
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

    notify "Az ÁNYK sikeresen eltávolítva."
    show_info "Eltávolítás kész!"
}

# ── LAUNCH ───────────────────────────────────────────────
do_launch() {
    is_installed || { show_info "Az ÁNYK nincs telepítve!"; return; }
    local IDIR=$(get_install_dir)
    cd "$IDIR" && ./abevjava_start
}

# ── MAIN LOOP ────────────────────────────────────────────
while true; do
    CHOICE=$(show_menu)
    case "$CHOICE" in
        "Telepítés")   do_install ;;
        "Frissítés")   do_update ;;
        "Eltávolítás") do_uninstall ;;
        "Indítás")     do_launch ;;
        "Kilépés"|"")  break ;;
    esac
done
