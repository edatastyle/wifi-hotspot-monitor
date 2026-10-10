#!/usr/bin/env python3
#
# Developed by: Md. Saiful Islam
# Email: e2getway@gmail.com
# Website: https://edatastyle.com/
#
"""Hotspot Manager agent. Runs as root, prints one JSON object."""

import glob, json, os, random, re, signal, socket, struct, subprocess, sys, time
from collections import Counter, deque
from datetime import datetime

C = {"ap_iface": "wlan0", "leases": "/var/lib/misc/dnsmasq.leases", "dns_log": "/var/log/dnsmasq.log",
     "dnsmasq_conf": "/etc/dnsmasq.d/hotspot-manager.conf", "state": "/var/lib/hotspot-manager/state.json",
     "cache": "/var/lib/hotspot-manager/cache.json", "oui": "/usr/share/ieee-data/oui.txt",
     "dns_port": 53}

# Load optional overrides
try:
    ov = json.load(open("/etc/hotspot-manager/config.json"))
    C.update({k: v for k, v in ov.items() if k in C})
except (OSError, ValueError):
    pass

MAC_RE = re.compile(r"^([0-9a-f]{2}:){5}[0-9a-f]{2}$")
DOM_RE = re.compile(r"^(?=.{4,253}$)([a-z0-9_-]{1,63}\.)+[a-z]{2,63}$")


def sh(*a, timeout=5):
    try:
        r = subprocess.run(a, capture_output=True, text=True, timeout=timeout)
        return r.returncode, r.stdout
    except Exception:
        return 1, ""

def ipt(*a): return sh("iptables", "-w", *a)

def load(p, d):
    try: return json.load(open(p))
    except (OSError, ValueError): return d

def save(p, data):
    os.makedirs(os.path.dirname(p), exist_ok=True)
    json.dump(data, open(p + ".tmp", "w")); os.replace(p + ".tmp", p)

def state():
    s = load(C["state"], {})
    for k, v in {"blocked_domains": [], "redirects": {}, "blocked_macs": [], "allowed_macs": [],
                 "mode": "open", "names": {}, "presets": []}.items(): s.setdefault(k, v)
    return s

def mac(x):
    x = x.lower().replace("-", ":")
    if not MAC_RE.match(x): raise ValueError("Invalid MAC address")
    return x

def dom(x):
    x = re.sub(r"^\w+://", "", x.strip().lower()).split("/")[0].strip(".")
    if not DOM_RE.match(x): raise ValueError("Invalid domain, e.g. example.com")
    return x

def blocked_set(s):
    b = set(s["blocked_domains"])
    for p in s["presets"]: b.update(PRESETS.get(p, []))
    return b - set(s["redirects"])

# ---------- devices ----------
def leases():
    out = {}
    try:
        for ln in open(C["leases"]):
            p = ln.split()
            if len(p) >= 4: out[p[1].lower()] = {"ip": p[2], "hostname": "" if p[3] == "*" else p[3]}
    except OSError: pass
    return out

def stations():
    res, cur = {}, None
    for ln in sh("iw", "dev", C["ap_iface"], "station", "dump")[1].splitlines():
        m = re.match(r"Station ([0-9a-f:]{17})", ln)
        if m: cur = res.setdefault(m.group(1), {}); continue
        if cur is None: continue
        for k, rx in (("signal", r"signal:\s+(-?\d+)"), ("connected_s", r"connected time:\s+(\d+)")):
            m = re.search(rx, ln)
            if m: cur[k] = int(m.group(1))
    return res

def vendors(macs):
    want = {m[:8].replace(":", "-").upper(): m for m in macs}; out = {}
    try:
        for ln in open(C["oui"], errors="ignore"):
            if "(hex)" in ln and ln[:8] in want: out[want[ln[:8]]] = ln.split("(hex)")[1].strip()
    except OSError: pass
    return out

