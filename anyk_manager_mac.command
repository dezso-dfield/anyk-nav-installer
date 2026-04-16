#!/bin/bash
# ============================================================
#   ÁNYK - NAV Manager for macOS
#   Native GUI via AppleScript — Install / Update / Uninstall / Launch
# ============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

DOWNLOAD_URL="https://nav.gov.hu/pfile/programFile?path=/nyomtatvanyok/letoltesek/nyomtatvanykitolto_programok/nyomtatvany_apeh/keretprogramok/AbevJava"
CONFIG_FILE="$HOME/.abevjava/abevjavapath.cfg"
JAR_FILE="/tmp/abevjava_install.jar"
ZULU_URL_ARM="https://cdn.azul.com/zulu/bin/zulu8.92.0.21-ca-jdk8.0.482-macosx_aarch64.dmg"
ZULU_URL_X64="https://cdn.azul.com/zulu/bin/zulu8.92.0.21-ca-jdk8.0.482-macosx_x86_64.dmg"

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC}  $1"; }
err()  { echo -e "  ${RED}✗${NC} $1"; }

# ── Detect install state ─────────────────────────────────
is_installed() { [ -f "$CONFIG_FILE" ] && [ -d "$(get_install_dir)" ]; }
get_install_dir() {
    if [ -f "$CONFIG_FILE" ]; then
        grep "abevjava.path" "$CONFIG_FILE" | sed 's/abevjava\.path *= *//'
    else
        echo "$HOME/abevjava"
    fi
}
get_java8() {
    /usr/libexec/java_home -v 1.8 2>/dev/null || echo ""
}

# ── Show native GUI dialog ────────────────────────────────
show_menu() {
    local INSTALLED_LABEL=""
    if is_installed; then
        INSTALLED_LABEL="Telepítve: $(get_install_dir)"
    else
        INSTALLED_LABEL="Nincs telepítve"
    fi

    CHOICE=$(osascript <<EOF
tell application "System Events"
    activate
    set dlg to display dialog "ÁNYK – NAV Manager\n\nÁllapot: ${INSTALLED_LABEL}\n\nMit szeretnél csinálni?" ¬
        buttons {"Kilépés", "Eltávolítás", "Frissítés", "Indítás", "Telepítés"} ¬
        default button "Telepítés" ¬
        with title "ÁNYK – NAV Manager" ¬
        with icon note
    return button returned of dlg
end tell
EOF
)
    echo "$CHOICE"
}

