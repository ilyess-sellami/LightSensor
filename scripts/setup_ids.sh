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