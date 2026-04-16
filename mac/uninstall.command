#!/bin/bash
# ============================================================
#   ÁNYK – NAV  |  Uninstall  |  macOS
# ============================================================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

clear
echo -e "${CYAN}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║    ÁNYK – NAV  •  Eltávolítás – macOS    ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

CONFIG_FILE="$HOME/.abevjava/abevjavapath.cfg"
[ -f "$CONFIG_FILE" ] && INSTALL_DIR=$(grep "abevjava.path" "$CONFIG_FILE" | sed 's/abevjava\.path *= *//') || INSTALL_DIR="$HOME/abevjava"

echo -e "  ${YELLOW}Ez az ÁNYK teljes eltávolítását végzi.${NC}\n"
echo -e "  Könyvtár:   ${BOLD}$INSTALL_DIR${NC}"
echo -e "  Config:     ${BOLD}$HOME/.abevjava${NC}"
echo -e "  Asztali:    ${BOLD}~/Desktop/ÁNYK - NAV.command${NC}\n"
echo -e "  ${RED}${BOLD}Nyomtatványok és mentések is törlődnek!${NC}\n"
read -rp "  Biztosan folytatod? (igen/nem): " CONFIRM
[[ "$CONFIRM" != "igen" ]] && { echo "  Megszakítva."; read -rp "  ENTER..."; exit 0; }

echo ""
[ -d "$INSTALL_DIR" ]    && rm -rf "$INSTALL_DIR"    && echo -e "  ${GREEN}✓${NC} $INSTALL_DIR törölve"
[ -d "$HOME/.abevjava" ] && rm -rf "$HOME/.abevjava" && echo -e "  ${GREEN}✓${NC} Config törölve"
for L in "$HOME/Desktop/ÁNYK - NAV.command" "$HOME/Desktop/AbevJava.command"; do
    [ -f "$L" ] && rm -f "$L" && echo -e "  ${GREEN}✓${NC} $(basename "$L") törölve"
done

echo ""
read -rp "  Eltávolítsuk a Zulu JDK 8-at is? (igen/nem): " RJ
[[ "$RJ" == "igen" ]] && command -v brew &>/dev/null && brew uninstall --cask zulu@8 2>/dev/null && echo -e "  ${GREEN}✓${NC} Zulu JDK 8 törölve"

echo ""
echo -e "${GREEN}${BOLD}  ✓ Az ÁNYK sikeresen eltávolítva.${NC}"
echo ""
read -rp "  Nyomj ENTER-t a bezáráshoz..."
