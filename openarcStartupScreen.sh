#!/bin/bash
# OpenArc DietPi Login-Banner
#
# Main parts:
# - Lädt DietPi Globals + Version (wenn vorhanden)
# - Ermittelt Systeminfos (IP, Uptime, Temp, RAM, Disk, Load)
# - Prüft Update-Flags (/run/dietpi/*) und zeigt Status/Datum
# - Rendert OpenArc ASCII-Banner + Kurzinfos/Kommandos

# Wichtig: Diese Datei MUSS Unix-LF haben (kein CRLF), sonst kommt: "cannot execute: required file not found"
# Fix: sed -i 's/\r$//' /boot/dietpi/func/dietpi-banner

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

# DietPi-Globals (optional)
if [ -r /boot/dietpi/func/dietpi-globals ]; then
  . /boot/dietpi/func/dietpi-globals
fi

# DietPi-Version (optional)
if [ -r /boot/dietpi/.version ]; then
  . /boot/dietpi/.version
fi

COLOUR_RESET='\e[0m'
GREEN_SEPARATOR="${RED}:$COLOUR_RESET"
GREEN_LINE=" ${GREEN}─────────────────────────────────────────────────────$COLOUR_RESET"

# Locale (einmal sauber aus dietpi.txt holen)
LOCALE="$(sed -n '/^[[:blank:]]*AUTO_SETUP_LOCALE=/{s/^[^=]*=//p;q}' /boot/dietpi.txt 2>/dev/null | tr -d '\r')"
[ -n "$LOCALE" ] || LOCALE="C.UTF-8"

# DietPi Version string (fallback)
if [ -n "${G_DIETPI_VERSION_CORE:-}" ] && [ -n "${G_DIETPI_VERSION_SUB:-}" ] && [ -n "${G_DIETPI_VERSION_RC:-}" ]; then
  DIETPI_VERSION="${G_DIETPI_VERSION_CORE}.${G_DIETPI_VERSION_SUB}.${G_DIETPI_VERSION_RC}"
else
  DIETPI_VERSION="unknown"
fi

# Systeminfos (robust, ohne Login zu killen)
HOSTNAME="$(hostname 2>/dev/null || echo "unknown")"
IP="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
[ -n "$IP" ] || IP="n/a"

if [ -r /sys/class/thermal/thermal_zone0/temp ]; then
  CPU_TEMP="$(awk '{printf "%.1f°C", $1/1000}' /sys/class/thermal/thermal_zone0/temp 2>/dev/null)"
else
  CPU_TEMP="n/a"
fi

LOAD="$(uptime 2>/dev/null | awk -F'load average: ' '{print $2}' || true)"
[ -n "$LOAD" ] || LOAD="n/a"

UPTIME="$(uptime -p 2>/dev/null || echo "n/a")"

# RAM/Disk: nur awk, kein mawk-hardcoding
RAM="$(free -b 2>/dev/null | awk 'NR==2 {printf "%.0f of %.0f MiB (%.0f%%)", $3/1024^2, $2/1024^2, ($3/$2*100)}' || true)"
[ -n "$RAM" ] || RAM="n/a"

DISK="$(df -h --output=used,size,pcent / 2>/dev/null | awk 'NR==2 {print $1" of "$2" ("$3")"}' || true)"
[ -n "$DISK" ] || DISK="n/a"

# Update-Checks (DietPi flags)
AVAILABLE_UPDATE=""
Check_DietPi_Update() {
  [ -f /run/dietpi/.update_available ] || return 1
  read -r AVAILABLE_UPDATE < /run/dietpi/.update_available
  return 0
}

LIVE_PATCHES=0
Check_DietPi_Live_Patches() {
  [ -f /run/dietpi/.live_patches ] || return 1
  LIVE_PATCHES=1
  return 0
}

PACKAGE_COUNT=0
Check_APT_Updates() {
  [ -f /run/dietpi/.apt_updates ] || return 1
  read -r PACKAGE_COUNT < /run/dietpi/.apt_updates
  return 0
}

REBOOT_REQUIRED=0
Check_Reboot() {
  # G_CHECK_KERNEL kommt aus dietpi-globals. Wenn nicht vorhanden: kein Reboot-Check.
  command -v G_CHECK_KERNEL >/dev/null 2>&1 || return 1
  G_CHECK_KERNEL && return 1
  REBOOT_REQUIRED=1
  return 0
}

