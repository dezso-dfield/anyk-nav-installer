#!/bin/bash
# ============================================================
#   ÁNYK – NAV  |  Install  |  macOS (Apple Silicon + Intel)
# ============================================================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

clear
echo -e "${CYAN}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║     ÁNYK – NAV  •  Telepítés – macOS     ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

DOWNLOAD_URL="https://nav.gov.hu/pfile/programFile?path=/nyomtatvanyok/letoltesek/nyomtatvanykitolto_programok/nyomtatvany_apeh/keretprogramok/AbevJava"
JAR_FILE="/tmp/abevjava_install.jar"
CONFIG_FILE="$HOME/.abevjava/abevjavapath.cfg"

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC}  $1"; }
err()  { echo -e "  ${RED}✗${NC} $1"; }
step() { echo -e "\n${CYAN}${BOLD}[$1/6] $2${NC}"; }

# ── sudo upfront ─────────────────────────────────────────
step 0 "Rendszergazdai jogosultság"
echo "  Egyszer kérjük a jelszavadat – ezután nem kérdezi újra."
sudo -v || { err "Sikertelen."; read -rp "  ENTER..."; exit 1; }
ok "Jogosultság megadva"
( while true; do sudo -n true; sleep 50; done ) &
SKPID=$!; trap "kill $SKPID 2>/dev/null" EXIT

# ── Homebrew ─────────────────────────────────────────────
step 1 "Homebrew"
if ! command -v brew &>/dev/null; then
    [ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
    [ -f /usr/local/bin/brew ]    && eval "$(/usr/local/bin/brew shellenv)"
    if ! command -v brew &>/dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        [ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
        [ -f /usr/local/bin/brew ]    && eval "$(/usr/local/bin/brew shellenv)"
    fi
fi
command -v brew &>/dev/null && ok "Homebrew elérhető" || { err "Homebrew nem telepíthető → https://brew.sh"; read -rp "  ENTER..."; exit 1; }

# ── Java 8 ───────────────────────────────────────────────
step 2 "Java 8 (Azul Zulu – Apple Silicon kompatibilis)"
if ! /usr/libexec/java_home -v 1.8 &>/dev/null 2>&1; then
    brew install --cask zulu@8
fi
JAVA8_HOME=$(/usr/libexec/java_home -v 1.8 2>/dev/null)
[ -n "$JAVA8_HOME" ] && ok "Java 8: $JAVA8_HOME" || { err "Java 8 telepítése sikertelen"; read -rp "  ENTER..."; exit 1; }

# ── Download ─────────────────────────────────────────────
step 3 "ÁNYK letöltése a NAV szerveréről"
curl -L --progress-bar -o "$JAR_FILE" "$DOWNLOAD_URL" || { err "Letöltés sikertelen"; read -rp "  ENTER..."; exit 1; }
xattr -dr com.apple.quarantine "$JAR_FILE" 2>/dev/null || true
ok "Letöltve: $JAR_FILE"

# ── Run installer ────────────────────────────────────────
step 4 "ÁNYK telepítő futtatása"
echo ""
echo -e "  ${YELLOW}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${BOLD}A megnyíló ablakban a Könyvtár mezőbe add meg:${NC}"
echo -e "  ${GREEN}${BOLD}  $HOME/abevjava${NC}"
echo -e "  ${BOLD}Majd: Tovább → Befejez${NC}"
echo -e "  ${YELLOW}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
read -rp "  Nyomj ENTER-t a telepítő megnyitásához..."
JAVA_HOME="$JAVA8_HOME" "$JAVA8_HOME/bin/java" -jar "$JAR_FILE"
rm -f "$JAR_FILE"

# ── Fix setenv ───────────────────────────────────────────
step 5 "Konfiguráció javítása (Java 8 path)"
[ -f "$CONFIG_FILE" ] && INSTALL_DIR=$(grep "abevjava.path" "$CONFIG_FILE" | sed 's/abevjava\.path *= *//') || INSTALL_DIR="$HOME/abevjava"
ok "Telepítési könyvtár: $INSTALL_DIR"
if [ -f "$INSTALL_DIR/setenv" ]; then
    grep -v "JAVA_HOME_ABEV" "$INSTALL_DIR/setenv" > /tmp/sc && mv /tmp/sc "$INSTALL_DIR/setenv"
    echo "JAVA_HOME_ABEV=\"$JAVA8_HOME/bin/\"" >> "$INSTALL_DIR/setenv"
    ok "setenv javítva"
fi
chmod +x "$INSTALL_DIR/abevjava_start" 2>/dev/null || true

# ── Desktop launcher ─────────────────────────────────────
step 6 "Asztali indító"
LAUNCHER="$HOME/Desktop/ÁNYK - NAV.command"
printf '#!/bin/bash\ncd "%s"\n./abevjava_start\n' "$INSTALL_DIR" > "$LAUNCHER"
chmod +x "$LAUNCHER"; xattr -dr com.apple.quarantine "$LAUNCHER" 2>/dev/null || true
ok "Létrehozva: ~/Desktop/ÁNYK - NAV.command"

echo ""
echo -e "${GREEN}${BOLD}  ✓ Telepítés kész! Indítás: duplaklikk az 'ÁNYK - NAV.command' ikonra.${NC}"
echo ""
read -rp "  Nyomj ENTER-t a bezáráshoz..."
