#!/bin/bash
# ============================================================
#   ÁNYK – NAV  |  Uninstall  |  Linux
# ============================================================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

clear
echo -e "${CYAN}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║    ÁNYK – NAV  •  Eltávolítás – Linux    ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

CONFIG_FILE="$HOME/.abevjava/abevjavapath.cfg"
JAVA8_DIR="$HOME/.local/share/zulu-jdk8"
DESKTOP_FILE="$HOME/.local/share/applications/anyk-nav.desktop"
[ -f "$CONFIG_FILE" ] && INSTALL_DIR=$(grep "abevjava.path" "$CONFIG_FILE" | sed 's/abevjava\.path *= *//') || INSTALL_DIR="$HOME/abevjava"

echo -e "  ${YELLOW}Ez az ÁNYK teljes eltávolítását végzi.${NC}\n"
echo -e "  Könyvtár:  ${BOLD}$INSTALL_DIR${NC}"
echo -e "  Config:    ${BOLD}$HOME/.abevjava${NC}\n"
echo -e "  ${RED}${BOLD}Nyomtatványok és mentések is törlődnek!${NC}\n"
read -rp "  Biztosan folytatod? (igen/nem): " CONFIRM
[[ "$CONFIRM" != "igen" ]] && { echo "  Megszakítva."; read -rp "  ENTER..."; exit 0; }

echo ""
[ -d "$INSTALL_DIR" ]    && rm -rf "$INSTALL_DIR"    && echo -e "  ${GREEN}✓${NC} $INSTALL_DIR törölve"
[ -d "$HOME/.abevjava" ] && rm -rf "$HOME/.abevjava" && echo -e "  ${GREEN}✓${NC} Config törölve"
[ -f "$DESKTOP_FILE" ]   && rm -f "$DESKTOP_FILE"   && echo -e "  ${GREEN}✓${NC} .desktop fájl törölve"
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

echo ""
read -rp "  Eltávolítsuk a Zulu JDK 8-at is ($JAVA8_DIR)? (igen/nem): " RJ
[[ "$RJ" == "igen" ]] && [ -d "$JAVA8_DIR" ] && rm -rf "$JAVA8_DIR" && echo -e "  ${GREEN}✓${NC} Zulu JDK 8 törölve"

echo ""
echo -e "${GREEN}${BOLD}  ✓ Az ÁNYK sikeresen eltávolítva.${NC}"
echo ""
read -rp "  Nyomj ENTER-t a bezáráshoz..."
