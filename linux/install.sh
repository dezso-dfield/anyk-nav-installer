#!/bin/bash
# ============================================================
#   ÁNYK – NAV  |  Install  |  Linux (x86_64 + ARM64)
# ============================================================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

clear
echo -e "${CYAN}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║     ÁNYK – NAV  •  Telepítés – Linux     ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

DOWNLOAD_URL="https://nav.gov.hu/pfile/programFile?path=/nyomtatvanyok/letoltesek/nyomtatvanykitolto_programok/nyomtatvany_apeh/keretprogramok/AbevJava"
JAR_FILE="/tmp/abevjava_install.jar"
CONFIG_FILE="$HOME/.abevjava/abevjavapath.cfg"
JAVA8_DIR="$HOME/.local/share/zulu-jdk8"
ZULU_URL="https://cdn.azul.com/zulu/bin/zulu8.92.0.21-ca-jdk8.0.482-linux_x64.tar.gz"
ZULU_ARM_URL="https://cdn.azul.com/zulu/bin/zulu8.92.0.21-ca-jdk8.0.482-linux_aarch64.tar.gz"

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC}  $1"; }
err()  { echo -e "  ${RED}✗${NC} $1"; }

sudo -v || { err "sudo sikertelen."; exit 1; }
( while true; do sudo -n true; sleep 50; done ) &
SKPID=$!; trap "kill $SKPID 2>/dev/null" EXIT

echo -e "\n${CYAN}${BOLD}  [1/5] Eszközök${NC}"
for cmd in curl tar; do
    command -v $cmd &>/dev/null || {
        command -v apt-get &>/dev/null && sudo apt-get install -y $cmd
        command -v dnf     &>/dev/null && sudo dnf install -y $cmd
        command -v pacman  &>/dev/null && sudo pacman -S --noconfirm $cmd
    }
done; ok "curl, tar elérhető"

echo -e "\n${CYAN}${BOLD}  [2/5] Java 8 (Azul Zulu)${NC}"
JAVA8_BIN=""
if java -version 2>&1 | grep -q '"1\.8\.'; then
    JAVA8_BIN=$(which java); ok "Java 8 már elérhető: $JAVA8_BIN"
elif [ -f "$JAVA8_DIR/bin/java" ]; then
    JAVA8_BIN="$JAVA8_DIR/bin/java"; ok "Zulu JDK 8 már telepítve"
else
    [ "$(uname -m)" = "aarch64" ] && DL_URL="$ZULU_ARM_URL" || DL_URL="$ZULU_URL"
    mkdir -p "$JAVA8_DIR"
    curl -L --progress-bar -o /tmp/zulu8.tar.gz "$DL_URL"
    tar -xzf /tmp/zulu8.tar.gz -C "$JAVA8_DIR" --strip-components=1
    rm -f /tmp/zulu8.tar.gz
    JAVA8_BIN="$JAVA8_DIR/bin/java"
    ok "Zulu JDK 8 telepítve: $JAVA8_BIN"
fi
[ -z "$JAVA8_BIN" ] && { err "Java 8 telepítése sikertelen"; exit 1; }

echo -e "\n${CYAN}${BOLD}  [3/5] ÁNYK letöltése${NC}"
curl -L --progress-bar -o "$JAR_FILE" "$DOWNLOAD_URL" || { err "Letöltés sikertelen"; exit 1; }
ok "Letöltve"

echo -e "\n${CYAN}${BOLD}  [4/5] Telepítő${NC}"
echo ""
echo -e "  ${YELLOW}${BOLD}Könyvtár mezőbe add meg: ${GREEN}$HOME/abevjava${NC}"
read -rp "  ENTER a megnyitáshoz..."
JAVA_HOME="$(dirname $(dirname $JAVA8_BIN))" "$JAVA8_BIN" -jar "$JAR_FILE"
rm -f "$JAR_FILE"

echo -e "\n${CYAN}${BOLD}  [5/5] Konfiguráció${NC}"
[ -f "$CONFIG_FILE" ] && INSTALL_DIR=$(grep "abevjava.path" "$CONFIG_FILE" | sed 's/abevjava\.path *= *//') || INSTALL_DIR="$HOME/abevjava"
ok "Telepítési könyvtár: $INSTALL_DIR"
JAVA8_HOME_DIR="$(dirname $JAVA8_BIN)"
if [ -f "$INSTALL_DIR/setenv" ]; then
    grep -v "JAVA_HOME_ABEV" "$INSTALL_DIR/setenv" > /tmp/sc && mv /tmp/sc "$INSTALL_DIR/setenv"
    echo "JAVA_HOME_ABEV=\"$JAVA8_HOME_DIR/\"" >> "$INSTALL_DIR/setenv"
    ok "setenv javítva"
fi
chmod +x "$INSTALL_DIR/abevjava_start" 2>/dev/null || true

mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/anyk-nav.desktop" << DEOF
[Desktop Entry]
Version=1.0
Type=Application
Name=ÁNYK - NAV
Comment=Magyar adónyomtatvány kitöltő (Hivatalos NAV szoftver)
Exec=bash -c "cd ${INSTALL_DIR} && ./abevjava_start"
Icon=${INSTALL_DIR}/abevjava.png
Terminal=true
Categories=Office;Finance;
DEOF
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
ok "Asztali parancsikon: ÁNYK - NAV"

echo ""
echo -e "${GREEN}${BOLD}  ✓ Telepítés kész! Indítás: Alkalmazások → ÁNYK - NAV${NC}"
echo ""
read -rp "  Nyomj ENTER-t a bezáráshoz..."
