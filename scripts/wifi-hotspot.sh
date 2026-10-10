#!/usr/bin/env bash
#
# Developed by: Md. Saiful Islam
# Email: e2getway@gmail.com
# Website: https://edatastyle.com/
#
# Wi-Fi Hotspot Manager for Linux (NetworkManager)
# Interactive setup and start of a Wi-Fi access point.

set -Eeuo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Please run: sudo bash wifi-hotspot.sh"
    exit 1
fi

for cmd in nmcli iw; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: Required command '$cmd' is not installed."
        exit 1
    fi
done

echo "======================================"
echo "       Wi-Fi Hotspot Manager"
echo "======================================"

# Enable Wi-Fi radio.
echo
echo "Enabling Wi-Fi..."
nmcli radio wifi on

# Discover Wi-Fi interfaces.
mapfile -t WIFI_DEVICES < <(
    nmcli -t -f DEVICE,TYPE device status |
    awk -F: '$2 == "wifi" {print $1}'
)

if [[ ${#WIFI_DEVICES[@]} -eq 0 ]]; then
    echo "ERROR: No Wi-Fi devices found."
    nmcli device status
    exit 1
fi

echo
echo "Available Wi-Fi adapters:"
for i in "${!WIFI_DEVICES[@]}"; do
    printf "  %d) %s\n" "$((i + 1))" "${WIFI_DEVICES[$i]}"
done

while true; do
    read -rp "Select adapter number: " DEVICE_CHOICE
    if [[ "$DEVICE_CHOICE" =~ ^[0-9]+$ ]] &&
       (( DEVICE_CHOICE >= 1 && DEVICE_CHOICE <= ${#WIFI_DEVICES[@]} )); then
        IFACE="${WIFI_DEVICES[$((DEVICE_CHOICE - 1))]}"
        break
    fi
    echo "Invalid selection. Try again."
done

# Enter hotspot settings.
echo
read -rp "Hotspot Wi-Fi name (SSID): " SSID
if [[ -z "$SSID" || ${#SSID} -gt 32 ]]; then
    echo "SSID must contain 1-32 characters."
    exit 1
fi

read -rsp "Hotspot password (8-63 characters): " PASSWORD
echo
if [[ ${#PASSWORD} -lt 8 || ${#PASSWORD} -gt 63 ]]; then
    echo "Password must contain 8-63 characters."
    exit 1
fi

DEFAULT_PROFILE="${SSID}-${IFACE}"
read -rp "Connection profile name [$DEFAULT_PROFILE]: " PROFILE
PROFILE="${PROFILE:-$DEFAULT_PROFILE}"

# Channel selection.
echo
echo "Select 2.4 GHz channel:"
echo "  1) Channel 1"
echo "  2) Channel 6"
echo "  3) Channel 11"
read -rp "Choose [2]: " CHANNEL_CHOICE
CHANNEL_CHOICE="${CHANNEL_CHOICE:-2}"

case "$CHANNEL_CHOICE" in
    1) CHANNEL=1 ;;
    2) CHANNEL=6 ;;
    3) CHANNEL=11 ;;
    *)
        echo "Invalid channel selection."
        exit 1
        ;;
esac

echo
echo "Hotspot configuration:"
echo "  Adapter:  $IFACE"
echo "  SSID:     $SSID"
echo "  Profile:  $PROFILE"
echo "  Channel:  $CHANNEL"
echo "  Security: WPA2-PSK / CCMP"
echo "  Internet: NetworkManager shared mode"
echo
read -rp "Continue? [Y/n]: " CONFIRM
if [[ "$CONFIRM" =~ ^[Nn] ]]; then
    echo "Cancelled."
    exit 0
fi

# Create or update the connection profile.
if nmcli -t -f NAME connection show |
   grep -Fxq "$PROFILE"; then
    echo "Updating existing profile: $PROFILE"
else
    echo "Creating profile: $PROFILE"
    nmcli connection add \
        type wifi \
        ifname "$IFACE" \
        con-name "$PROFILE" \
        ssid "$SSID"
fi

# Configure access point and security.
nmcli connection modify "$PROFILE" \
    connection.interface-name "$IFACE" \
    802-11-wireless.mode ap \
    802-11-wireless.band bg \
    802-11-wireless.channel "$CHANNEL" \
    802-11-wireless.ssid "$SSID" \
    802-11-wireless-security.key-mgmt wpa-psk \
    802-11-wireless-security.proto rsn \
    802-11-wireless-security.pairwise ccmp \
    802-11-wireless-security.group ccmp \
    802-11-wireless-security.psk "$PASSWORD" \
    ipv4.method shared

# Start the hotspot.
echo
echo "Starting hotspot..."
nmcli connection up "$PROFILE" ifname "$IFACE"

echo
echo "======================================"
echo "       Hotspot Started"
echo "======================================"
echo "SSID:     $SSID"
echo "Adapter:  $IFACE"
echo "Channel:  $CHANNEL"
echo "Profile:  $PROFILE"

echo
echo "=== Wi-Fi device status ==="
nmcli device status

echo
echo "=== Active connections ==="
nmcli connection show --active

echo
echo "=== Adapter details ==="
iw dev "$IFACE" info
