#!/usr/bin/env bash
# Quick health check of the robot computer (host). Safe to run any time.
#   ./host/check_host.sh
set -u
ok()   { printf '  [OK]   %s\n' "$*"; }
warn() { printf '  [WARN] %s\n' "$*"; }
bad()  { printf '  [FAIL] %s\n' "$*"; }

echo "== System"
echo "  $(tr -d '\0' < /proc/device-tree/model 2>/dev/null || uname -n) | $(uname -m) | kernel $(uname -r)"
uname -v | grep -qi "PREEMPT_RT\|PREEMPT RT" && ok "real-time kernel" || warn "not a PREEMPT_RT kernel (fine for bench tests)"
[ "$(ulimit -r)" -ge 90 ] 2>/dev/null && ok "rtprio limit $(ulimit -r)" || warn "rtprio limit $(ulimit -r) (expected 98, see host/setup_host.sh)"
command -v docker >/dev/null && ok "docker $(docker --version | cut -d' ' -f3 | tr -d ,)" || bad "docker missing"

echo "== CAN (expected can0..can3 UP @ 1 Mbit/s)"
for i in 0 1 2 3; do
  if ip link show can$i >/dev/null 2>&1; then
    D=$(ip -details -statistics link show can$i)
    STATE=$(echo "$D" | grep -oE 'state [A-Z-]+' | head -1)
    BR=$(echo "$D" | grep -oE 'bitrate [0-9]+' | head -1)
    ERR=$(echo "$D" | grep -oE 'can state [A-Z-]+' | head -1)
    echo "$D" | grep -q "UP" && ok "can$i $STATE $BR ${ERR}" || warn "can$i down"
  else
    bad "can$i missing"
  fi
done

echo "== Serial / input devices"
ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null | sed 's/^/  /' || warn "no serial devices (IMU?)"
ls /dev/input/js* 2>/dev/null | sed 's/^/  /' || warn "no gamepad"

echo "== USB tree"
command -v lsusb >/dev/null && lsusb -t | sed 's/^/  /'

if command -v vcgencmd >/dev/null; then
  echo "== Raspberry Pi power"
  V=$(vcgencmd pmic_read_adc EXT5V_V | grep -oE '[0-9]+\.[0-9]+')
  THR=$(vcgencmd get_throttled | cut -d= -f2)
  awk "BEGIN{exit !($V >= 4.9)}" && ok "EXT5V ${V} V" || warn "EXT5V ${V} V (low)"
  (( THR == 0 )) && ok "throttled=0x0" || warn "throttled=$THR (bit0 under-voltage now, bit16 occurred since boot)"
  grep -q "^usb_max_current_enable=1" /boot/firmware/config.txt 2>/dev/null \
    && ok "usb_max_current_enable=1" || warn "USB ports limited to 600 mA (see docs/power-hub-v2.1.md)"
fi
