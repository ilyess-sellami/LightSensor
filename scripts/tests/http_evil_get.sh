#!/bin/bash
set -e

TARGET=${1:-http://10.0.0.20/evil.php}

if ! command -v curl >/dev/null 2>&1; then
  echo "curl required. Install: sudo apt install curl"
  exit 1
fi

echo "Requesting $TARGET"
curl -i -s "$TARGET" || true
