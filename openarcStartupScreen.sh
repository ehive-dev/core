#!/bin/bash

# Farben

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m' # Kein Farbcode

# Import DietPi-Globals --------------------------------------------------------------
. /boot/dietpi/func/dietpi-globals
. /boot/dietpi/.version

COLOUR_RESET='\e[0m'
GREEN_SEPARATOR="${RED}:$COLOUR_RESET"
GREEN_LINE=" ${GREEN}─────────────────────────────────────────────────────$COLOUR_RESET"
DIETPI_VERSION="$G_DIETPI_VERSION_CORE.$G_DIETPI_VERSION_SUB.$G_DIETPI_VERSION_RC"

# Systeminformationen
IP=$(hostname -I | awk '{print $1}')
CPU_TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{printf "%.1f°C", $1/1000}')
LOAD=$(uptime | awk -F'load average: ' '{ print $2 }')
RAM=$(free -b | mawk 'NR==2 {CONVFMT="%.0f"; print $3/1024^2" of "$2/1024^2" MiB ("$3/$2*100"%)"}')
UPTIME=$(uptime -p)
DISK=$(df -h --output=used,size,pcent / | mawk 'NR==2 {print $1" of "$2" ("$3")"}' 2>&1)
HOSTNAME=$(hostname)

# DietPi update available?
AVAILABLE_UPDATE= # value = version string
Check_DietPi_Update()
{
	[[ -f '/run/dietpi/.update_available' ]] || return 1
	read -r AVAILABLE_UPDATE < /run/dietpi/.update_available
	return 0
}

# New DietPi live patches available?
LIVE_PATCHES=0
Check_DietPi_Live_Patches()
{
	[[ -f '/run/dietpi/.live_patches' ]] || return 1
	LIVE_PATCHES=1
	return 0
}

# APT updates available?
PACKAGE_COUNT=0
Check_APT_Updates()
{
	[[ -f '/run/dietpi/.apt_updates' ]] || return 1
	read -r PACKAGE_COUNT < /run/dietpi/.apt_updates
	return 0
}

# Reboot required to finalise kernel upgrade?
REBOOT_REQUIRED=0
Check_Reboot()
{
	G_CHECK_KERNEL && return 1
	REBOOT_REQUIRED=1
	return 0
}


Print_Header()
{
	# DietPi update available?
	if Check_DietPi_Update
	then
		local text_update_available_date="${GREEN}Update available"

	# New DietPi live patches available?
	elif Check_DietPi_Live_Patches
	then
		local text_update_available_date="${GREEN}New live patches available"

	# APT update available?
	elif Check_APT_Updates
	then
		local text_update_available_date="${GREEN}$PACKAGE_COUNT APT updates available"

	# Reboot required to finalise kernel upgrade?
	elif Check_Reboot
	then
		local text_update_available_date="${GREEN}Reboot required"
	else
		local locale=$(sed -n '/^[[:blank:]]*AUTO_SETUP_LOCALE=/{s/^[^=]*=//p;q}' /boot/dietpi.txt)
		local text_update_available_date=$(LC_ALL=${locale:-C.UTF-8} date '+%R - %a %x')
	fi

		echo -e "${GREEN}v$DIETPI_VERSION$COLOUR_RESET"
}

Print_Date()
{ 
	echo -e $(LC_ALL=${locale:-C.UTF-8} date '+%R - %a %x')
}

Print_Software()
{ 
	/boot/dietpi/dietpi-software list | grep '=2' | awk -F'|' '{split($3, a, ":"); gsub(/^[ \t]+/, "", a[1]); printf "%s, ", a[1]}'
}

# OpenArc-Banner
echo -e "${PURPLE}  _____                   ___           "
echo -e "${PURPLE} |  _  |                 / _ \          "
echo -e "${PURPLE} | | | |_ __   ___ _ __ / /_\ \_ __ ___ "
echo -e "${PURPLE} | | | | '_ \ / _ \ '_ \|  _  | '__/ __|"
echo -e "${PURPLE} \ \_/ / |_) |  __/ | | | | | | | | (__ "
echo -e "${PURPLE}  \___/| .__/ \___|_| |_\_| |_/_|  \___|"
echo -e "${PURPLE}       | |                              "
echo -e "${PURPLE}       |_|                              "
echo -e "${PURPLE} #############################################"
echo -e ""
echo -e "${CYAN}  Welcome to ${YELLOW}OpenArcOS${CYAN} – The Open Source Architecture Platform${NC}"
echo -e ""

# Projektinfo
echo -e "${YELLOW}  $(Print_Date)" 
echo -e ""
echo -e "${GREEN}  🛠️  Version:${NC}        1.0.0" 
echo -e "${GREEN}  🧠  Based on:${NC}      DietPi (GPLv2) $(Print_Header)"
echo -e "${GREEN}  🔌  Modules:${NC}       EVCC, $(Print_Software)"
echo -e "${GREEN}  🌐  Web UI:${NC}        http://eHiveOne.local/"
echo -e ""

# Live-Systemstatus
echo -e "${YELLOW}  📊 Systemstatus:${NC}"
echo -e "    🔹 Hostname:   $HOSTNAME"
echo -e "    🔹 Uptime:     $UPTIME"
echo -e "    🔹 IP Address: $IP"
echo -e "    🔹 CPU Temp:   $CPU_TEMP"
echo -e "    🔹 RAM Usage:  $RAM"
echo -e "    🔹 Disk Usage: $DISK"
echo -e ""
echo -e "$GREEN_BULLET ${GREEN}VPN Status $GREEN_SEPARATOR $(/boot/dietpi/dietpi-vpn status 2>&1)"
echo -e ""
echo -e " ${GREEN}dietpi-launcher$COLOUR_RESET $GREEN_SEPARATOR All the DietPi programs in one place
 ${GREEN}dietpi-config$COLOUR_RESET   $GREEN_SEPARATOR Feature rich configuration tool for your device
 ${GREEN}dietpi-software$COLOUR_RESET $GREEN_SEPARATOR Select optimised software for installation
 ${GREEN}htop$COLOUR_RESET            $GREEN_SEPARATOR Resource monitor
 ${GREEN}cpu$COLOUR_RESET             $GREEN_SEPARATOR Shows CPU information and stats\n"