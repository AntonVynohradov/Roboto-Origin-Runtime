#!/usr/bin/env bash
# Runs ON THE RASPBERRY PI 5 (host, not container).
# Samples the Pi 5 PMIC input voltage, throttling flags and USB state every 100 ms and
# prints one line per sample. Each line is flushed immediately, so when it is streamed to
# the laptop (tools/debug/stream_logs.sh) the last samples before a brown-out survive.
#
#   ./pi_power_monitor.sh [interval_s]        default 0.1
set -u
INTERVAL=${1:-0.1}
command -v vcgencmd >/dev/null || { echo "vcgencmd not found (Raspberry Pi only)"; exit 1; }

echo "# time_iso;ext5v_V;throttled;core_V;temp_C"
while true; do
  T=$(date +%Y-%m-%dT%H:%M:%S.%3N)
  EXT5V=$(vcgencmd pmic_read_adc EXT5V_V 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)
  THR=$(vcgencmd get_throttled | cut -d= -f2)
  CORE=$(vcgencmd measure_volts core | grep -oE '[0-9]+\.[0-9]+')
  TEMP=$(vcgencmd measure_temp | grep -oE '[0-9]+\.[0-9]+')
  echo "${T};${EXT5V:-NA};${THR};${CORE};${TEMP}"
  # throttled bit 0 = under-voltage now, bit 16 = under-voltage has occurred
  if (( THR & 0x1 )); then echo "${T};!!! UNDER-VOLTAGE NOW" >&2; fi
  sleep "$INTERVAL"
done
