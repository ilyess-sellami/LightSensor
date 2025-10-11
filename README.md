# LightSensor - Suricata IDS/IPS

---

## Table of contents

1. Overview & objectives
2. Introduction to IDS vs IPS (short)
3. Architecture and network diagrams
4. Prerequisites (IDS VM + attacker PC)
5. Install & configure the IDS (one command)
6. Start Suricata (IDS mode)
7. Run attack scripts from your PC (how & examples)
8. View & parse alerts on the IDS VM
9. Conclusion

---

## 1 - Overview & objectives 

This lab — **LightSensor** — demonstrates how to **deploy a lightweight Suricata-based IDS/IPS sensor**, add local rules to **detect common network attacks** (port scans, ICMP floods, SQL-injection tool user-agents, brute-force attempts, simple exploit URIs), and how to **run attacks from an attacker machine** to trigger and examine alerts.

Objectives:

- Build a reproducible lab you can share on GitHub.
- Configure Suricata as an IDS (pcap mode) and optionally as an IPS (inline/NFQUEUE) for blocking tests.
- Add local rules tailored for lab testing (nmap scans, sqlmap user-agent, ICMP floods, etc.).
- Run scripted attacks from your PC and collect/parse alerts from `/var/log/suricata/eve.json`.

Target audience: cybersecurity students, pentesters, engineers learning network detection.

---

## 2 — Introduction to IDS vs IPS (short)

- **IDS (Intrusion Detection System):** passive—sniffs traffic and **alerts** when rules match suspicious patterns (pcap mode). Good for detection and investigation.

- **IPS (Intrusion Prevention System):** inline—can **drop** or modify packets when rules match (NFQUEUE/AF_PACKET). Blocks traffic but can disrupt services if misconfigured.

This lab focuses on IDS (pcap) for safety and resource constraints, with notes for running IPS inline if you want to test blocking.

---

## 3 — Architecture and network diagrams

### 3.1 - Simple lab topology
```pgsql
[Host machine / VirtualBox]
  ├─ IDS VM (Ubuntu + Suricata)    IP: 10.0.0.10  (recommended 2GB RAM)
  ├─ Victim VM (nginx test server) IP: 10.0.0.20  (1GB)
  └─ Attacker (your PC or VM)      IP: 10.0.0.30  (your machine)
All connected on internal network (e.g., int-net-lab) or host-only network.
```

### 3.2 - Enterprise placement (how IDS/IPS fits into enterprise network)

#### Network Architecture Example with IDS:

![Network Architecture Example with IDS](/images/Network-Architecture-Example-with-IDS.png)

#### Network Architecture Example with IPS:

![Network Architecture Example with IPS](/images/Network-Architecture-Example-with-IPS.png)

### 3.3 - How we use IDS vs IPS in enterprise

- **IDS (monitoring):** Tap or SPAN port — passive monitoring for detection and investigation.

- **IPS (prevention):** Inline device or NSM function — blocks traffic (use only after rigorous testing).

![IDS vs IPS](/images/IDS-vs-IPS.jpeg)

---

## 4 — Prerequisites

**On the IDS VM (Ubuntu 20.04/22.04+)**

- sudo/root user
- `suricata`, `jq`, `tcpdump`, `python3-pip` installed (the `setup_ids.sh` script installs them)
- The repo cloned on the IDS VM (or transfer configs/ into the VM)

**On the attacker PC (Linux/macOS/Windows WSL)**

- `nmap`, `hping3`, `curl`, `python3` (install as needed)
- Ensure attacker can reach victim IPs in the lab network

 **Note:** run attack scripts from the attacker PC (not on the IDS VM) unless explicitly directed.

---

## 5 — Install & configure the IDS (one command)

1. Clone your repo on the IDS VM:

```bash
git clone https://github.com/ilyess-sellami/LightSensor
cd LightSensor
```

2. Run the setup script as root:

```bash
chmod +x ./scripts/setup_ids.sh
sudo ./scripts/setup_ids.sh
```

This script installs packages, creates necessary directories, and copies `configs/suricata/*` to `/etc/suricata/` and `/etc/suricata/rules/`.

3. Identify your interface name:

```bash
ip a
```

4. Start Suricata (IDS/pcap mode):

```bash
sudo suricata -c /etc/suricata/suricata.yaml -i <interface>
```

---

## 6 — Start Suricata (IDS / pcap mode)

1. Identify your network interface:

```bash
ip a
```

2. Start Suricata on the interface that sees lab traffic (example `eth0`, replace as needed):

```bash
sudo suricata -c /etc/suricata/suricata.yaml -i eth0
```

- To daemonize, add `-D`.
- Suricata logs: `/var/log/suricata/suricata.log` and `/var/log/suricata/eve.json`.

---

## 7 — Run attack scripts from your attacker machine

Make test scripts executable if needed on attacker:

```bash
chmod +x scripts/tests/*.sh
chmod +x scripts/tests/*.py
```

Replace `10.0.0.20` below with your victim IP.

### 7.1 - ICMP burst (hping3)

```bash
# from attacker machine
./scripts/tests/icmp_flood.sh 10.0.0.20 200 u1000
```

### 7.2 - Nmap SYN scan

```bash
# from attacker machine
./scripts/tests/nmap_scan.sh 10.0.0.20 200
```

### 7.3 - HTTP request with sqlmap user-agent

```bash
# from attacker machine (python)
./scripts/tests/http_sql_injection.py http://10.0.0.20/
```

### 7.4 - HTTP GET /evil.php

```bash
# from attacker machine
./scripts/tests/http_evil_get.sh http://10.0.0.20/evil.php
```

Allow a few seconds after each test for Suricata to log events.

---

## 8 — View & parse alerts on IDS VM

### 8.1 - Quick raw tail (live JSON)

```bash
sudo tail -f /var/log/suricata/eve.json
```

### 8.2 - Use `jq` to show only alerts in compact form

```bash
sudo tail -f /var/log/suricata/eve.json | jq -c 'select(.event_type=="alert") | {time:.timestamp, src:.src_ip, dst:.dest_ip, sig:.alert.signature}'
```

### 8.3 - Use the provided parser for prettier lines

```bash
python3 scripts/parse_alerts.py | tail -n 50
```

---

## 9 - Conclusion

The LightSensor lab shows how to deploy and operate a Suricata-based IDS/IPS in a low-resource environment. You learned how to configure detection rules, simulate attacks, and analyze alerts in real time. This setup provides a practical understanding of intrusion detection and prevention, while also serving as a foundation for more advanced network security experiments and enterprise-grade monitoring scenarios.
