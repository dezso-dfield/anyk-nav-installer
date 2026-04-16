#!/bin/bash
# ============================================================
#   ÁNYK - NAV One-Click Installer for Linux
#   Supports: Ubuntu/Debian, Fedora/RHEL, Arch, and others
#   via Azul Zulu JDK 8 direct download
# ============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

clear
echo -e "${CYAN}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║     ÁNYK – NAV Telepítő – Linux          ║"
echo "  ║   Automatikus telepítő – minden lépés     ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

DOWNLOAD_URL="https://nav.gov.hu/pfile/programFile?path=/nyomtatvanyok/letoltesek/nyomtatvanykitolto_programok/nyomtatvany_apeh/keretprogramok/AbevJava"
JAR_FILE="/tmp/abevjava_install.jar"
CONFIG_FILE="$HOME/.abevjava/abevjavapath.cfg"
ZULU_URL="https://cdn.azul.com/zulu/bin/zulu8.92.0.21-ca-jdk8.0.482-linux_x64.tar.gz"
ZULU_ARM_URL="https://cdn.azul.com/zulu/bin/zulu8.92.0.21-ca-jdk8.0.482-linux_aarch64.tar.gz"
JAVA8_DIR="$HOME/.local/share/zulu-jdk8"

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC}  $1"; }
err()  { echo -e "  ${RED}✗${NC} $1"; }
step() { echo -e "\n${CYAN}${BOLD}[$1/6] $2${NC}"; }

# ── Step 0: sudo upfront ─────────────────────────────────
step 0 "Rendszergazdai jogosultság kérése"
echo "  A telepítőnek egyszer szükséges a jelszavad."
sudo -v
if [ $? -ne 0 ]; then err "Jelszó sikertelen."; read -rp "  ENTER..." ; exit 1; fi
ok "Jogosultság megadva"
( while true; do sudo -n true; sleep 50; done ) &
SUDO_KEEPALIVE_PID=$!
trap "kill $SUDO_KEEPALIVE_PID 2>/dev/null" EXIT

# ── Step 1: Dependencies ─────────────────────────────────
step 1 "Szükséges eszközök ellenőrzése"
for cmd in curl tar; do
    if ! command -v $cmd &>/dev/null; then
        warn "$cmd hiányzik – telepítés..."
        if command -v apt-get &>/dev/null; then sudo apt-get install -y $cmd
        elif command -v dnf &>/dev/null;     then sudo dnf install -y $cmd
        elif command -v pacman &>/dev/null;  then sudo pacman -S --noconfirm $cmd
        fi
    fi
done
ok "Eszközök elérhetők"

# ── Step 2: Java 8 ───────────────────────────────────────
step 2 "Java 8 (Zulu) telepítése"

JAVA8_BIN=""

# Check if Java 8 already available system-wide
if java -version 2>&1 | grep -q '"1\.8\.'; then
    JAVA8_BIN=$(which java)
    ok "Java 8 már elérhető: $JAVA8_BIN"
elif [ -f "$JAVA8_DIR/bin/java" ]; then
    JAVA8_BIN="$JAVA8_DIR/bin/java"
    ok "Java 8 (Zulu) már telepítve: $JAVA8_BIN"
else
    # Detect architecture
    ARCH=$(uname -m)
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        DL_URL="$ZULU_ARM_URL"
        echo "  ARM64 architektúra észlelve"
    else
        DL_URL="$ZULU_URL"
        echo "  x86_64 architektúra észlelve"
    fi

    echo "  Java 8 letöltése..."
    mkdir -p "$JAVA8_DIR"
    curl -L --progress-bar -o /tmp/zulu8.tar.gz "$DL_URL"
    tar -xzf /tmp/zulu8.tar.gz -C "$JAVA8_DIR" --strip-components=1
    rm -f /tmp/zulu8.tar.gz
    JAVA8_BIN="$JAVA8_DIR/bin/java"
    ok "Java 8 telepítve: $JAVA8_BIN"
fi

