#!/bin/bash
# ============================================================
#   ÁNYK - NAV Uninstaller for macOS
# ============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

clear
echo -e "${CYAN}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║     ÁNYK – NAV Eltávolító – macOS        ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

CONFIG_FILE="$HOME/.abevjava/abevjavapath.cfg"

# Read install path
if [ -f "$CONFIG_FILE" ]; then
    INSTALL_DIR=$(grep "abevjava.path" "$CONFIG_FILE" | sed 's/abevjava\.path *= *//')
else
    INSTALL_DIR="$HOME/abevjava"
fi

echo -e "  ${YELLOW}Ez eltávolítja az ÁNYK szoftvert a gépedről.${NC}"
echo -e "  Telepítési könyvtár: ${BOLD}$INSTALL_DIR${NC}"
echo -e "  Config könyvtár:     ${BOLD}$HOME/.abevjava${NC}"
echo -e "  Asztali indító:      ${BOLD}~/Desktop/ÁNYK - NAV.command${NC}"
echo ""
echo -e "  ${RED}${BOLD}A nyomtatványok és mentések is törlődnek!${NC}"
echo ""
read -rp "  Biztosan folytatod? (igen/nem): " CONFIRM
if [[ "$CONFIRM" != "igen" ]]; then
    echo "  Megszakítva."
    read -rp "  Nyomj ENTER-t a kilépéshez..." ; exit 0
fi

echo ""
echo -e "${CYAN}${BOLD}Eltávolítás...${NC}"

# Remove install directory
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo -e "  ${GREEN}✓${NC} $INSTALL_DIR törölve"
else
    echo -e "  ${YELLOW}⚠${NC}  $INSTALL_DIR nem található"
fi

# Remove config directory
if [ -d "$HOME/.abevjava" ]; then
    rm -rf "$HOME/.abevjava"
    echo -e "  ${GREEN}✓${NC} ~/.abevjava törölve"
fi

# Remove desktop launcher
for LAUNCHER in "$HOME/Desktop/ÁNYK - NAV.command" "$HOME/Desktop/AbevJava.command"; do
    if [ -f "$LAUNCHER" ]; then
        rm -f "$LAUNCHER"
        echo -e "  ${GREEN}✓${NC} Asztali indító törölve: $(basename "$LAUNCHER")"
    fi
done

# Ask about Java 8
echo ""
read -rp "  Eltávolítsuk a Java 8 (Zulu) -t is? (igen/nem): " REMOVEJAVA
if [[ "$REMOVEJAVA" == "igen" ]]; then
    if command -v brew &>/dev/null; then
        brew uninstall --cask zulu@8 2>/dev/null && \
        echo -e "  ${GREEN}✓${NC} Zulu JDK 8 eltávolítva" || \
        echo -e "  ${YELLOW}⚠${NC}  Zulu JDK 8 nem volt telepítve Homebrew-val"
    fi
fi

echo ""
echo -e "${GREEN}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║       ÁNYK sikeresen eltávolítva!        ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"
read -rp "  Nyomj ENTER-t a bezáráshoz..."
