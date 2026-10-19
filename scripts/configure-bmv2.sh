#!/usr/bin/env bash
set -euo pipefail

mkdir -p /etc/bmv2

cat >/etc/bmv2/bmv2.env <<'EOF'
# P4Runtime gRPC listen address.
BMV2_GRPC_SERVER_ADDR="0.0.0.0:9559"

# Standard v1model CPU port. Change per experiment if necessary.
BMV2_CPU_PORT="255"
EOF

cat >/etc/bmv2/ports <<'EOF'
# One mapping per line:
#
#   <BMv2-port>@<Linux-interface>
#
# Example:
#   1@ens19
#   2@ens20
#   3@ens21
#
# Keep the management interface (usually ens18) out of this file.
EOF

cat >/usr/local/sbin/bmv2-run <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

source /etc/bmv2/bmv2.env

args=(--no-p4)

while IFS= read -r port; do
  [[ -z "$port" ]] && continue
  [[ "$port" =~ ^[[:space:]]*# ]] && continue
  args+=( -i "$port" )
done < /etc/bmv2/ports

exec /usr/local/bin/simple_switch_grpc \
  "${args[@]}" \
  -- \
  --grpc-server-addr="${BMV2_GRPC_SERVER_ADDR}" \
  --cpu-port="${BMV2_CPU_PORT}"
EOF

chmod 0755 /usr/local/sbin/bmv2-run

cat >/etc/systemd/system/bmv2.service <<'EOF'
[Unit]
Description=BMv2 simple_switch_grpc
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
EnvironmentFile=/etc/bmv2/bmv2.env
ExecStart=/usr/local/sbin/bmv2-run
Restart=on-failure
RestartSec=2
LimitNOFILE=65536

# BMv2 opens packet sockets and interacts with network interfaces.
AmbientCapabilities=CAP_NET_RAW CAP_NET_ADMIN
CapabilityBoundingSet=CAP_NET_RAW CAP_NET_ADMIN
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl disable bmv2.service >/dev/null 2>&1 || true
systemctl stop bmv2.service >/dev/null 2>&1 || true

cat >/etc/bmv2/VERSION <<'EOF'
BMv2 commit: 0bf80968bbd533e5bb58f849743001ae8221b715
PI commit:   04bf8ac8a0c00cd8a663f1f936fdaadc8b7a658c
EOF
