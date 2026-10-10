#!/usr/bin/env bash
#
# Developed by: Md. Saiful Islam
# Email: e2getway@gmail.com
# Website: https://edatastyle.com/
#
# Start a previously configured hotspot profile.
# Uses settings from /etc/hotspot-manager/hotspot.env (created by fix-hotspot.sh).
# Default SSID: LoveAllah

set -euo pipefail

CONFIG_FILE="/etc/hotspot-manager/hotspot.env"
DEFAULT_SSID="LoveAllah"
DEFAULT_IFACE="wlan0"

SSID="$DEFAULT_SSID"
IFACE="$DEFAULT_IFACE"
CON="$DEFAULT_SSID"

if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE" 2>/dev/null || true
fi

CON="${CON:-$SSID}"

echo "=== Starting hotspot: $SSID ==="

if [[ "$EUID" -ne 0 ]]; then
    echo "Please run: sudo ./scripts/start-hotspot.sh"
    exit 1
fi

echo "[1/4] Enabling Wi-Fi..."
nmcli radio wifi on

echo "[2/4] Checking Wi-Fi interface ($IFACE)..."
nmcli device status

if ! nmcli connection show "$CON" >/dev/null 2>&1; then
    echo "Profile '$CON' not found."
    echo "Run:  sudo ./scripts/fix-hotspot.sh   to create or configure it first."
    exit 1
fi

echo "[3/4] Activating hotspot..."
nmcli connection up "$CON" ifname "$IFACE"

echo
echo "[4/4] Active connections:"
nmcli connection show --active

echo
echo "=== Hotspot started successfully ==="
echo "SSID: $SSID"
