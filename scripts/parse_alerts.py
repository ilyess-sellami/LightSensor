#!/usr/bin/env python3
import json
import os
fn = "/var/log/suricata/eve.json"

if not os.path.isfile(fn):
    print("eve.json not found at /var/log/suricata/eve.json")
    raise SystemExit(1)

with open(fn, 'r') as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            ev = json.loads(line)
        except Exception:
            continue
        if ev.get("event_type") == "alert":
            ts = ev.get("timestamp", "")
            src = f'{ev.get("src_ip","")}:{ev.get("src_port","")}'
            dst = f'{ev.get("dest_ip","")}:{ev.get("dest_port","")}'
            sig = ev.get("alert", {}).get("signature", "")
            sid = ev.get("alert", {}).get("signature_id", "")
            print(f"{ts} | {src} -> {dst} | {sig} (sid:{sid})")
