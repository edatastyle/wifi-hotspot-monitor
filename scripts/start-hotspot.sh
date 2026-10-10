#!/usr/bin/env bash
#
# Developed by: Md. Saiful Islam
# Email: e2getway@gmail.com
# Website: https://edatastyle.com/
#
# Quick start for a pre-configured "LoveAllah" hotspot profile.

set -euo pipefail

CON="LoveAllah"
IFACE="wlan0"

echo "=== Starting LoveAllah Hotspot ==="

# Ensure the script is run as root.
if [[ "$EUID" -ne 0 ]]; then
    echo "Please run: sudo ./start-hotspot.sh"
    exit 1
fi

# Enable Wi-Fi radio.
echo "[1/4] Enabling Wi-Fi..."
nmcli radio wifi on

# Ensure the Wi-Fi device is available.
echo "[2/4] Checking Wi-Fi interface..."
nmcli device status

# Activate the saved hotspot profile.
echo "[3/4] Activating hotspot..."
nmcli connection up "$CON" ifname "$IFACE"

# Verify active connections.
echo
echo "[4/4] Active connections:"
nmcli connection show --active

echo
echo "=== Hotspot started successfully ==="
echo "SSID: LoveAllah"
