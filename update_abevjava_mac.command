#!/bin/bash
# ============================================================
#   ÁNYK - NAV Updater for macOS
# ============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

clear
echo -e "${CYAN}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║     ÁNYK – NAV Frissítő – macOS          ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC}  $1"; }
err()  { echo -e "  ${RED}✗${NC} $1"; }
step() { echo -e "\n${CYAN}${BOLD}[$1/4] $2${NC}"; }

DOWNLOAD_URL="https://nav.gov.hu/pfile/programFile?path=/nyomtatvanyok/letoltesek/nyomtatvanykitolto_programok/nyomtatvany_apeh/keretprogramok/AbevJava"
JAR_FILE="/tmp/abevjava_install.jar"
CONFIG_FILE="$HOME/.abevjava/abevjavapath.cfg"

# Check installed
if [ ! -f "$CONFIG_FILE" ]; then
    err "Az ÁNYK nincs telepítve. Először futtasd az install_abevjava_mac.command szkriptet."
    read -rp "  ENTER..." ; exit 1
fi

INSTALL_DIR=$(grep "abevjava.path" "$CONFIG_FILE" | sed 's/abevjava\.path *= *//')
echo -e "  Jelenlegi telepítési könyvtár: ${BOLD}$INSTALL_DIR${NC}"

# sudo upfront
step 0 "Rendszergazdai jogosultság"
sudo -v || { err "Sikertelen."; read -rp "  ENTER..."; exit 1; }
ok "Jogosultság megadva"
( while true; do sudo -n true; sleep 50; done ) &
SUDO_KEEPALIVE_PID=$!
trap "kill $SUDO_KEEPALIVE_PID 2>/dev/null" EXIT

# Find Java 8
if /usr/libexec/java_home -v 1.8 &>/dev/null 2>&1; then
    JAVA8_HOME=$(/usr/libexec/java_home -v 1.8)
else
    err "Java 8 nem található. Futtasd az install_abevjava_mac.command szkriptet."
    read -rp "  ENTER..."; exit 1
fi

# Step 1: Backup forms
step 1 "Nyomtatványok biztonsági mentése"
BACKUP_DIR="/tmp/anyk_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
for dir in nyomtatvanyok nyomtatvanyok_archivum beallitasok mentesek; do
    [ -d "$INSTALL_DIR/$dir" ] && cp -r "$INSTALL_DIR/$dir" "$BACKUP_DIR/" 2>/dev/null
done
ok "Biztonsági mentés: $BACKUP_DIR"

# Step 2: Try built-in updater first
step 2 "Frissítés NAV szerveren keresztül"
if [ -f "$INSTALL_DIR/abevjava_update" ]; then
    echo "  Beépített frissítő futtatása..."
    chmod +x "$INSTALL_DIR/abevjava_update"
    cd "$INSTALL_DIR" && JAVA_HOME="$JAVA8_HOME" ./abevjava_update
    ok "Beépített frissítő lefutott"
else
    warn "Beépített frissítő nem található – teljes újratelepítés..."
    curl -L --progress-bar -o "$JAR_FILE" "$DOWNLOAD_URL"
    xattr -dr com.apple.quarantine "$JAR_FILE" 2>/dev/null || true
    echo ""
    echo -e "  ${YELLOW}${BOLD}A telepítő megnyílik. Könyvtárnak add meg: ${GREEN}$INSTALL_DIR${NC}"
    read -rp "  Nyomj ENTER-t..."
    JAVA_HOME="$JAVA8_HOME" "$JAVA8_HOME/bin/java" -jar "$JAR_FILE"
    rm -f "$JAR_FILE"
fi

# Step 3: Restore backup
step 3 "Adatok visszaállítása"
for dir in nyomtatvanyok nyomtatvanyok_archivum beallitasok mentesek; do
    [ -d "$BACKUP_DIR/$dir" ] && cp -r "$BACKUP_DIR/$dir" "$INSTALL_DIR/" 2>/dev/null
done
rm -rf "$BACKUP_DIR"
ok "Adatok visszaállítva"

# Step 4: Re-apply setenv fix
step 4 "Konfiguráció újraalkalmazása"
if [ -f "$INSTALL_DIR/setenv" ]; then
    grep -v "JAVA_HOME_ABEV" "$INSTALL_DIR/setenv" > /tmp/setenv_clean && mv /tmp/setenv_clean "$INSTALL_DIR/setenv"
    echo "JAVA_HOME_ABEV=\"$JAVA8_HOME/bin/\"" >> "$INSTALL_DIR/setenv"
    ok "setenv javítva"
fi
chmod +x "$INSTALL_DIR/abevjava_start" 2>/dev/null || true

echo ""
echo -e "${GREEN}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║        Frissítés sikeresen kész!         ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"
read -rp "  Nyomj ENTER-t a bezáráshoz..."
