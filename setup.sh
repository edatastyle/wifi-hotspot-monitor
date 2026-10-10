#!/usr/bin/env bash
#
# Developed by: Md. Saiful Islam
# Email: e2getway@gmail.com
# Website: https://edatastyle.com/
#
# Single-entry setup & run for Wi-Fi Hotspot resources.
# Usage:
#   sudo ./setup.sh                  # Interactive menu
#   sudo ./setup.sh basic            # Interactive basic hotspot (scripts/wifi-hotspot.sh)
#   sudo ./setup.sh loveallah        # Quick LoveAllah profile
#   sudo ./setup.sh manager [port]   # Full Hotspot Manager dashboard (default port 8080)
#   sudo ./setup.sh manager --service

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

if [[ $EUID -ne 0 ]]; then
    echo "Please run with sudo:  sudo ./setup.sh"
    exit 1
fi

usage() {
    cat <<HELP
Wi-Fi Hotspot Toolkit
Developed by Md. Saiful Islam (https://edatastyle.com/)

Usage: sudo ./setup.sh [command]

Commands:
  (none)              Show interactive menu
  basic               Create & start a custom hotspot (interactive)
  loveallah           Start/repair the pre-configured LoveAllah hotspot
  manager [port]      Install deps + launch full Hotspot Manager dashboard
  manager --service   Same, and enable start-at-boot
  help                Show this help

Examples:
  sudo ./setup.sh basic
  sudo ./setup.sh manager 8080
  sudo ./setup.sh manager --service
HELP
}

menu() {
    echo "=========================================="
    echo "  Wi-Fi Hotspot Toolkit"
    echo "  by Md. Saiful Islam"
    echo "=========================================="
    echo
    echo "1) Basic interactive hotspot (SSID/password you choose)"
    echo "2) LoveAllah quick start / fix"
    echo "3) Full Hotspot Manager (dashboard + device control)"
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
    loveallah|love|start) bash "$ROOT/scripts/fix-hotspot.sh" ;;
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
