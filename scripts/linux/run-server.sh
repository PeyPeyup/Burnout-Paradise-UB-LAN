#!/usr/bin/env bash
# Starts the private Burnout Paradise server on Linux.
#   SERVER_IP=203.0.113.10 ./run-server.sh        (or: bash run-server.sh)
# SERVER_IP  = IPv4 address the GAME CLIENTS will connect to (required)
# MAX_USERS  = max simultaneous players (default 2; values above 2 are untested)
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"
: "${SERVER_IP:?Set SERVER_IP to the address clients will use, e.g. SERVER_IP=192.168.1.50}"
MAX_USERS="${MAX_USERS:-2}"
chmod +x ./MultiSocks 2>/dev/null || true
mkdir -p static
for n in otg3.cer otg3.key fesl.key; do cp -f "certs/$n" "static/private-$n"; done
cat > static/MultiSocks.json <<EOF
{
  "config_version": 4,
  "server_bind_address": "$SERVER_IP",
  "rpcs3_workarounds": false,
  "private_pair_mode": true,
  "private_max_users": $MAX_USERS,
  "enable_blaze_encryption": false,
  "dirtysocks_database_path": "$PWD/static/local-accounts.json",
  "servers": [
    { "type": "Aries", "subtype": "Redirector", "port": 21841, "target_ip": "$SERVER_IP", "target_port": 21842,
      "project": "BURNOUT5", "sku": "PC", "secure": true, "cn": "pcburnout08.ea.com" },
    { "type": "Aries", "subtype": "Matchmaker", "port": 21842, "listen_ip": "0.0.0.0", "project": "BURNOUT5", "sku": "PC" }
  ]
}
EOF
echo "Burnout private server on $SERVER_IP (TCP 21841/21842), max players $MAX_USERS. Ctrl+C to stop."
export DOTNET_RUNNING_IN_CONTAINER=true DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
exec ./MultiSocks