# IDS/IPS Lab — "LightSensor" (Suricata)

**Purpose:** a compact, reproducible IDS/IPS lab using Suricata suitable for a low-resource VirtualBox host (≤5GB RAM). This README is ready to drop into a GitHub repository and contains architecture diagrams, installation and configuration steps, example rules, a bash script to install and enable Suricata + local rules, attack simulation steps, and how to view alerts.

---

## Table of contents

1. Overview & objectives
2. Introduction to IDS vs IPS
3. Architecture and network diagrams
4. Repository structure
5. Quick start (Get started)
6. Install Ubuntu Server & prerequisites
7. Suricata installation & configuration (with script)
8. Example local rules (nmap, sqlmap, ICMP flood, SSH, HTTP exploit)
9. Simulate attacks from your PC and expected alerts
10. Viewing & parsing alerts
11. Troubleshooting and tips
12. Next steps / extensions

---

## 1. Overview & objectives

This lab — **LightSensor** — demonstrates how to deploy a lightweight Suricata-based IDS/IPS sensor, add local rules to detect common network attacks (port scans, ICMP floods, SQL-injection tool user-agents, brute-force attempts, simple exploit URIs), and how to run attacks from an attacker machine (your PC) to trigger and examine alerts.

Objectives:

* Build a reproducible lab you can share on GitHub.
* Configure Suricata as an IDS (pcap mode) and optionally as an IPS (inline/NFQUEUE) for blocking tests.
* Add local rules tailored for lab testing (nmap scans, sqlmap user-agent, ICMP floods, etc.).
* Run scripted attacks from your PC and collect/parse alerts from `/var/log/suricata/eve.json`.

Target audience: cybersecurity students, pentesters, engineers learning network detection.

---

## 2. Introduction to IDS vs IPS (short)

* **IDS (Intrusion Detection System):** monitors network traffic and **alerts** on suspicious patterns. Typically passive (pcap mode).
* **IPS (Intrusion Prevention System):** sits inline and can **drop/modify** traffic based on rules (requires inline mode such as NFQUEUE/AF_PACKET). More disruptive and requires careful deployment.

This lab focuses on IDS (pcap) for safety and resource constraints, with notes for running IPS inline if you want to test blocking.

---

## 3. Architecture and network diagrams

Below are diagrams you can include in the repo. Save image files under `/docs/images/` if you want to show them in GitHub Pages or the repo viewer. I include ASCII diagrams that work in plain README and references to suggested PNG/SVG filenames.

### 3.1 Simple lab topology (single VirtualBox host)

```
[Host (VirtualBox) — int-net-lab]
    |-- IDS VM (Ubuntu + Suricata)   IP: 10.0.0.10    (2GB RAM)
    |-- Victim VM (Ubuntu + nginx)   IP: 10.0.0.20    (1GB RAM)
    |-- Attacker (your PC / VM)      IP: 10.0.0.30    (1GB RAM)
```

Markdown image placeholder (add this file to `/docs/images/lab-topology.png`):

`![Lab Topology](/docs/images/lab-topology.png "LightSensor lab topology")`

### 3.2 Enterprise placement (how IDS/IPS fits into enterprise network)

ASCII representation for README:

```
Internet --> Perimeter Firewall --> Network Edge Switch --> [IDS/IPS Sensor (SPAN/port-mirror) placed on monitoring port]
                                           |--> Internal VLANs / Servers / Workstations
                                           |--> DMZ (web/mail)

- IDS Sniffs mirrored traffic from edge/core switch.
- IPS (if inline) sits on the traffic path between firewall and internal network or in front of DMZ.
```

Markdown image placeholder: `/docs/images/enterprise-placement.png`

### 3.3 How we use IDS vs IPS in enterprise

* **IDS (monitoring):** Tap or SPAN port — passive monitoring for detection and investigation.
* **IPS (prevention):** Inline device or NSM function — blocks traffic (use only after rigorous testing).

Add sample images to `/docs/images/ids-vs-ips-diagram.png` if desired.

---

## 4. Repository structure (recommended)

```
LightSensor/                      # repo root
├─ README.md                       # this document
├─ LICENSE
├─ configs/
│   └─ suricata/
│       ├─ suricata.yaml           # minimal/edited, eve-log enabled
│       └─ local.rules             # local rules (nmap, sqlmap, icmp, etc.)
├─ scripts/
│   ├─ setup_ids.sh                # install & copy configs + start instructions
│   └─ tests/
│       ├─ icmp_flood.sh
│       ├─ nmap_scan.sh
│       └─ http_sql_injection.py
├─ docs/
│   └─ images/                     # add the PNG/SVG diagrams here
└─ docs/lab-guide.md               # extended step-by-step guide (optional)
```