# ── INSTALL ──────────────────────────────────────────────
do_install() {
    clear
    echo -e "${CYAN}${BOLD}  ÁNYK – Telepítés${NC}\n"

    # sudo
    echo "  Jelszó kérése..."; sudo -v || { err "Sikertelen."; return; }
    ( while true; do sudo -n true; sleep 50; done ) &
    SKPID=$!; trap "kill $SKPID 2>/dev/null" RETURN

    # Homebrew
    echo -e "\n${CYAN}${BOLD}  [1/5] Homebrew${NC}"
    if ! command -v brew &>/dev/null; then
        [ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
        [ -f /usr/local/bin/brew ]    && eval "$(/usr/local/bin/brew shellenv)"
        if ! command -v brew &>/dev/null; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            [ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
    command -v brew &>/dev/null && ok "Homebrew elérhető" || { err "Homebrew telepítése sikertelen"; return; }

    # Java 8
    echo -e "\n${CYAN}${BOLD}  [2/5] Java 8${NC}"
    if ! /usr/libexec/java_home -v 1.8 &>/dev/null 2>&1; then
        brew install --cask zulu@8
    fi
    JAVA8_HOME=$(get_java8)
    [ -n "$JAVA8_HOME" ] && ok "Java 8: $JAVA8_HOME" || { err "Java 8 telepítése sikertelen"; return; }

    # Download
    echo -e "\n${CYAN}${BOLD}  [3/5] Letöltés${NC}"
    curl -L --progress-bar -o "$JAR_FILE" "$DOWNLOAD_URL"
    xattr -dr com.apple.quarantine "$JAR_FILE" 2>/dev/null || true
    ok "Letöltés kész"

    # Run installer
    echo -e "\n${CYAN}${BOLD}  [4/5] Telepítő${NC}"
    osascript -e "display notification \"A telepítő megnyílik. Könyvtár: $HOME/abevjava\" with title \"ÁNYK – NAV\""
    echo -e "  ${YELLOW}Könyvtár mezőbe írd: ${GREEN}$HOME/abevjava${NC}"
    read -rp "  ENTER a folytatáshoz..."
    JAVA_HOME="$JAVA8_HOME" "$JAVA8_HOME/bin/java" -jar "$JAR_FILE"
    rm -f "$JAR_FILE"

    # Fix setenv
    echo -e "\n${CYAN}${BOLD}  [5/5] Konfiguráció${NC}"
    local IDIR=$(get_install_dir)
    if [ -f "$IDIR/setenv" ]; then
        grep -v "JAVA_HOME_ABEV" "$IDIR/setenv" > /tmp/sc && mv /tmp/sc "$IDIR/setenv"
        echo "JAVA_HOME_ABEV=\"$JAVA8_HOME/bin/\"" >> "$IDIR/setenv"
        ok "setenv javítva"
    fi
    chmod +x "$IDIR/abevjava_start" 2>/dev/null || true

    # Desktop launcher
    local LAUNCHER="$HOME/Desktop/ÁNYK - NAV.command"
    printf '#!/bin/bash\ncd "%s"\n./abevjava_start\n' "$IDIR" > "$LAUNCHER"
    chmod +x "$LAUNCHER"
    xattr -dr com.apple.quarantine "$LAUNCHER" 2>/dev/null || true
    ok "Asztali indító létrehozva"

    osascript -e 'display notification "Az ÁNYK sikeresen telepítve!" with title "ÁNYK – NAV"'
    echo -e "\n  ${GREEN}${BOLD}Telepítés kész!${NC}"
    read -rp "  ENTER..."
}

# ── UPDATE ───────────────────────────────────────────────
do_update() {
    clear
    echo -e "${CYAN}${BOLD}  ÁNYK – Frissítés${NC}\n"
    if ! is_installed; then err "Nincs telepítve!"; read -rp "  ENTER..."; return; fi

    local IDIR=$(get_install_dir)
    local JAVA8_HOME=$(get_java8)
    [ -z "$JAVA8_HOME" ] && { err "Java 8 nem található!"; read -rp "  ENTER..."; return; }

    sudo -v || return
    ( while true; do sudo -n true; sleep 50; done ) &
    SKPID=$!; trap "kill $SKPID 2>/dev/null" RETURN

    # Backup
    echo -e "  ${CYAN}Biztonsági mentés...${NC}"
    local BACKUP="/tmp/anyk_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP"
    for d in nyomtatvanyok nyomtatvanyok_archivum beallitasok mentesek; do
        [ -d "$IDIR/$d" ] && cp -r "$IDIR/$d" "$BACKUP/"
    done
    ok "Mentés: $BACKUP"

    # Update
    if [ -f "$IDIR/abevjava_update" ]; then
        chmod +x "$IDIR/abevjava_update"
        cd "$IDIR" && JAVA_HOME="$JAVA8_HOME" ./abevjava_update
    else
        curl -L --progress-bar -o "$JAR_FILE" "$DOWNLOAD_URL"
        xattr -dr com.apple.quarantine "$JAR_FILE" 2>/dev/null || true
        echo -e "  ${YELLOW}Könyvtár: ${GREEN}$IDIR${NC}"; read -rp "  ENTER..."
        JAVA_HOME="$JAVA8_HOME" "$JAVA8_HOME/bin/java" -jar "$JAR_FILE"
        rm -f "$JAR_FILE"
    fi

    # Restore + re-fix
    for d in nyomtatvanyok nyomtatvanyok_archivum beallitasok mentesek; do
        [ -d "$BACKUP/$d" ] && cp -r "$BACKUP/$d" "$IDIR/"
    done
    rm -rf "$BACKUP"
    grep -v "JAVA_HOME_ABEV" "$IDIR/setenv" > /tmp/sc 2>/dev/null && mv /tmp/sc "$IDIR/setenv"
    echo "JAVA_HOME_ABEV=\"$JAVA8_HOME/bin/\"" >> "$IDIR/setenv"
    chmod +x "$IDIR/abevjava_start" 2>/dev/null || true

    osascript -e 'display notification "Az ÁNYK sikeresen frissítve!" with title "ÁNYK – NAV"'
    ok "Frissítés kész!"; read -rp "  ENTER..."
}

# ── UNINSTALL ────────────────────────────────────────────
do_uninstall() {
    clear
    echo -e "${CYAN}${BOLD}  ÁNYK – Eltávolítás${NC}\n"
    if ! is_installed; then warn "Nincs telepítve."; read -rp "  ENTER..."; return; fi

    local IDIR=$(get_install_dir)
    CONFIRM=$(osascript -e "display dialog \"Biztosan eltávolítod az ÁNYK-t?\n\nKönyvtár: $IDIR\n\nA nyomtatványok és mentések is törlődnek!\" buttons {\"Mégse\", \"Eltávolítás\"} default button \"Mégse\" with title \"ÁNYK – NAV Eltávolítás\" with icon caution")
    [[ "$CONFIRM" != *"Eltávolítás"* ]] && return

    [ -d "$IDIR" ]           && rm -rf "$IDIR"           && ok "$IDIR törölve"
    [ -d "$HOME/.abevjava" ] && rm -rf "$HOME/.abevjava" && ok "Config törölve"
    for L in "$HOME/Desktop/ÁNYK - NAV.command" "$HOME/Desktop/AbevJava.command"; do
        [ -f "$L" ] && rm -f "$L" && ok "Asztali indító törölve"
    done

    osascript -e 'display notification "Az ÁNYK sikeresen eltávolítva." with title "ÁNYK – NAV"'
    ok "Eltávolítás kész!"; read -rp "  ENTER..."
}

# ── LAUNCH ───────────────────────────────────────────────
do_launch() {
    if ! is_installed; then err "Nincs telepítve!"; read -rp "  ENTER..."; return; fi
    local IDIR=$(get_install_dir)
    cd "$IDIR" && ./abevjava_start
}

# ── MAIN LOOP ────────────────────────────────────────────
while true; do
    clear
    CHOICE=$(show_menu)
    case "$CHOICE" in
        "Telepítés")   do_install ;;
        "Frissítés")   do_update ;;
        "Eltávolítás") do_uninstall ;;
        "Indítás")     do_launch ;;
        "Kilépés"|"")  break ;;
    esac
done
