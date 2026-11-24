#!/usr/bin/env bash
# One-time host preparation (Raspberry Pi OS 64-bit, Ubuntu 22.04/24.04, Debian 12).
# Everything that touches the kernel stays on the host: CAN drivers, udev, RT limits, Docker.
#
#   sudo ./host/setup_host.sh [path/to/99-...rules]
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
USER_NAME=${SUDO_USER:-$(logname)}
ARCH=$(uname -m)
[ "$ARCH" = aarch64 ] || [ "$ARCH" = x86_64 ] || { echo "64-bit OS required (got $ARCH)"; exit 1; }

echo "== 1. Docker"
if ! command -v docker >/dev/null; then
  curl -fsSL https://get.docker.com | sh
fi
usermod -aG docker "$USER_NAME"

echo "== 2. SocketCAN kernel modules"
apt-get update && apt-get install -y can-utils iproute2
for m in can can_raw can_dev gs_usb; do modprobe "$m" || echo "!! module $m not available"; done
printf "can\ncan_raw\ncan_dev\ngs_usb\n" > /etc/modules-load.d/roboto-can.conf

echo "== 3. CAN bring-up at 1 Mbit/s whenever an adapter appears"
cat > /usr/local/bin/roboto-can-up <<'EOF'
#!/bin/sh
ip link set "$1" down 2>/dev/null
ip link set "$1" type can bitrate 1000000
ip link set "$1" txqueuelen 1000
ip link set "$1" up
EOF
chmod +x /usr/local/bin/roboto-can-up
cat > /etc/udev/rules.d/90-roboto-can-up.rules <<'EOF'
SUBSYSTEM=="net", ACTION=="add", KERNEL=="can[0-9]*", RUN+="/usr/local/bin/roboto-can-up %k"
EOF

echo "== 4. Port mapping rules from roboparty_deploy (can0=L leg, can1=R leg+waist, can2=L arm, can3=R arm)"
if [ "${1:-}" != "" ] && [ -f "$1" ]; then
  cp "$1" /etc/udev/rules.d/
  echo "   installed $1 - check KERNELS== paths for THIS computer with: udevadm monitor"
else
  echo "   skipped: pass assets/99-auto-up-devs-*.rules adapted to this computer's USB ports"
fi
udevadm control --reload && udevadm trigger

echo "== 5. Real-time limits"
grep -q "$USER_NAME.*rtprio" /etc/security/limits.conf || cat >> /etc/security/limits.conf <<EOF
$USER_NAME - rtprio 98
$USER_NAME - memlock unlimited
EOF

echo "== 6. Raspberry Pi 5 specifics"
if grep -qi "raspberry pi 5" /proc/device-tree/model 2>/dev/null; then
  CFG=/boot/firmware/config.txt
  # The power hub advertises only 3 A on USB-C (10k CC pull-ups), so Pi 5 limits USB to 600 mA.
  # Only enable this if the hub's 5 V rail really delivers 5 A.
  grep -q usb_max_current_enable "$CFG" || echo "usb_max_current_enable=1" >> "$CFG"
  grep -q enable_uart "$CFG" || echo "enable_uart=1" >> "$CFG"
  echo "   set usb_max_current_enable=1 and enable_uart=1 in $CFG"
  # Persistent journal flushed often, so the last seconds survive a brown-out.
  mkdir -p /etc/systemd/journald.conf.d
  printf "[Journal]\nStorage=persistent\nSyncIntervalSec=1s\n" > /etc/systemd/journald.conf.d/roboto.conf
fi

echo "== done. Reboot, then check: ip -details link show can0 ; ulimit -r"