def guess_os(host, vendor, ttl):
    h, v = host.lower(), vendor.lower()
    for pat, n in HINTS:
        if re.search(pat, h): return n
    if "apple" in v: return "Apple (iOS/macOS)"
    if any(k in v for k in ("samsung", "xiaomi", "huawei", "oppo", "vivo", "realme", "oneplus")): return "Android"
    if "microsoft" in v or "intel" in v: return "Windows/PC"
    if ttl and 60 <= ttl <= 70: return "Linux/Android?"
    if ttl and 120 <= ttl <= 130: return "Windows?"
    return "Unknown"

HINTS = [
    (r"iphone|ipad|ipod|macbook|imac", "Apple"),
    (r"android|galaxy|pixel|redmi|poco", "Android"),
    (r"windows|desktop|laptop", "Windows"),
    (r"linux|ubuntu|debian|raspberry", "Linux"),
]

PRESETS = {
    "social": ["facebook.com", "instagram.com", "twitter.com", "x.com", "tiktok.com", "snapchat.com", "linkedin.com"],
    "video": ["youtube.com", "netflix.com", "twitch.tv", "vimeo.com", "dailymotion.com"],
    "gaming": ["steamcommunity.com", "steampowered.com", "epicgames.com", "riotgames.com", "battle.net"],
    "ads": ["doubleclick.net", "googlesyndication.com", "adservice.google.com", "adnxs.com", "advertising.com"],
}

def devices():
    le, st, s = leases(), stations(), state()
    macs = set(le) | set(st) | set(s["blocked_macs"]) | set(s["allowed_macs"]) | set(s["names"])
    vend = vendors(macs)
    out = []
    for m in sorted(macs):
        d = {"mac": m, "ip": le.get(m, {}).get("ip", ""), "hostname": le.get(m, {}).get("hostname", ""),
             "vendor": vend.get(m, ""), "signal": st.get(m, {}).get("signal"),
             "connected_s": st.get(m, {}).get("connected_s"), "name": s["names"].get(m, ""),
             "blocked": m in s["blocked_macs"], "allowed": m in s["allowed_macs"]}
        d["os"] = guess_os(d["hostname"] or d["name"], d["vendor"], None)
        out.append(d)
    return out

# ---------- DNS / blocking ----------
def write_dnsmasq(s):
    lines = ["# managed by hotspot-manager", "log-queries", "log-facility=" + C["dns_log"]]
    for d in sorted(blocked_set(s)):
        lines.append(f"address=/{d}/")
    for d, t in s["redirects"].items():
        lines.append(f"address=/{d}/{t}")
    os.makedirs(os.path.dirname(C["dnsmasq_conf"]), exist_ok=True)
    open(C["dnsmasq_conf"], "w").write("\n".join(lines) + "\n")

def dns_status():
    if not os.path.exists(C["dnsmasq_conf"]): return False, "Config missing"
    return True, "OK"

def dns_query(name, server, port=53):
    # minimal A query
    q = struct.pack(">HHHHHH", random.randint(0, 65535), 0x0100, 1, 0, 0, 0)
    q += b"".join(bytes([len(x)]) + x.encode() for x in name.split(".")) + b"\0" + struct.pack(">HH", 1, 1)
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.settimeout(2)
    try:
        s.sendto(q, (server, port)); r = s.recv(512)
    except OSError: return None
    finally: s.close()
    return {"rcode": r[3] & 15, "answers": struct.unpack(">H", r[6:8])[0]}

def recent_counts(sec=600):
    now, c = datetime.now(), Counter()
    rx = re.compile(r"^(\w{3}\s+\d+ [\d:]{8}) dnsmasq\[\d+\]: query\[\w+\] \S+ from (\S+)")
    try: lines = deque(open(C["dns_log"], errors="ignore"), maxlen=20000)
    except OSError: return c
    for ln in reversed(lines):
        m = rx.match(ln)
        if not m: continue
        try: t = datetime.strptime(f"{now.year} {m.group(1)}", "%Y %b %d %H:%M:%S")
        except ValueError: continue
        if t > now: t = t.replace(year=now.year - 1)
        if (now - t).total_seconds() > sec: break
        c[m.group(2)] += 1
    return c

