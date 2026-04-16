#!/bin/bash
# ============================================================
#   ÁNYK - NAV Updater for Linux
# ============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

clear
echo -e "${CYAN}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║     ÁNYK – NAV Frissítő – Linux          ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC}  $1"; }
err()  { echo -e "  ${RED}✗${NC} $1"; }

DOWNLOAD_URL="https://nav.gov.hu/pfile/programFile?path=/nyomtatvanyok/letoltesek/nyomtatvanykitolto_programok/nyomtatvany_apeh/keretprogramok/AbevJava"
JAR_FILE="/tmp/abevjava_install.jar"
CONFIG_FILE="$HOME/.abevjava/abevjavapath.cfg"
JAVA8_DIR="$HOME/.local/share/zulu-jdk8"

if [ ! -f "$CONFIG_FILE" ]; then
    err "Az ÁNYK nincs telepítve. Futtasd az install_abevjava_linux.sh szkriptet."
    read -rp "  ENTER..." ; exit 1
fi

INSTALL_DIR=$(grep "abevjava.path" "$CONFIG_FILE" | sed 's/abevjava\.path *= *//')
echo -e "  Jelenlegi telepítési könyvtár: ${BOLD}$INSTALL_DIR${NC}"

# Find Java 8
if [ -f "$JAVA8_DIR/bin/java" ]; then
    JAVA8_BIN="$JAVA8_DIR/bin/java"
elif java -version 2>&1 | grep -q '"1\.8\.'; then
    JAVA8_BIN=$(which java)
else
    err "Java 8 nem található. Futtasd az install_abevjava_linux.sh szkriptet."
    read -rp "  ENTER..."; exit 1
fi

sudo -v || { err "sudo sikertelen."; exit 1; }
( while true; do sudo -n true; sleep 50; done ) &
KEEPALIVE=$!
trap "kill $KEEPALIVE 2>/dev/null" EXIT

# Backup
echo -e "\n${CYAN}${BOLD}[1/4] Nyomtatványok biztonsági mentése${NC}"
BACKUP="/tmp/anyk_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP"
for dir in nyomtatvanyok nyomtatvanyok_archivum beallitasok mentesek; do
    [ -d "$INSTALL_DIR/$dir" ] && cp -r "$INSTALL_DIR/$dir" "$BACKUP/" 2>/dev/null
done
ok "Biztonsági mentés: $BACKUP"

# Update
echo -e "\n${CYAN}${BOLD}[2/4] Frissítés${NC}"
if [ -f "$INSTALL_DIR/abevjava_update" ]; then
    chmod +x "$INSTALL_DIR/abevjava_update"
    cd "$INSTALL_DIR" && JAVA_HOME="$(dirname $(dirname $JAVA8_BIN))" ./abevjava_update
    ok "Beépített frissítő lefutott"
else
    warn "Beépített frissítő nem található – teljes újratelepítés..."
    curl -L --progress-bar -o "$JAR_FILE" "$DOWNLOAD_URL"
    echo -e "  ${YELLOW}Könyvtárnak add meg: ${GREEN}$INSTALL_DIR${NC}"
    read -rp "  Nyomj ENTER-t..."
    JAVA_HOME="$(dirname $(dirname $JAVA8_BIN))" "$JAVA8_BIN" -jar "$JAR_FILE"
    rm -f "$JAR_FILE"
fi

# Restore
echo -e "\n${CYAN}${BOLD}[3/4] Adatok visszaállítása${NC}"
for dir in nyomtatvanyok nyomtatvanyok_archivum beallitasok mentesek; do
    [ -d "$BACKUP/$dir" ] && cp -r "$BACKUP/$dir" "$INSTALL_DIR/" 2>/dev/null
done
rm -rf "$BACKUP"
ok "Adatok visszaállítva"

# Re-apply fix
echo -e "\n${CYAN}${BOLD}[4/4] Konfiguráció újraalkalmazása${NC}"
JAVA8_HOME_DIR="$(dirname $JAVA8_BIN)"
if [ -f "$INSTALL_DIR/setenv" ]; then
    grep -v "JAVA_HOME_ABEV" "$INSTALL_DIR/setenv" > /tmp/setenv_clean && mv /tmp/setenv_clean "$INSTALL_DIR/setenv"
    echo "JAVA_HOME_ABEV=\"$JAVA8_HOME_DIR/\"" >> "$INSTALL_DIR/setenv"
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
