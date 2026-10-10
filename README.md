# Wi-Fi Hotspot Toolkit

**One-command Wi-Fi hotspot setup and management for Linux** (Ubuntu, Debian, Kali, Raspberry Pi OS, etc.)

Developed by **Md. Saiful Islam**  
Email: e2getway@gmail.com  
Website: [https://edatastyle.com/](https://edatastyle.com/)

---

## Features

- **Basic interactive hotspot** – choose adapter, SSID, password, channel and start immediately
- **LoveAllah quick profile** – pre-configured hotspot ready to start/repair
- **Full Hotspot Manager** – web dashboard to:
  - See connected devices (hostname, MAC, vendor, signal, OS guess)
  - Block / allow devices by MAC
  - Block websites / domains (and whole presets)
  - Redirect domains
  - View live DNS activity
  - Restart hotspot with one click
- Single entry point: `sudo ./setup.sh`
- Automatic dependency installation (apt-based systems)
- NetworkManager + `nmcli` based (no hostapd required for the basic mode)

---

## Requirements

- Linux with **NetworkManager**
- A Wi-Fi adapter that supports **AP / master mode** (`iw list | grep -A8 "Supported interface modes"` should show `AP`)
- Root / sudo privileges
- For the full Manager: PHP CLI, Python 3, iptables, dnsmasq, iw

---

## Quick Start (GitHub / one-liner)

```bash
# Clone
git clone https://github.com/edatastyle/wifi-hotspot-monitor.git
cd wifi-hotspot-monitor

# Make executable
chmod +x setup.sh scripts/*.sh hotspot-manager/run.sh hotspot-manager/agent/hsagent.py

# Run the interactive menu
sudo ./setup.sh
```

Or jump straight to a mode:

```bash
# Interactive custom hotspot
sudo ./setup.sh basic

# Pre-configured LoveAllah hotspot
sudo ./setup.sh loveallah

# Full Manager dashboard (installs missing packages automatically)
sudo ./setup.sh manager

# Manager + auto-start at boot
sudo ./setup.sh manager --service
```

The Manager dashboard will be available at **http://127.0.0.1:8080** (or the port you chose).  
Default login is configured on first run.

---

## Installation & Usage Details

### 1. Basic Interactive Hotspot

```bash
sudo ./setup.sh basic
# or
sudo ./scripts/wifi-hotspot.sh
```

You will be asked for:

- Wi-Fi adapter
- SSID (network name)
- Password (WPA2)
- Channel (1 / 6 / 11)
- Profile name

The script creates (or updates) a NetworkManager connection in shared mode and brings it up.

### 2. LoveAllah Quick Profile

```bash
sudo ./setup.sh loveallah
# or
sudo ./scripts/fix-hotspot.sh   # also repairs the profile
sudo ./scripts/start-hotspot.sh  # only starts if profile already exists
```

Default values (edit the scripts if you want different ones):

| Setting   | Value      |
|-----------|------------|
| SSID      | LoveAllah  |
| Password  | 78123456   |
| Interface | wlan0      |
| Channel   | 6          |

### 3. Full Hotspot Manager (recommended for ongoing control)

```bash
sudo ./setup.sh manager [port]
# default port = 8080
```

What `hotspot-manager/run.sh` does:

1. Installs missing packages (`php-cli`, `python3`, `iw`, `iptables`, `dnsmasq`, `network-manager`, …)
2. Detects or offers to create a hotspot
3. Writes a secure `config.php` (you set a password on first run)
4. Adds a sudoers rule so the web UI can talk to the privileged agent
5. Starts a PHP built-in server on the chosen port
6. Optionally installs a systemd service for auto-start

Open the dashboard → sign in → manage devices, block sites, etc.

#### Manager configuration

- Copy `hotspot-manager/config.example.php` → `hotspot-manager/config.php` if you want to edit manually.
- Generate a password hash:
  ```bash
  php -r 'echo password_hash("your-strong-password", PASSWORD_DEFAULT), "\n";'
  ```
- Optional advanced settings live in `/etc/hotspot-manager/config.json` (interface name, leases file, etc.).

---

## Project Structure

```
wifi-hotspot/
├── setup.sh                 # ← Single entry point (use this)
├── README.md
├── LICENSE
├── .gitignore
├── scripts/
│   ├── wifi-hotspot.sh      # Interactive basic hotspot
│   ├── start-hotspot.sh     # Start LoveAllah profile
│   └── fix-hotspot.sh       # Repair LoveAllah profile
└── hotspot-manager/
    ├── run.sh               # Full manager installer + launcher
    ├── config.example.php
    ├── lib.php
    ├── agent/
    │   └── hsagent.py       # Privileged Python agent
    └── public/
        ├── index.php        # Dashboard UI
        └── api.php          # JSON API
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `Interface wlan0 not found` | Run `nmcli device status` and edit the `IFACE` variable in the scripts, or use the interactive `basic` mode. |
| Adapter does not support AP mode | Check with `iw list \| grep -A8 "Supported interface modes"`. Use a USB Wi-Fi adapter that supports AP. |
| Devices connect but have no internet | Your computer must already have internet on another interface (Ethernet, USB tether, second Wi-Fi, etc.). Check `sysctl net.ipv4.ip_forward` is `1`. |
| Hotspot will not start | `sudo rfkill unblock wifi`. Make sure the adapter is not already connected as a client to another network. |
| Manager: “Could not start the agent” | The sudoers rule was not installed. Re-run `sudo ./setup.sh manager`. |
| Manager: red error banner | Always start the dashboard with `sudo ./run.sh` (or via `setup.sh`). |
| Blocked site still opens | Disable Private DNS / Secure DNS / iCloud Private Relay / VPNs on the client device, then toggle Wi-Fi. Click **Restart hotspot** in the dashboard. |
| Password / login forgotten | Delete `hotspot-manager/config.php` and re-run `sudo ./setup.sh manager`. |
| NetworkManager not managing Wi-Fi | On servers using netplan, set `renderer: NetworkManager`. |

### Useful diagnostic commands

```bash
nmcli device status
nmcli connection show --active
iw dev wlan0 info
iw list | grep -A8 "Supported interface modes"
journalctl -u NetworkManager -e
sudo iptables -t nat -L -n -v
```

---

## Security Notes

- The dashboard listens on `127.0.0.1` by default (only reachable from the host).
- The privileged agent is only callable via a tightly-scoped sudoers rule.
- Always inform people who connect to your hotspot that traffic may be monitored / filtered.
- Change the default LoveAllah password if you use that profile on a public network.

---

## License

MIT License – see [LICENSE](LICENSE).

---

## Credits

Developed by **Md. Saiful Islam**  
Email: e2getway@gmail.com  
Website: https://edatastyle.com/

Original Hotspot Manager concepts inspired by community tools; all code in this repository has been organized, cleaned and attributed for open use.