def diagnose():
    s, chk = state(), []
    add = lambda ok, title, detail="": chk.append({"ok": ok, "title": title, "detail": detail})
    ready, why = dns_status(); add(ready, "Hotspot DNS has the latest settings", why)
    r = re.search(r"inet (\S+)/", sh("ip", "-4", "-o", "addr", "show", "dev", C["ap_iface"])[1]); rip = r.group(1) if r else ""
    blk = sorted(blocked_set(s))
    if not blk: add(False, "Block test", "Block a site or app first, then run this check again.")
    elif not rip: add(False, "Block test", f"No IP address found on {C['ap_iface']}. Is the hotspot on?")
    else:
        res = dns_query(blk[0], rip, int(C.get("dns_port", 53)))
        if res is None: add(False, f"Test lookup of {blk[0]}", f"No answer from the hotspot DNS at {rip}.")
        else:
            good = res["rcode"] != 0 or res["answers"] == 0
            add(good, f"Test lookup of {blk[0]} is blocked",
                "" if good else "The hotspot DNS still answers normally, so it has not loaded the block list. Use Restart hotspot.")
    nat = ipt("-t", "nat", "-S", "HS_NAT")[1]
    add("REDIRECT" in nat, "Devices with their own DNS server are redirected to the hotspot",
        "" if "REDIRECT" in nat else "Devices set to a custom DNS server (for example 8.8.8.8) can skip blocks.")
    cnt = recent_counts()
    add(sum(cnt.values()) > 0, "Website lookups are being logged", "" if cnt else "No lookups in the last 10 minutes. Browse on a device, or restart the hotspot so logging starts.")
    return {"ok": True, "checks": chk}

def apply():
    s = state()
    write_dnsmasq(s)
    # iptables rules for MAC block / allow and DNS redirect
    ipt("-t", "nat", "-N", "HS_NAT") or True
    ipt("-t", "filter", "-N", "HS_FWD") or True
    ipt("-t", "nat", "-F", "HS_NAT")
    ipt("-t", "filter", "-F", "HS_FWD")
    # DNS redirect so clients using 8.8.8.8 still hit our dnsmasq
    rip = re.search(r"inet (\S+)/", sh("ip", "-4", "-o", "addr", "show", "dev", C["ap_iface"])[1])
    if rip:
        ip = rip.group(1)
        ipt("-t", "nat", "-A", "HS_NAT", "-p", "udp", "--dport", "53", "-j", "REDIRECT", "--to-ports", str(C.get("dns_port", 53)))
        ipt("-t", "nat", "-A", "HS_NAT", "-p", "tcp", "--dport", "53", "-j", "REDIRECT", "--to-ports", str(C.get("dns_port", 53)))
    for m in s["blocked_macs"]:
        ipt("-t", "filter", "-A", "HS_FWD", "-m", "mac", "--mac-source", m, "-j", "DROP")
    # ensure chains are hooked (idempotent)
    if "HS_NAT" not in ipt("-t", "nat", "-S", "PREROUTING")[1]:
        ipt("-t", "nat", "-I", "PREROUTING", "-i", C["ap_iface"], "-j", "HS_NAT")
    if "HS_FWD" not in ipt("-t", "filter", "-S", "FORWARD")[1]:
        ipt("-t", "filter", "-I", "FORWARD", "-i", C["ap_iface"], "-j", "HS_FWD")
    # reload dnsmasq if possible
    sh("pkill", "-HUP", "dnsmasq")
    return {"ok": True}

