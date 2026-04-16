#!/bin/bash
# ============================================================
#   ÁNYK - NAV Uninstaller for Linux
# ============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

clear
echo -e "${CYAN}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║     ÁNYK – NAV Eltávolító – Linux        ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

CONFIG_FILE="$HOME/.abevjava/abevjavapath.cfg"
JAVA8_DIR="$HOME/.local/share/zulu-jdk8"
DESKTOP_FILE="$HOME/.local/share/applications/anyk-nav.desktop"
LAUNCHER_SCRIPT="$HOME/.local/bin/anyk-nav"

if [ -f "$CONFIG_FILE" ]; then
    INSTALL_DIR=$(grep "abevjava.path" "$CONFIG_FILE" | sed 's/abevjava\.path *= *//')
else
    INSTALL_DIR="$HOME/abevjava"
fi

echo -e "  ${YELLOW}Ez eltávolítja az ÁNYK szoftvert a gépedről.${NC}"
echo -e "  Telepítési könyvtár: ${BOLD}$INSTALL_DIR${NC}"
echo -e "  Config könyvtár:     ${BOLD}$HOME/.abevjava${NC}"
echo -e "  Asztali parancsikon: ${BOLD}$DESKTOP_FILE${NC}"
echo ""
echo -e "  ${RED}${BOLD}A nyomtatványok és mentések is törlődnek!${NC}"
echo ""
read -rp "  Biztosan folytatod? (igen/nem): " CONFIRM
if [[ "$CONFIRM" != "igen" ]]; then
    echo "  Megszakítva."
    read -rp "  Nyomj ENTER-t..." ; exit 0
fi

echo ""
echo -e "${CYAN}${BOLD}Eltávolítás...${NC}"

[ -d "$INSTALL_DIR" ]   && rm -rf "$INSTALL_DIR"   && echo -e "  ${GREEN}✓${NC} $INSTALL_DIR törölve"
[ -d "$HOME/.abevjava" ] && rm -rf "$HOME/.abevjava" && echo -e "  ${GREEN}✓${NC} ~/.abevjava törölve"
[ -f "$DESKTOP_FILE" ]  && rm -f "$DESKTOP_FILE"   && echo -e "  ${GREEN}✓${NC} .desktop fájl törölve"
[ -f "$LAUNCHER_SCRIPT" ] && rm -f "$LAUNCHER_SCRIPT" && echo -e "  ${GREEN}✓${NC} Indítószkript törölve"

update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

echo ""
read -rp "  Eltávolítsuk a Zulu JDK 8-at is ($JAVA8_DIR)? (igen/nem): " REMOVEJAVA
if [[ "$REMOVEJAVA" == "igen" ]] && [ -d "$JAVA8_DIR" ]; then
    rm -rf "$JAVA8_DIR"
    echo -e "  ${GREEN}✓${NC} Zulu JDK 8 törölve"
fi

echo ""
echo -e "${GREEN}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║       ÁNYK sikeresen eltávolítva!        ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"
read -rp "  Nyomj ENTER-t a bezáráshoz..."
