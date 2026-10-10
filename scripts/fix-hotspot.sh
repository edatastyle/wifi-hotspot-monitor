#!/usr/bin/env bash
#
# Developed by: Md. Saiful Islam
# Email: e2getway@gmail.com
# Website: https://edatastyle.com/
#
# Repair / reconfigure the "LoveAllah" hotspot profile.

set -euo pipefail

CON="LoveAllah"
IFACE="wlan0"
SSID="LoveAllah"
PASSWORD="78123456"
CHANNEL="6"

echo "=== Fixing Wi-Fi hotspot: $SSID ==="

# Check for root privileges.
if [[ "$EUID" -ne 0 ]]; then
    echo "Run this script with: sudo bash fix-hotspot.sh"
    exit 1
fi

# Confirm that the Wi-Fi interface exists.
if ! nmcli device status | grep -q "^${IFACE}[[:space:]]"; then
    echo "ERROR: Interface $IFACE was not found."
    nmcli device status
    exit 1
fi

# Ensure the connection profile exists.
if ! nmcli connection show "$CON" >/dev/null 2>&1; then
    echo "Creating hotspot profile..."
    nmcli connection add type wifi ifname "$IFACE" \
        con-name "$CON" ssid "$SSID"
fi

# Configure the hotspot for 2.4 GHz, WPA2-AES, and shared IPv4.
nmcli connection modify "$CON" \
    connection.interface-name "$IFACE" \
    connection.autoconnect no \
    802-11-wireless.mode ap \
    802-11-wireless.band bg \
    802-11-wireless.channel "$CHANNEL" \
    802-11-wireless.ssid "$SSID" \
    802-11-wireless-security.key-mgmt wpa-psk \
    802-11-wireless-security.proto rsn \
    802-11-wireless-security.pairwise ccmp \
    802-11-wireless-security.group ccmp \
    802-11-wireless-security.psk "$PASSWORD" \
    ipv4.method shared \
    ipv6.method auto

# Restart the hotspot.
nmcli connection down "$CON" >/dev/null 2>&1 || true
nmcli connection up "$CON"

echo
echo "=== Hotspot configuration ==="
nmcli -f \
802-11-wireless.ssid,\
802-11-wireless.mode,\
802-11-wireless.band,\
802-11-wireless.channel,\
802-11-wireless-security.key-mgmt,\
802-11-wireless-security.proto,\
802-11-wireless-security.pairwise \
connection show "$CON"

echo
echo "=== Active Wi-Fi connections ==="
nmcli device status

echo
echo "Hotspot restarted."
echo "SSID: $SSID"
echo "Password: $PASSWORD"
echo "Channel: $CHANNEL (2.4 GHz)"
echo
echo "On the client device, forget LoveAllah and reconnect."
echo "If it still fails, inspect NetworkManager logs."
