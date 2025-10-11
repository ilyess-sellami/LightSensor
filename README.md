# IDS/IPS Lab — "LightSensor" (Suricata)

---

## Overview

LightSensor is a compact, reproducible lab showing how to deploy a Suricata IDS/IPS sensor, test it with common network attacks from an attacker machine, and inspect the alerts. This README explains what an IDS/IPS is, the lab topology, prerequisites, and exact commands to run the prepared scripts and view results.

 ⚠️ WARNING: Only run attacks in a controlled lab network you own. Do not attack systems you don’t own or have permission to test.

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

