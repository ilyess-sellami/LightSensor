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
9. Mapping: tests → expected alerts (SIDs)
10. Troubleshooting & tips
11. Next steps & license

---

## 1 - Overview & objectives 

This lab — **LightSensor** — demonstrates how to deploy a lightweight Suricata-based IDS/IPS sensor, add local rules to detect common network attacks (port scans, ICMP floods, SQL-injection tool user-agents, brute-force attempts, simple exploit URIs), and how to run attacks from an attacker machine (your PC) to trigger and examine alerts.

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

#### Network Architecture Example with IDS

![Network Architecture Example with IDS](/images/Network-Architecture-Example-with-IDS.png)

#### Network Architecture Example with IPS

![Network Architecture Example with IPS](/images/Network-Architecture-Example-with-IPS.png)

### 3.3 How we use IDS vs IPS in enterprise

- **IDS (monitoring):** Tap or SPAN port — passive monitoring for detection and investigation.

- **IPS (prevention):** Inline device or NSM function — blocks traffic (use only after rigorous testing).

![IDS vs IPS](/images/IDS-vs-IPS.jpeg)

---

## 3 - 

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
sudo ./scripts/setup_ids.sh
```

This script installs packages, creates necessary directories, and copies `configs/suricata/*` to `/etc/suricata/` and `/etc/suricata/rules/`.

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

## 7 — Run attack scripts from your attacker machine

Make test scripts executable if needed on attacker:

```bash
chmod +x scripts/tests/*.sh
chmod +x scripts/tests/*.py
```

Replace `10.0.0.20` below with your victim IP.

