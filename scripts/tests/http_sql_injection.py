#!/usr/bin/env python3
import sys
import requests

URL = sys.argv[1] if len(sys.argv) > 1 else "http://10.0.0.20/"

headers = {
    "User-Agent": "sqlmap/1.6.7"
}

try:
    r = requests.get(URL, headers=headers, timeout=5)
    print(f"{r.status_code} {r.reason} -> {URL}")
except Exception as e:
    print("Request failed:", e)
