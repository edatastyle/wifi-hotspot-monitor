#!/usr/bin/env bash
#
# Developed by: Md. Saiful Islam
# Email: e2getway@gmail.com
# Website: https://edatastyle.com/
#
# Hotspot Manager - single entry point
# Usage:
#   sudo ./setup.sh                  # Interactive menu
#   sudo ./setup.sh basic            # Interactive custom hotspot
#   sudo ./setup.sh hotspot          # Configure / start hotspot (default name: LoveAllah)
#   sudo ./setup.sh manager [port]   # Full dashboard (default port 8080)
#   sudo ./setup.sh manager --service

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

if [[ $EUID -ne 0 ]]; then
    echo "Please run with sudo:  sudo ./setup.sh"
    exit 1
fi

usage() {
    cat <<HELP
Hotspot Manager - Wi-Fi Hotspot Monitor and Access Control Dashboard
Developed by Md. Saiful Islam (https://edatastyle.com/)

Usage: sudo ./setup.sh [command]

Commands:
  (none)              Show interactive menu
  basic               Create a custom hotspot (you choose SSID, password, channel)
  hotspot             Configure / start hotspot (default name: LoveAllah – changeable)
  manager [port]      Install deps + launch full dashboard (device monitor, site blocking)
  manager --service   Same, and enable start-at-boot
  help                Show this help

Examples:
  sudo ./setup.sh basic
  sudo ./setup.sh hotspot
  sudo ./setup.sh manager 8080
  sudo ./setup.sh manager --service
HELP
}

menu() {
    echo "=========================================="
    echo "  Hotspot Manager"
    echo "  Wi-Fi Monitor & Access Control"
    echo "  by Md. Saiful Islam"
    echo "=========================================="
    echo
    echo "1) Custom hotspot (choose your own SSID & password)"
    echo "2) Quick hotspot setup (default name: LoveAllah – you can change it)"
    echo "3) Full Manager dashboard (devices, blocking, activity)"
    echo "4) Help"
    echo "5) Exit"
    echo
    read -rp "Choose [1-5]: " choice
    case "$choice" in
        1) exec bash "$ROOT/scripts/wifi-hotspot.sh" ;;
        2) exec bash "$ROOT/scripts/fix-hotspot.sh" ;;
        3) exec bash "$ROOT/hotspot-manager/run.sh" ;;
        4) usage; exit 0 ;;
        5) exit 0 ;;
        *) echo "Invalid choice"; exit 1 ;;
    esac
}

cmd="${1:-}"
case "$cmd" in
    "" ) menu ;;
    help|-h|--help) usage ;;
    basic) bash "$ROOT/scripts/wifi-hotspot.sh" ;;
    hotspot|loveallah|love|start|fix)
        bash "$ROOT/scripts/fix-hotspot.sh"
        ;;
    manager|dashboard|full)
        shift || true
        bash "$ROOT/hotspot-manager/run.sh" "$@"
        ;;
    *)
        echo "Unknown command: $cmd"
        usage
        exit 1
        ;;
esac