# ── Step 3: Download ÁNYK ────────────────────────────────
step 3 "ÁNYK letöltése a NAV szerveréről"
curl -L --progress-bar -o "$JAR_FILE" "$DOWNLOAD_URL"
if [ $? -ne 0 ]; then err "Letöltés sikertelen."; read -rp "  ENTER..."; exit 1; fi
ok "Letöltés kész"

# ── Step 4: Run Installer ────────────────────────────────
step 4 "ÁNYK telepítő futtatása"
echo ""
echo -e "  ${YELLOW}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${BOLD}FONTOS: A megnyíló ablakban a Könyvtár mezőbe${NC}"
echo -e "  ${BOLD}írd be:  ${GREEN}$HOME/abevjava${NC}"
echo -e "  ${BOLD}Majd kattints a 'Tovább' gombra, végül 'Befejez'.${NC}"
echo -e "  ${YELLOW}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
read -rp "  Nyomj ENTER-t a telepítő megnyitásához..."
JAVA_HOME="$(dirname $(dirname $JAVA8_BIN))" "$JAVA8_BIN" -jar "$JAR_FILE"

# ── Step 5: Fix setenv ───────────────────────────────────
step 5 "Konfiguráció automatikus javítása"
if [ -f "$CONFIG_FILE" ]; then
    INSTALL_DIR=$(grep "abevjava.path" "$CONFIG_FILE" | sed 's/abevjava\.path *= *//')
    ok "Telepítési könyvtár: $INSTALL_DIR"
else
    warn "Config nem található, alapértelmezett: $HOME/abevjava"
    INSTALL_DIR="$HOME/abevjava"
fi

JAVA8_HOME_DIR="$(dirname $JAVA8_BIN)"
if [ -f "$INSTALL_DIR/setenv" ]; then
    grep -v "JAVA_HOME_ABEV" "$INSTALL_DIR/setenv" > /tmp/setenv_clean && mv /tmp/setenv_clean "$INSTALL_DIR/setenv"
    echo "JAVA_HOME_ABEV=\"$JAVA8_HOME_DIR/\"" >> "$INSTALL_DIR/setenv"
    ok "setenv javítva – Java 8 beállítva"
fi
chmod +x "$INSTALL_DIR/abevjava_start" 2>/dev/null || true

# ── Step 6: Desktop entry + Launcher ─────────────────────
step 6 "Asztali parancsikon létrehozása"

# Create launcher script
LAUNCHER_SCRIPT="$HOME/.local/bin/anyk-nav"
mkdir -p "$HOME/.local/bin"
cat > "$LAUNCHER_SCRIPT" << LAUNCHEOF
#!/bin/bash
cd "${INSTALL_DIR}"
./abevjava_start
LAUNCHEOF
chmod +x "$LAUNCHER_SCRIPT"

# Create .desktop entry
DESKTOP_DIR="$HOME/.local/share/applications"
mkdir -p "$DESKTOP_DIR"
cat > "$DESKTOP_DIR/anyk-nav.desktop" << DESKTOPEOF
[Desktop Entry]
Version=1.0
Type=Application
Name=ÁNYK - NAV
Comment=Magyar adónyomtatvány kitöltő (Hivatalos NAV szoftver)
Exec=bash -c "cd ${INSTALL_DIR} && ./abevjava_start"
Icon=${INSTALL_DIR}/abevjava.png
Terminal=true
Categories=Office;Finance;
StartupNotify=true
DESKTOPEOF

update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
ok "Asztali parancsikon: ÁNYK - NAV"

rm -f "$JAR_FILE"

echo ""
echo -e "${GREEN}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║        Telepítés sikeresen kész!         ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  ${BOLD}ÁNYK indítása:${NC}"
echo -e "  ${GREEN}1.${NC} Alkalmazások menüből: ÁNYK - NAV"
echo -e "  ${GREEN}2.${NC} Terminálból: cd ~/abevjava && ./abevjava_start"
echo ""
read -rp "  Nyomj ENTER-t a bezáráshoz..."