def restart_hotspot():
    # best-effort: find shared connection and bounce it
    out = sh("nmcli", "-t", "-f", "NAME,DEVICE", "con", "show", "--active")[1]
    for ln in out.splitlines():
        if ":" not in ln: continue
        name, dev = ln.split(":", 1)
        if sh("nmcli", "-g", "ipv4.method", "con", "show", name)[1].strip() == "shared":
            sh("nmcli", "con", "down", name)
            time.sleep(1)
            sh("nmcli", "con", "up", name, "ifname", dev or C["ap_iface"])
            apply()
            return {"ok": True, "connection": name}
    return {"ok": False, "error": "No shared NetworkManager connection found"}

# ---------- command dispatch ----------
def main():
    if len(sys.argv) < 2:
        print(json.dumps({"ok": False, "error": "No action"})); return
    a = sys.argv[1]
    args = sys.argv[2:]
    s = state()
    try:
        if a == "overview":
            print(json.dumps({"ok": True, "devices": devices(), "state": s}))
        elif a == "state":
            print(json.dumps({"ok": True, "state": s}))
        elif a == "logs":
            # simple recent DNS log lines
            try:
                lines = deque(open(C["dns_log"], errors="ignore"), maxlen=500)
                print(json.dumps({"ok": True, "lines": list(lines)[-100:]}))
            except OSError:
                print(json.dumps({"ok": True, "lines": []}))
        elif a == "apply":
            print(json.dumps(apply()))
        elif a == "restart-hotspot":
            print(json.dumps(restart_hotspot()))
        elif a == "diagnose":
            print(json.dumps(diagnose()))
        elif a == "block-domain":
            d = dom(args[0]); s["blocked_domains"] = sorted(set(s["blocked_domains"]) | {d}); save(C["state"], s); print(json.dumps(apply()))
        elif a == "unblock-domain":
            d = dom(args[0]); s["blocked_domains"] = [x for x in s["blocked_domains"] if x != d]; save(C["state"], s); print(json.dumps(apply()))
        elif a == "redirect":
            d, t = dom(args[0]), args[1]; s["redirects"][d] = t; save(C["state"], s); print(json.dumps(apply()))
        elif a == "unredirect":
            d = dom(args[0]); s["redirects"].pop(d, None); save(C["state"], s); print(json.dumps(apply()))
        elif a == "block-mac":
            m = mac(args[0]); s["blocked_macs"] = sorted(set(s["blocked_macs"]) | {m}); s["allowed_macs"] = [x for x in s["allowed_macs"] if x != m]; save(C["state"], s); print(json.dumps(apply()))
        elif a == "unblock-mac":
            m = mac(args[0]); s["blocked_macs"] = [x for x in s["blocked_macs"] if x != m]; save(C["state"], s); print(json.dumps(apply()))
        elif a == "allow-mac":
            m = mac(args[0]); s["allowed_macs"] = sorted(set(s["allowed_macs"]) | {m}); s["blocked_macs"] = [x for x in s["blocked_macs"] if x != m]; save(C["state"], s); print(json.dumps(apply()))
        elif a == "disallow-mac":
            m = mac(args[0]); s["allowed_macs"] = [x for x in s["allowed_macs"] if x != m]; save(C["state"], s); print(json.dumps(apply()))
        elif a == "kick":
            m = mac(args[0]); sh("iw", "dev", C["ap_iface"], "station", "del", m); print(json.dumps({"ok": True}))
        elif a == "rename":
            m, n = mac(args[0]), args[1][:40]; s["names"][m] = n; save(C["state"], s); print(json.dumps({"ok": True}))
        elif a == "preset":
            name, on = args[0], args[1] == "1"
            if on and name not in s["presets"]: s["presets"].append(name)
            if not on: s["presets"] = [x for x in s["presets"] if x != name]
            save(C["state"], s); print(json.dumps(apply()))
        elif a == "mode":
            s["mode"] = args[0] if args[0] in ("open", "allowlist") else "open"; save(C["state"], s); print(json.dumps(apply()))
        else:
            print(json.dumps({"ok": False, "error": "Unknown action"}))
    except Exception as e:
        print(json.dumps({"ok": False, "error": str(e)}))

if __name__ == "__main__":
    main()
