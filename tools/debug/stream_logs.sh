#!/usr/bin/env bash
# Runs ON THE LAPTOP (Linux, macOS, WSL2 or Git Bash on Windows).
# Streams kernel log, system journal and the Pi power monitor from the robot computer
# over SSH into ./logs/remote_<timestamp>/ on the laptop. Because the data is written on
# the laptop, it survives the robot computer losing power.
#
#   ./tools/debug/stream_logs.sh [user@host]
#
# Requires: SSH key login to the robot (ssh-copy-id), sudo without password for dmesg/journalctl
# or run as a user in the adm/systemd-journal groups.
set -u
cd "$(dirname "$0")/../.."
[ -f .env ] && set -a && . ./.env && set +a
TARGET=${1:-${ROBOT_USER:-pi}@${ROBOT_HOST:-raspberrypi.local}}
OUT="logs/remote_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT"
SSH="ssh -o ServerAliveInterval=1 -o ServerAliveCountMax=3 -o ConnectTimeout=5 $TARGET"

echo "Streaming from $TARGET into $OUT  (Ctrl+C to stop)"
scp -q tools/debug/pi_power_monitor.sh "$TARGET:/tmp/pi_power_monitor.sh" 2>/dev/null || true

stamp() { while IFS= read -r l; do printf '%s %s\n' "$(date +%H:%M:%S.%3N)" "$l"; done; }

$SSH "sudo dmesg -w -T"                  2>&1 | stamp > "$OUT/dmesg.log"   &
$SSH "journalctl -f -o short-precise"    2>&1 | stamp > "$OUT/journal.log" &
$SSH "bash /tmp/pi_power_monitor.sh 0.1" 2>&1        > "$OUT/power.csv"   &

# Connection watchdog: records the exact moment the robot stops answering.
(
  while true; do
    if ping -c1 -W1 "${TARGET#*@}" >/dev/null 2>&1; then s=UP; else s=DOWN; fi
    echo "$(date +%H:%M:%S.%3N) $s"
    sleep 0.5
  done
) > "$OUT/ping.log" &

trap 'kill $(jobs -p) 2>/dev/null; echo; echo "Saved in $OUT"' INT TERM
tail -f "$OUT/power.csv"
