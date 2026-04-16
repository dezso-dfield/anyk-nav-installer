#!/bin/bash
# ============================================================
#   ÁNYK - NAV One-Click Installer for macOS
#   Supports: Apple Silicon (M1/M2/M3/M4) + Intel
# ============================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

clear
echo -e "${CYAN}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║     ÁNYK – NAV Telepítő – macOS          ║"
echo "  ║   Automatikus telepítő – minden lépés     ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

DOWNLOAD_URL="https://nav.gov.hu/pfile/programFile?path=/nyomtatvanyok/letoltesek/nyomtatvanykitolto_programok/nyomtatvany_apeh/keretprogramok/AbevJava"
JAR_FILE="/tmp/abevjava_install.jar"
CONFIG_FILE="$HOME/.abevjava/abevjavapath.cfg"

# ── Helper ────────────────────────────────────────────────
ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC}  $1"; }
err()  { echo -e "  ${RED}✗${NC} $1"; }
step() { echo -e "\n${CYAN}${BOLD}[$1/6] $2${NC}"; }

# ── Step 0: Request sudo upfront ─────────────────────────
step 0 "Rendszergazdai jogosultság kérése"
echo "  A telepítőnek egyszer szükséges a jelszavad."
echo "  Ezután nem kér többet a folyamat során."
echo ""
sudo -v
if [ $? -ne 0 ]; then
    err "Jelszó megadása sikertelen vagy megszakítva."
    read -rp "  Nyomj ENTER-t a kilépéshez..." ; exit 1
fi
ok "Jogosultság megadva"

# Keep sudo alive in background for the duration of the script
( while true; do sudo -n true; sleep 50; done ) &
SUDO_KEEPALIVE_PID=$!
trap "kill $SUDO_KEEPALIVE_PID 2>/dev/null" EXIT

# ── Step 1: Homebrew ─────────────────────────────────────
step 1 "Homebrew ellenőrzése (1/6)"

if ! command -v brew &>/dev/null; then
    # Try known paths first (faster than full install check)
    if   [ -f /opt/homebrew/bin/brew ];  then eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f /usr/local/bin/brew ];     then eval "$(/usr/local/bin/brew shellenv)"
    else
        echo "  Homebrew telepítése (jelszó szükséges lehet)..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        [ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
        [ -f /usr/local/bin/brew ]    && eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

if command -v brew &>/dev/null; then
    ok "Homebrew elérhető"
else
    err "Homebrew nem telepíthető. Látogass el: https://brew.sh"
    read -rp "  Nyomj ENTER-t a kilépéshez..." ; exit 1
fi

# ── Step 2: Java 8 ───────────────────────────────────────
step 2 "Java 8 (Zulu) ellenőrzése és telepítése (2/6)"

if /usr/libexec/java_home -v 1.8 &>/dev/null 2>&1; then
    JAVA8_HOME=$(/usr/libexec/java_home -v 1.8)
    ok "Java 8 már telepítve: $JAVA8_HOME"
else
    echo "  Java 8 telepítése (Azul Zulu – Apple Silicon kompatibilis)..."
    brew install --cask zulu@8
    if /usr/libexec/java_home -v 1.8 &>/dev/null 2>&1; then
        JAVA8_HOME=$(/usr/libexec/java_home -v 1.8)
        ok "Java 8 telepítve: $JAVA8_HOME"
    else
        err "Java 8 telepítése sikertelen"
        read -rp "  Nyomj ENTER-t a kilépéshez..." ; exit 1
    fi
fi

# ── Step 3: Download AbevJava ────────────────────────────
step 3 "ÁNYK letöltése a NAV szerveréről (3/6)"
echo "  URL: $DOWNLOAD_URL"
echo ""
curl -L --progress-bar -o "$JAR_FILE" "$DOWNLOAD_URL"
if [ $? -ne 0 ]; then
    err "Letöltés sikertelen. Ellenőrizd az internet kapcsolatot."
    read -rp "  Nyomj ENTER-t a kilépéshez..." ; exit 1
fi
xattr -dr com.apple.quarantine "$JAR_FILE" 2>/dev/null || true
ok "Letöltés kész: $JAR_FILE"

# ── Step 4: Run Installer ────────────────────────────────
step 4 "ÁNYK telepítő futtatása (4/6)"
echo ""
echo -e "  ${YELLOW}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${BOLD}FONTOS: A megnyíló ablakban a Könyvtár mezőbe${NC}"
echo -e "  ${BOLD}írd be:  ${GREEN}$HOME/abevjava${NC}"
echo -e "  ${BOLD}Majd kattints a 'Tovább' gombra, végül 'Befejez'.${NC}"
echo -e "  ${YELLOW}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
read -rp "  Nyomj ENTER-t a telepítő megnyitásához..."

JAVA_HOME="$JAVA8_HOME" "$JAVA8_HOME/bin/java" -jar "$JAR_FILE"

echo ""
echo "  Várakozás a telepítés befejezésére..."

# ── Step 5: Auto-fix + Launcher ──────────────────────────
step 5 "Konfiguráció automatikus javítása (5/6)"

# Read actual install path from config
if [ -f "$CONFIG_FILE" ]; then
    INSTALL_DIR=$(grep "abevjava.path" "$CONFIG_FILE" | sed 's/abevjava\.path *= *//')
    ok "Telepítési könyvtár megtalálva: $INSTALL_DIR"
else
    warn "Config fájl nem található, alapértelmezett könyvtár: $HOME/abevjava"
    INSTALL_DIR="$HOME/abevjava"
fi

# Fix setenv: set JAVA_HOME_ABEV to Java 8
if [ -f "$INSTALL_DIR/setenv" ]; then
    # Remove old entries and add correct one
    grep -v "JAVA_HOME_ABEV" "$INSTALL_DIR/setenv" > /tmp/setenv_clean && \
    mv /tmp/setenv_clean "$INSTALL_DIR/setenv"
    echo "JAVA_HOME_ABEV=\"$JAVA8_HOME/bin/\"" >> "$INSTALL_DIR/setenv"
    ok "setenv javítva – Java 8 beállítva"
else
    warn "setenv nem található a $INSTALL_DIR könyvtárban"
    warn "Telepítési hiba lehetséges. Ellenőrizd a könyvtárat."
fi

# Make start script executable
chmod +x "$INSTALL_DIR/abevjava_start" 2>/dev/null || true

# ── Step 6: Create Desktop Launcher ─────────────────────
step 6 "Asztali indító létrehozása (6/6)"

LAUNCHER="$HOME/Desktop/ÁNYK - NAV.command"
cat > "$LAUNCHER" << LAUNCHEOF
#!/bin/bash
cd "${INSTALL_DIR}"
./abevjava_start
LAUNCHEOF
chmod +x "$LAUNCHER"
xattr -dr com.apple.quarantine "$LAUNCHER" 2>/dev/null || true
ok "Asztali indító létrehozva: ~/Desktop/ÁNYK - NAV.command"

# Remove temp installer
rm -f "$JAR_FILE"

# ── Done ─────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║        Telepítés sikeresen kész!         ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "  ${BOLD}ÁNYK – NAV indítása:${NC}"
echo -e "  ${GREEN}1.${NC} Duplaklikk az 'ÁNYK - NAV.command' ikonra az asztalon"
echo -e "  ${GREEN}2.${NC} Vagy terminálból: cd ~/abevjava && ./abevjava_start"
echo ""
read -rp "  Nyomj ENTER-t a bezáráshoz..."
