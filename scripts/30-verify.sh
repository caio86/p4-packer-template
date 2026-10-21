#!/bin/sh
set -eux

command -v p4c
command -v p4c-bm2-ss
command -v simple_switch
command -v simple_switch_CLI

p4c --version

WORK=$(mktemp -d)
cat > "$WORK/smoke.p4" <<'EOF'
#include <core.p4>
#include <v1model.p4>

header ethernet_t { bit<48> dst; bit<48> src; bit<16> type; }
struct headers { ethernet_t eth; }
struct metadata { }

parser P(packet_in pkt, out headers h, inout metadata m, inout standard_metadata_t s) {
    state start { pkt.extract(h.eth); transition accept; }
}
control VC(inout headers h, inout metadata m) { apply { } }
control Ing(inout headers h, inout metadata m, inout standard_metadata_t s) {
    apply { s.egress_spec = s.ingress_port; }
}
control Egr(inout headers h, inout metadata m, inout standard_metadata_t s) { apply { } }
control CC(inout headers h, inout metadata m) { apply { } }
control D(packet_out pkt, in headers h) { apply { pkt.emit(h.eth); } }
V1Switch(P(), VC(), Ing(), Egr(), CC(), D()) main;
EOF

p4c-bm2-ss --p4v 16 -o "$WORK/smoke.json" "$WORK/smoke.p4"
test -s "$WORK/smoke.json"

simple_switch --version
rm -rf "$WORK"
