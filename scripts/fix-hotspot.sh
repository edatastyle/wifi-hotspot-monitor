#!/usr/bin/env bash
#
# Developed by: Md. Saiful Islam
# Email: e2getway@gmail.com
# Website: https://edatastyle.com/
#
# Create or repair a NetworkManager Wi-Fi hotspot profile.
# Default SSID: LoveAllah  |  You can change the name during setup.

set -euo pipefail

DEFAULT_SSID="LoveAllah"
DEFAULT_PASSWORD="78123456"
DEFAULT_IFACE="wlan0"
DEFAULT_CHANNEL="6"
CONFIG_FILE="/etc/hotspot-manager/hotspot.env"

# Load previous settings if present
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE" 2>/dev/null || true
fi

SSID="${SSID:-$DEFAULT_SSID}"
PASSWORD="${PASSWORD:-$DEFAULT_PASSWORD}"
IFACE="${IFACE:-$DEFAULT_IFACE}"
CHANNEL="${CHANNEL:-$DEFAULT_CHANNEL}"
CON="${CON:-$SSID}"

echo "=========================================="
echo "  Hotspot setup / repair"
echo "  Developed by Md. Saiful Islam"
echo "=========================================="
echo
echo "Press Enter to keep the value shown in [brackets]."
echo

# Check for root privileges.
if [[ "$EUID" -ne 0 ]]; then
    echo "Run this script with: sudo bash scripts/fix-hotspot.sh"
    exit 1
fi

# Discover Wi-Fi interfaces if needed
mapfile -t WIFI_DEVICES < <(
    nmcli -t -f DEVICE,TYPE device status 2>/dev/null |
    awk -F: '$2 == "wifi" {print $1}'
)

if [[ ${#WIFI_DEVICES[@]} -eq 0 ]]; then
    echo "ERROR: No Wi-Fi devices found."
    nmcli device status 2>/dev/null || true
    exit 1
fi

echo "Available Wi-Fi adapters: ${WIFI_DEVICES[*]}"
read -rp "Wi-Fi interface [$IFACE]: " input
IFACE="${input:-$IFACE}"

if ! nmcli device status | grep -q "^${IFACE}[[:space:]]"; then
    echo "ERROR: Interface $IFACE was not found."
    nmcli device status
    exit 1
fi

read -rp "Hotspot name (SSID) [$SSID]: " input
SSID="${input:-$SSID}"
if [[ -z "$SSID" || ${#SSID} -gt 32 ]]; then
    echo "SSID must be 1–32 characters."
    exit 1
fi
CON="$SSID"

read -rsp "Password (8–63 chars) [hidden, default kept if empty]: " input
echo
if [[ -n "$input" ]]; then
    if [[ ${#input} -lt 8 || ${#input} -gt 63 ]]; then
        echo "Password must be 8–63 characters."
        exit 1
    fi
    PASSWORD="$input"
fi

echo
echo "Channel options: 1, 6, or 11 (2.4 GHz)"
read -rp "Channel [$CHANNEL]: " input
CHANNEL="${input:-$CHANNEL}"
case "$CHANNEL" in
    1|6|11) ;;
    *) echo "Invalid channel. Using 6."; CHANNEL=6 ;;
esac

echo
echo "Configuration summary:"
echo "  Interface : $IFACE"
echo "  SSID      : $SSID"
echo "  Profile   : $CON"
echo "  Channel   : $CHANNEL"
echo "  Security  : WPA2-PSK / CCMP"
echo
read -rp "Apply and start hotspot? [Y/n]: " CONFIRM
if [[ "${CONFIRM:-Y}" =~ ^[Nn] ]]; then
    echo "Cancelled."
    exit 0
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

# Save settings for next time
mkdir -p "$(dirname "$CONFIG_FILE")"
cat > "$CONFIG_FILE" <<ENV
SSID="$SSID"
PASSWORD="$PASSWORD"
IFACE="$IFACE"
CHANNEL="$CHANNEL"
CON="$CON"
ENV
chmod 600 "$CONFIG_FILE"

# Restart the hotspot.
nmcli connection down "$CON" >/dev/null 2>&1 || true
nmcli connection up "$CON"

echo
echo "=== Hotspot is running ==="
echo "SSID:     $SSID"
echo "Password: (the one you set)"
echo "Channel:  $CHANNEL (2.4 GHz)"
echo "Profile:  $CON"
echo
echo "Settings saved to $CONFIG_FILE"
echo "On client devices: forget the old network (if any) and reconnect."
echo
nmcli device status