---

## 5. Quick start (get started)

1. Clone this repo to your IDS VM: `git clone https://github.com/<your>/LightSensor.git`
2. On the IDS VM, run the setup script:

```bash
cd LightSensor
chmod +x scripts/setup_ids.sh
sudo ./scripts/setup_ids.sh
```

3. Start Suricata (see `setup_ids.sh` output for exact command). Ensure the interface name (`eth0`, `ens3`, etc.) is correct.
4. From your PC (attacker), run one of the test scripts in `scripts/tests/` to trigger alerts.
5. On the IDS VM, parse alerts using the provided `scripts/parse_alerts.py` (or `jq` commands shown below).

---

## 6. Install Ubuntu Server & prerequisites

Use Ubuntu Server 22.04 LTS (or 20.04). Minimal install options save resources. Assign VM RAM as described in repo docs.

### Basic OS steps (run on IDS VM):

```bash
# update
sudo apt update && sudo apt -y upgrade
# install required packages
sudo apt -y install suricata jq tcpdump python3-pip git
# python deps for tests
python3 -m pip install --user requests
```

If `suricata` from the distro is out-of-date and you need the latest, consider adding the official "suricata-ids" repository — instructions vary by Ubuntu version. The packaged `suricata` is sufficient for the lab.

---

## 7. Suricata installation & configuration (script)

Place the following script at `scripts/setup_ids.sh`. It will install Suricata and copy the `configs/suricata/*` files to the appropriate system locations.

```bash
#!/bin/bash
set -e

# Basic installer for lab (Ubuntu 22.04+)
# Run as a user with sudo privileges

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)"; exit 1
fi

apt update && apt -y upgrade
apt -y install suricata jq tcpdump python3-pip libnetfilter-queue-dev
python3 -m pip install requests --upgrade

# Ensure config paths exist
mkdir -p /etc/suricata/rules
mkdir -p /var/log/suricata

# Copy files from repo (assumes running from repo root)
cp configs/suricata/suricata.yaml /etc/suricata/suricata.yaml
cp configs/suricata/local.rules /etc/suricata/rules/local.rules

# Fix ownership for logs
chown -R $(logname):$(logname) /var/log/suricata

# Print next steps (do not automatically start in case interface differs)
cat <<EOF
Suricata configured. Next steps:
1) Identify your interface name: ip a
2) Start Suricata (IDS/pcap mode):
   sudo suricata -c /etc/suricata/suricata.yaml -i <interface>
3) To run inline/IPS (advanced): configure iptables NFQUEUE on the gateway and run suricata in --af-packet or --nfqueue mode.
EOF

exit 0
```

> Save this file and mark it executable: `chmod +x scripts/setup_ids.sh`.

---

## 8. Example local rules (configs/suricata/local.rules)

Create the following `local.rules` in `configs/suricata/local.rules`. These are intentionally simple, lab-focused signatures and are not comprehensive production rules.

```text
# Local lab signatures (SIDs in 1000000+ range)

# 1) Detect HTTP requests with known SQLMap User-Agent
alert http any any -> any any (msg:"HTTP Suspicious User-Agent: sqlmap"; http_user_agent; content:"sqlmap"; sid:1000001; rev:1;)

# 2) Detect fast ICMP bursts (simple threshold)
alert icmp any any -> any any (msg:"ICMP flood - lab detection"; detection_filter: track by_src, count 20, seconds 2; sid:1000003; rev:1;)

# 3) Detect SSH connection attempts to server (simple)
alert tcp any any -> any 22 (msg:"SSH connection attempt"; flow:to_server,established; sid:1000002; rev:1;)

# 4) Detect HTTP GET to /evil.php (example exploit URI)
alert http any any -> any any (msg:"HTTP GET /evil.php detected"; http_uri; content:"/evil.php"; sid:1000004; rev:1;)

# 5) Detect large number of TCP SYNs (scan-like behaviour)
alert tcp any any -> any any (msg:"Possible TCP Scan (many SYNs)"; flags:S; detection_filter: track by_src, count 50, seconds 10; sid:1000005; rev:1;)

# 6) Detect common web scanner signature (nmap user-agent or nmap TCP ping)
alert tcp any any -> any any (msg:"Possible Nmap Probe"; content:"User-Agent: Nmap"; nocase; sid:1000006; rev:1;)
```

Notes:

