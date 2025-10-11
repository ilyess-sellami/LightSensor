# LightSensor - Suricata IDS/IPS

---

## Overview

**LightSensor** is a **compact, reproducible lab** showing how to **deploy a Suricata IDS/IPS sensor**, test it with common **network attacks** from an attacker machine, and **inspect the alerts**. This README explains what an IDS/IPS is, the lab topology, prerequisites, and exact commands to run the prepared scripts and view results.

 ⚠️ **WARNING:** Only run attacks in a controlled lab network you own. Do not attack systems you don’t own or have permission to test.

---

## Table of contents

1. What is IDS vs IPS?
2. Lab topology
3. Files you have (scripts & configs)
4. Prerequisites (IDS VM + attacker PC)
5. Install & configure the IDS (one command)
6. Start Suricata (IDS mode)
7. Run attack scripts from your PC (how & examples)
8. View & parse alerts on the IDS VM
9. Mapping: tests → expected alerts (SIDs)
10. Troubleshooting & tips
11. Next steps & license

---

## 1 — What is IDS vs IPS?

- **IDS (Intrusion Detection System):** passive—sniffs traffic and **alerts** when rules match suspicious patterns (pcap mode). Good for detection and investigation.

- **IPS (Intrusion Prevention System):** inline—can **drop** or modify packets when rules match (NFQUEUE/AF_PACKET). Blocks traffic but can disrupt services if misconfigured.

This lab uses **Suricata** as IDS by default (safer). We include notes for IPS/inline if you later want to test blocking.

---

## 2 — Lab topology

Single VirtualBox host or small lab network:

```pgsql
[Host machine / VirtualBox]
  ├─ IDS VM (Ubuntu + Suricata)    IP: 10.0.0.10  (recommended 2GB RAM)
  ├─ Victim VM (nginx test server) IP: 10.0.0.20  (1GB)
  └─ Attacker (your PC or VM)      IP: 10.0.0.30  (your machine)
All connected on internal network (e.g., int-net-lab) or host-only network.
```

Enterprise placement: IDS typically receives mirrored (SPAN) traffic from switches; IPS sits inline on a traffic path. This lab keeps it simple and local.

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

