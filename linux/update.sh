#!/bin/bash
# ============================================================
#   ÁNYK – NAV  |  Update  |  Linux
# ============================================================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

clear
echo -e "${CYAN}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║     ÁNYK – NAV  •  Frissítés – Linux     ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

ok()  { echo -e "  ${GREEN}✓${NC} $1"; }
warn(){ echo -e "  ${YELLOW}⚠${NC}  $1"; }
err() { echo -e "  ${RED}✗${NC} $1"; }

DOWNLOAD_URL="https://nav.gov.hu/pfile/programFile?path=/nyomtatvanyok/letoltesek/nyomtatvanykitolto_programok/nyomtatvany_apeh/keretprogramok/AbevJava"
JAR_FILE="/tmp/abevjava_install.jar"
CONFIG_FILE="$HOME/.abevjava/abevjavapath.cfg"
JAVA8_DIR="$HOME/.local/share/zulu-jdk8"

[ ! -f "$CONFIG_FILE" ] && { err "Az ÁNYK nincs telepítve. Futtasd az install.sh-t."; read -rp "  ENTER..."; exit 1; }
INSTALL_DIR=$(grep "abevjava.path" "$CONFIG_FILE" | sed 's/abevjava\.path *= *//')
[ -f "$JAVA8_DIR/bin/java" ] && JAVA8_BIN="$JAVA8_DIR/bin/java" || JAVA8_BIN=$(which java 2>/dev/null)
[ -z "$JAVA8_BIN" ] && { err "Java 8 nem található. Futtasd az install.sh-t."; exit 1; }

sudo -v || exit 1
( while true; do sudo -n true; sleep 50; done ) &
SKPID=$!; trap "kill $SKPID 2>/dev/null" EXIT

echo -e "\n${CYAN}${BOLD}  [1/4] Biztonsági mentés${NC}"
BACKUP="/tmp/anyk_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP"
for d in nyomtatvanyok nyomtatvanyok_archivum beallitasok mentesek; do
    [ -d "$INSTALL_DIR/$d" ] && cp -r "$INSTALL_DIR/$d" "$BACKUP/" 2>/dev/null
done; ok "Mentés: $BACKUP"

echo -e "\n${CYAN}${BOLD}  [2/4] Frissítés${NC}"
if [ -f "$INSTALL_DIR/abevjava_update" ]; then
    chmod +x "$INSTALL_DIR/abevjava_update"
    cd "$INSTALL_DIR" && JAVA_HOME="$(dirname $(dirname $JAVA8_BIN))" ./abevjava_update && ok "Beépített frissítő lefutott"
else
    warn "Beépített frissítő nem található – teljes letöltés..."
    curl -L --progress-bar -o "$JAR_FILE" "$DOWNLOAD_URL"
    echo -e "  ${YELLOW}Könyvtár: ${GREEN}$INSTALL_DIR${NC}"; read -rp "  ENTER..."
    JAVA_HOME="$(dirname $(dirname $JAVA8_BIN))" "$JAVA8_BIN" -jar "$JAR_FILE"
    rm -f "$JAR_FILE"
fi

echo -e "\n${CYAN}${BOLD}  [3/4] Adatok visszaállítása${NC}"
for d in nyomtatvanyok nyomtatvanyok_archivum beallitasok mentesek; do
    [ -d "$BACKUP/$d" ] && cp -r "$BACKUP/$d" "$INSTALL_DIR/" 2>/dev/null
done; rm -rf "$BACKUP"; ok "Adatok visszaállítva"

echo -e "\n${CYAN}${BOLD}  [4/4] setenv újraalkalmazása${NC}"
JAVA8_HOME_DIR="$(dirname $JAVA8_BIN)"
grep -v "JAVA_HOME_ABEV" "$INSTALL_DIR/setenv" > /tmp/sc 2>/dev/null && mv /tmp/sc "$INSTALL_DIR/setenv"
echo "JAVA_HOME_ABEV=\"$JAVA8_HOME_DIR/\"" >> "$INSTALL_DIR/setenv"
chmod +x "$INSTALL_DIR/abevjava_start" 2>/dev/null || true; ok "setenv javítva"

echo ""
echo -e "${GREEN}${BOLD}  ✓ Frissítés kész!${NC}"
echo ""
read -rp "  Nyomj ENTER-t a bezáráshoz..."
