#!/bin/bash
set -e

TARGET=${1:-10.0.0.20}
MINRATE=${2:-200}

if ! command -v nmap >/dev/null 2>&1; then
  echo "nmap required. Install: sudo apt install nmap"
  exit 1
fi

echo "Running SYN scan on $TARGET (min-rate $MINRATE)"
sudo nmap -sS -p- --min-rate="$MINRATE" "$TARGET"
