#!/bin/bash
# Runs tools/lan_run_test.tscn as a host and a client on this computer, on one clock, and compares the state each
# prints at the end. Run from infall-godot/:   tools/lan_run_test.sh [folder for the two logs]
cd "$(dirname "$0")/.."
out=${1:-tools/out/lan-run}
mkdir -p "$out"
export START_AT=$(($(date +%s) + 3))
ROLE=host timeout 90 godot --headless --path . tools/lan_run_test.tscn > "$out/host.txt" 2>&1 &
ROLE=client timeout 90 godot --headless --path . tools/lan_run_test.tscn > "$out/client.txt" 2>&1
wait
grep -h "PASS\|FAIL\|rejoined while" "$out/host.txt" "$out/client.txt"
host=$(grep "^STATE" "$out/host.txt"); client=$(grep "^STATE" "$out/client.txt")
echo "host:   $host"; echo "client: $client"
if [ -n "$host" ] && [ "$host" == "$client" ] && ! grep -q "FAIL" "$out/host.txt" "$out/client.txt"; then echo "LAN RUN: PASS"; else echo "LAN RUN: FAIL"; fi