Print_Header() {
  if Check_DietPi_Update; then
    echo -e "${GREEN}v${DIETPI_VERSION}${COLOUR_RESET} ${GREEN}(Update available)${COLOUR_RESET}"
  elif Check_DietPi_Live_Patches; then
    echo -e "${GREEN}v${DIETPI_VERSION}${COLOUR_RESET} ${GREEN}(New live patches available)${COLOUR_RESET}"
  elif Check_APT_Updates; then
    echo -e "${GREEN}v${DIETPI_VERSION}${COLOUR_RESET} ${GREEN}(${PACKAGE_COUNT} APT updates available)${COLOUR_RESET}"
  elif Check_Reboot; then
    echo -e "${GREEN}v${DIETPI_VERSION}${COLOUR_RESET} ${GREEN}(Reboot required)${COLOUR_RESET}"
  else
    echo -e "${GREEN}v${DIETPI_VERSION}${COLOUR_RESET}"
  fi
}

Print_Date() {
  LC_ALL="$LOCALE" date '+%R - %a %x' 2>/dev/null
}

Print_Software() {
  if [ -x /boot/dietpi/dietpi-software ]; then
    /boot/dietpi/dietpi-software list 2>/dev/null | awk -F'|' '/=2/ {split($3,a,":"); gsub(/^[ \t]+/,"",a[1]); printf "%s, ", a[1]}'
  fi
}

VPN_Status() {
  if [ -x /boot/dietpi/dietpi-vpn ]; then
    /boot/dietpi/dietpi-vpn status 2>&1
  else
    echo "n/a"
  fi
}

# Fallback wenn DietPi Globals nicht geladen wurden
GREEN_BULLET="${GREEN_BULLET:-*}"

# OpenArc-Banner
echo -e "${PURPLE}  _____                   ___           "
echo -e "${PURPLE} |  _  |                 / _ \\          "
echo -e "${PURPLE} | | | |_ __   ___ _ __ / /_\\ \\_ __ ___ "
echo -e "${PURPLE} | | | | '_ \\ / _ \\ '_ \\|  _  | '__/ __|"
echo -e "${PURPLE} \\ \\_/ / |_) |  __/ | | | | | | | | (__ "
echo -e "${PURPLE}  \\___/| .__/ \\___|_| |_|_| |_/_|  \\___|"
echo -e "${PURPLE}       | |                              "
echo -e "${PURPLE}       |_|                              "
echo -e "${PURPLE} #############################################"
echo -e ""
echo -e "${CYAN}  Welcome to ${YELLOW}OpenArcOS${CYAN} – The Open Source Architecture Platform${NC}"
echo -e ""

echo -e "${YELLOW}  $(Print_Date)"
echo -e ""
echo -e "${GREEN}  🛠️  Version:${NC}        1.0.0"
echo -e "${GREEN}  🧠  Based on:${NC}      DietPi (GPLv2) $(Print_Header)"
echo -e "${GREEN}  🔌  Modules:${NC}       EVCC, $(Print_Software)"
echo -e "${GREEN}  🌐  Web UI:${NC}        http://eHiveOne.local/"
echo -e ""

echo -e "${YELLOW}  📊 Systemstatus:${NC}"
echo -e "    🔹 Hostname:   $HOSTNAME"
echo -e "    🔹 Uptime:     $UPTIME"
echo -e "    🔹 IP Address: $IP"
echo -e "    🔹 CPU Temp:   $CPU_TEMP"
echo -e "    🔹 RAM Usage:  $RAM"
echo -e "    🔹 Disk Usage: $DISK"
echo -e ""

echo -e "$GREEN_BULLET ${GREEN}VPN Status $GREEN_SEPARATOR $(VPN_Status)"
echo -e ""
echo -e " ${GREEN}dietpi-launcher${COLOUR_RESET} ${GREEN_SEPARATOR} All the DietPi programs in one place"
echo -e " ${GREEN}dietpi-config${COLOUR_RESET}   ${GREEN_SEPARATOR} Feature rich configuration tool for your device"
echo -e " ${GREEN}dietpi-software${COLOUR_RESET} ${GREEN_SEPARATOR} Select optimised software for installation"
echo -e " ${GREEN}htop${COLOUR_RESET}            ${GREEN_SEPARATOR} Resource monitor"
echo -e " ${GREEN}cpu${COLOUR_RESET}             ${GREEN_SEPARATOR} Shows CPU information and stats"
