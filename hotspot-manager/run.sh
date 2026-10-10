#!/usr/bin/env bash
#
# Developed by: Md. Saiful Islam
# Email: e2getway@gmail.com
# Website: https://edatastyle.com/
#
# Hotspot Manager - one-command installer and launcher
# Usage:  sudo ./run.sh [port]        install missing deps, set up a hotspot if needed, start the dashboard
#         sudo ./run.sh --service     also start automatically at every boot
#         sudo ./run.sh --no-hotspot  skip the hotspot setup question

set -e
cd "$(dirname "$0")"; DIR="$(pwd)"
say() { printf '\n\033[1m%s\033[0m\n' "$*"; }
[ "$(id -u)" = 0 ] || { echo "Run it with sudo:  sudo ./run.sh"; exit 1; }
[ "$(uname -s)" = Linux ] || { echo "This tool needs Linux (Ubuntu, Debian or Raspberry Pi OS)."; exit 1; }
PORT=8080; SERVICE=0; HOTSPOT=1
for a in "$@"; do case "$a" in --service) SERVICE=1;; --no-hotspot) HOTSPOT=0;; [0-9]*) PORT="$a";; esac; done

# 1. Install missing dependencies
need=""
command -v php >/dev/null      || need="$need php-cli"
command -v python3 >/dev/null  || need="$need python3"
command -v iw >/dev/null       || need="$need iw"
command -v iptables >/dev/null || need="$need iptables"
command -v ip >/dev/null && command -v ss >/dev/null || need="$need iproute2"
command -v pgrep >/dev/null    || need="$need procps"
command -v nmcli >/dev/null    || need="$need network-manager"
command -v rfkill >/dev/null   || need="$need rfkill"
[ -x /usr/sbin/dnsmasq ] || command -v dnsmasq >/dev/null || need="$need dnsmasq-base"
[ -f /usr/share/ieee-data/oui.txt ] || need="$need ieee-data"
if [ -n "$need" ]; then
  say "Installing:$need"
  if command -v apt-get >/dev/null; then
    apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y $need
  else
    echo "Automatic install needs apt. Install these with your package manager, then run again:$need"; exit 1
  fi
fi
rfkill unblock wifi 2>/dev/null || true
chmod +x agent/hsagent.py

# 2. Hotspot: use the running one, or offer to create one
active_hotspot() {
  nmcli -t -f NAME con show --active 2>/dev/null | while IFS= read -r n; do
    [ "$(nmcli -g ipv4.method con show "$n" 2>/dev/null)" = shared ] && echo "$n"
  done
}
if [ "$HOTSPOT" = 1 ] && command -v nmcli >/dev/null; then
  HS="$(active_hotspot | head -1)"
  if [ -n "$HS" ]; then
    echo "Hotspot found: $HS"
  else
    IF="$(nmcli -t -f DEVICE,TYPE dev | awk -F: '$2=="wifi"{print $1; exit}')"
    if [ -z "$IF" ]; then
      echo "No Wi-Fi adapter found, so no hotspot can be created."
    else
      say "No hotspot is running."
      echo "Devices will get internet only if a hotspot is active."
      read -rp "Create a hotspot on $IF now? [Y/n] " ans
      if [ "${ans:-Y}" != "n" ] && [ "${ans:-Y}" != "N" ]; then
        read -rp "SSID [Hotspot]: " SSID; SSID="${SSID:-Hotspot}"
        read -rsp "Password (8+ chars): " PASS; echo
        while [ ${#PASS} -lt 8 ]; do read -rsp "Password too short, try again: " PASS; echo; done
        nmcli device wifi hotspot ifname "$IF" ssid "$SSID" password "$PASS" 2>/dev/null || \
        nmcli connection add type wifi ifname "$IF" con-name "$SSID" ssid "$SSID" && \
        nmcli connection modify "$SSID" 802-11-wireless.mode ap 802-11-wireless.band bg \
          802-11-wireless-security.key-mgmt wpa-psk 802-11-wireless-security.psk "$PASS" ipv4.method shared && \
        nmcli connection up "$SSID" ifname "$IF"
        echo "Hotspot $SSID is up."
      fi
    fi
  fi
fi

# 3. Config + password
if [ ! -f config.php ]; then
  say "First run – set a login password for the dashboard"
  read -rsp "Password for user 'admin': " PASS; echo
  while [ ${#PASS} -lt 6 ]; do read -rsp "At least 6 characters: " PASS; echo; done
  HASH="$(php -r "echo password_hash('$PASS', PASSWORD_DEFAULT);")"
  printf "<?php return ['username'=>'admin','password_hash'=>'%s','agent'=>__DIR__.'/agent/hsagent.py'];\n" "$HASH" > config.php
  chmod 600 config.php
fi
python3 agent/hsagent.py apply > /dev/null || true

# 4. Optional: start at boot
if [ "$SERVICE" = 1 ]; then
  cat > /etc/systemd/system/hotspot-manager.service <<UNIT
[Unit]
Description=Hotspot Manager (Md. Saiful Islam)
After=network-online.target NetworkManager.service
Wants=network-online.target
[Service]
ExecStart=$DIR/run.sh $PORT --no-hotspot
Restart=on-failure
[Install]
WantedBy=multi-user.target
UNIT
  systemctl daemon-reload && systemctl enable --now hotspot-manager
  say "Installed. Dashboard starts at every boot: http://localhost:$PORT  (user: admin)"; exit 0
fi

# 5. Start (stops an older copy and skips busy ports)
PIDF=/run/hotspot-manager.pid
[ -f "$PIDF" ] && kill "$(cat "$PIDF")" 2>/dev/null || true
sleep 0.5
while ss -ltn 2>/dev/null | grep -q ":$PORT "; do PORT=$((PORT+1)); done
echo $$ > "$PIDF"
say "Open http://localhost:$PORT   (user: admin)   Ctrl+C to stop"
PHP_CLI_SERVER_WORKERS=4 exec php -S 127.0.0.1:"$PORT" -t public
