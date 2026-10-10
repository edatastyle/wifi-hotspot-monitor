# Hotspot Manager - Wi-Fi Hotspot Monitor and Access Control Dashboard (PHP + Python)

**One-command Wi-Fi hotspot setup, device monitoring, and access control for Linux**

Developed by **Md. Saiful Islam**  
Email: e2getway@gmail.com  
Website: [https://edatastyle.com/](https://edatastyle.com/)

---

## What this project does

Hotspot Manager turns a Linux computer into a Wi-Fi access point and gives you a simple web dashboard to:

- **Monitor connected devices** – see who is on your hotspot (hostname, MAC address, vendor, signal strength, OS guess)
- **Monitor network traffic (DNS-level)** – view recent website lookups made by devices on the hotspot
- **Block risky or inappropriate websites** – stop access to specific domains (and useful presets) to help protect children and keep the network focused
- **Audit visited websites** (where technically supported) – DNS query logs show which domains were requested; this is domain-level visibility, not full page content
- **Control access** – block or allow devices by MAC address, kick a device, rename devices for clarity
- **Restart the hotspot** with one click from the dashboard

It is designed for home, family, small office, or lab use on Ubuntu, Debian, Kali, Raspberry Pi OS, and similar distributions that use NetworkManager.

---

## Features at a glance

| Area | Capability |
|------|------------|
| Hotspot | Create a WPA2 access point with NetworkManager (`nmcli`). Name is configurable (default: **LoveAllah**). |
| Devices | List connected clients, signal, vendor, guessed OS, custom names |
| Access control | Block / allow by MAC, kick device |
| Web filtering | Block domains and subdomains; optional presets (social, video, gaming, ads) |
| Activity | Recent DNS lookups from devices on the hotspot |
| Dashboard | Local web UI (default `http://127.0.0.1:8080`), login protected |
| Setup | Single script: `sudo ./setup.sh` – installs missing packages when needed |

---

## Requirements

- Linux with **NetworkManager**
- A Wi-Fi adapter that supports **AP (access point) mode**  
  Check with: `iw list | grep -A8 "Supported interface modes"` (look for `AP`)
- Root / sudo privileges
- For the full dashboard: PHP CLI, Python 3, iptables, dnsmasq, iw  
  (the manager installer can install these on apt-based systems)

---

## Quick start

```bash
git clone https://github.com/edatastyle/wifi-hotspot-monitor.git
cd wifi-hotspot-monitor

chmod +x setup.sh scripts/*.sh hotspot-manager/run.sh hotspot-manager/agent/hsagent.py

# Interactive menu
sudo ./setup.sh
```

Or jump straight to a mode:

```bash
# Custom hotspot – you choose SSID, password, channel
sudo ./setup.sh basic

# Quick hotspot setup (default name LoveAllah – you can change it during the prompts)
sudo ./setup.sh hotspot

# Full Manager dashboard (device list, site blocking, activity)
sudo ./setup.sh manager

# Dashboard + start automatically at boot
sudo ./setup.sh manager --service
```

Dashboard address (default): **http://127.0.0.1:8080**  
First run asks you to set a password for the `admin` user.

---

## Configuring the hotspot name

The default network name (SSID) is **LoveAllah**.

You can change it at any time:

```bash
sudo ./setup.sh hotspot
# or
sudo ./scripts/fix-hotspot.sh
```

You will be prompted for:

- Wi-Fi interface (e.g. `wlan0`)
- **Hotspot name (SSID)** – press Enter to keep the current/default name, or type a new one
- Password
- Channel (1, 6, or 11 on 2.4 GHz)

Settings are saved under `/etc/hotspot-manager/hotspot.env` so the next start uses your chosen name and password.

To only start an already configured hotspot:

```bash
sudo ./scripts/start-hotspot.sh
```

---

## Using the dashboard (Full Manager)

```bash
sudo ./setup.sh manager
# or
sudo ./hotspot-manager/run.sh
```

1. Open **http://127.0.0.1:8080** in a browser on the same computer.
2. Sign in with the password you set on first run.
3. **Devices** tab – see who is connected, kick or block a device.
4. **Rules** tab – block domains (e.g. inappropriate sites), block/allow MACs.
5. **Activity** tab – recent DNS lookups (which domains devices asked for).
6. **Diagnose** – check that blocking and logging are working.
7. Use **Restart hotspot** after changing rules so DNS and firewall settings take effect.

### Blocking websites to help protect children

- On the **Rules** tab, enter a domain (for example `example.com`) and click **Block**.
- Blocking covers the domain and its subdomains at the DNS level.
- Devices that use the hotspot’s DNS (the normal case) will not resolve blocked names.
- Encrypted DNS / Private DNS / VPNs on a device can bypass DNS-based blocks. Blocking a device by MAC still works.

### Auditing visited websites

- The **Activity** view shows recent DNS queries from devices on the hotspot.
- This is **domain-level** information (which names were looked up), not the content of web pages.
- Only traffic that goes through the hotspot’s DNS is visible. Clients that force their own DNS (e.g. 8.8.8.8) may be redirected by the manager’s rules when those rules are active.

---

## Configuration notes

| Item | Location / how |
|------|----------------|
| Hotspot SSID, password, interface | `/etc/hotspot-manager/hotspot.env` (created by `fix-hotspot.sh`) |
| Dashboard login | `hotspot-manager/config.php` (created on first `run.sh`) |
| Optional advanced manager settings | `/etc/hotspot-manager/config.json` (interface name, leases file, etc.) |

Generate a new password hash manually if needed:

```bash
php -r 'echo password_hash("your-strong-password", PASSWORD_DEFAULT), "\n";'
```

Then put the hash into `config.php` (see `config.example.php`).

---

## Privacy and responsible use

- The dashboard listens on **127.0.0.1** by default (only reachable from the host computer).
- DNS-level monitoring and blocking apply only to devices that connect to **your** hotspot.
- You should inform people who use the hotspot that connection activity may be monitored or filtered.
- Use this software only on networks you own or administer, and in compliance with local law and household/organizational policy.
- Do not use it to intercept or monitor traffic you are not authorized to control.

---

## Troubleshooting

| Problem | What to try |
|---------|-------------|
| Interface not found | Run `nmcli device status` and choose the correct adapter in the setup prompts. |
| Adapter does not support AP mode | Check `iw list \| grep -A8 "Supported interface modes"`. Use a USB Wi-Fi adapter that supports AP if needed. |
| Devices connect but have no internet | The host must already have internet on another interface. Check `sysctl net.ipv4.ip_forward` is `1`. |
| Hotspot will not start | `sudo rfkill unblock wifi`. Ensure the adapter is not only in client mode to another network. |
| Dashboard: “Could not start the agent” | Re-run `sudo ./setup.sh manager` so the sudoers rule is installed. |
| Blocked site still opens | Disable Private DNS / Secure DNS / iCloud Private Relay / VPN on the client, then toggle Wi-Fi. Click **Restart hotspot** in the dashboard. |
| Forgot dashboard password | Delete `hotspot-manager/config.php` and run `sudo ./setup.sh manager` again. |

Useful commands:

```bash
nmcli device status
nmcli connection show --active
iw dev wlan0 info
iw list | grep -A8 "Supported interface modes"
journalctl -u NetworkManager -e
```

---

## Project layout

```
wifi-hotspot-monitor/
├── setup.sh                      # Single entry point
├── README.md
├── LICENSE
├── scripts/
│   ├── wifi-hotspot.sh           # Fully interactive custom hotspot
│   ├── fix-hotspot.sh            # Configure / repair (name changeable, default LoveAllah)
│   └── start-hotspot.sh          # Start the saved profile
└── hotspot-manager/
    ├── run.sh                    # Install deps + launch dashboard
    ├── config.example.php
    ├── lib.php
    ├── agent/hsagent.py          # Privileged agent (devices, DNS, iptables)
    └── public/
        ├── index.php             # Dashboard UI
        └── api.php               # JSON API
```

---

## License

MIT License – see [LICENSE](LICENSE).

---

## Credits

Developed by **Md. Saiful Islam**  
Email: e2getway@gmail.com  
Website: https://edatastyle.com/