* The `detection_filter` is a simple way to reduce false positives in lab conditions.
* `drop` actions should only be used when running Suricata inline — here we use `alert` to keep the lab safe.

---

## 9. Simulate attacks from your PC and expected alerts

Run the following from your attacker PC (or Attacker VM). Replace IPs with your lab addresses (`10.0.0.10` IDS, `10.0.0.20` victim).

### 9.1 ICMP burst (hping3)

```bash
sudo apt -y install hping3
hping3 --icmp -i u1000 -c 200 10.0.0.20
```

Expected alert: `ICMP flood - lab detection` (sid:1000003)

### 9.2 Nmap scan

```bash
sudo apt -y install nmap
nmap -sS -p- --min-rate=200 10.0.0.20
```

Expected alert: `Possible TCP Scan (many SYNs)` and/or `Possible Nmap Probe` depending on how nmap behaves (user-agent, probe type).

### 9.3 SQLMap user-agent trigger (curl or python)

```bash
# curl
curl -A "sqlmap/1.6.7" http://10.0.0.20/

# or python
python3 -c "import requests; print(requests.get('http://10.0.0.20/', headers={'User-Agent':'sqlmap/1.6.7'}).status_code)"
```

Expected alert: `HTTP Suspicious User-Agent: sqlmap` (sid:1000001)

### 9.4 HTTP exploit URI

```bash
curl http://10.0.0.20/evil.php
```

Expected alert: `HTTP GET /evil.php detected` (sid:1000004)

---

## 10. Viewing & parsing alerts

### 10.1 Quick tail (raw JSON)

```bash
sudo tail -f /var/log/suricata/eve.json
```

### 10.2 Use `jq` to show only alerts in compact form

```bash
sudo tail -f /var/log/suricata/eve.json | jq -c 'select(.event_type=="alert") | {time:.timestamp, src:.src_ip, dst:.dest_ip, sig:.alert.signature} '
```

### 10.3 Human-friendly Python parser (scripts/parse_alerts.py)

Create `scripts/parse_alerts.py` with the following:

```python
#!/usr/bin/env python3
import json
fn = '/var/log/suricata/eve.json'
try:
    with open(fn) as f:
        for line in f:
            try:
                ev = json.loads(line)
            except:
                continue
            if ev.get('event_type') == 'alert':
                ts = ev.get('timestamp','')
                src = ev.get('src_ip','')+ ':' + str(ev.get('src_port',''))
                dst = ev.get('dest_ip','')+ ':' + str(ev.get('dest_port',''))
                sig = ev['alert'].get('signature','')
                sid = ev['alert'].get('signature_id','')
                print(f"{ts} | {src} -> {dst} | {sig} (sid:{sid})")
except FileNotFoundError:
    print('eve.json not found at /var/log/suricata/eve.json')
```

Run:

```bash
python3 scripts/parse_alerts.py | tail -n 50
```

---

## 11. Troubleshooting & tips

* **No alerts:** confirm rules loaded (`/etc/suricata/suricata.yaml` includes `local.rules`) and check `/var/log/suricata/suricata.log` for errors.
* **Interface mismatch:** run `ip a` to see the interface name; update the start command.
* **Traffic not reaching IDS:** run `tcpdump -i <iface> host <attacker-ip>` to verify.
* **High resource use:** reduce attack rate or use pcap replay to test offline (`suricata -r sample.pcap -c /etc/suricata/suricata.yaml`).
* **Inline/IPS mode:** test in a controlled environment only; block rules (`drop`) can interrupt services.

---

## 12. Next steps / extensions

* Add a lightweight ELK alternative (e.g., *mtail + graylog* or just filebeat -> local Elasticsearch) if you want dashboards (note: heavy).
* Compare Suricata vs Snort by adding a Snort container and running both sensors on the same traffic.
* Automate VM provisioning with Vagrant or Terraform & libvirt/VirtualBox.
* Add PCAP captures of attacks under `/tests/pcaps/` for reproducible offline testing.

---

### License & credits

© Your Name — adapt and reuse. Consider Apache-2.0 or MIT for open-source sharing.

---

*Ready:* I created this `README.md` for your repo. Next I can (choose one):

* Generate the **actual files** (`configs/suricata/suricata.yaml`, `local.rules`, `scripts/setup_ids.sh`, `scripts/parse_alerts.py`, test scripts) as individual files in the repo canvas, or
* Produce a **Docker Compose** alternative to run everything on a single host (lighter than separate VMs), or
* Prepare PNG/SVG diagrams for the `docs/images/` folder (I can create simple SVG diagrams you can add).

Tell me which next step you want and I will create the files directly in the repo document space.
