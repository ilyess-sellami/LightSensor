#!/bin/bash
set -e

TARGET=${1:-10.0.0.20}   # default target
COUNT=${2:-200}         # number of packets
INTERVAL=${3:-u1000}    # microsecond interval (hping3 format)

if ! command -v hping3 >/dev/null 2>&1; then
  echo "hping3 required. Install: sudo apt install hping3"
  exit 1
fi

echo "Sending $COUNT ICMP packets to $TARGET (interval $INTERVAL)"
sudo hping3 --icmp -i $INTERVAL -c $COUNT "$TARGET"
