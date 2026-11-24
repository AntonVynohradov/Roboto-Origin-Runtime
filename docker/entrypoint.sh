#!/usr/bin/env bash
# Container entrypoint: loads ROS, checks hardware, starts a log folder, runs the command.
set -e
source /opt/ros/${ROS_DISTRO}/setup.bash
source ${WS}/install/setup.bash

LOG_ROOT=${LOG_ROOT:-/logs}
RUN_DIR="${LOG_ROOT}/$(date +%Y%m%d_%H%M%S)"
mkdir -p "${RUN_DIR}"
export ROS_LOG_DIR="${RUN_DIR}/ros"
export RUN_DIR

echo "== Roboto container | ROS ${ROS_DISTRO} | $(uname -m) | logs: ${RUN_DIR}"
echo "-- rtprio limit: $(ulimit -r)  (98 expected for the control loop)"
for i in 0 1 2 3; do
  if ip link show can$i >/dev/null 2>&1; then
    echo "-- can$i: $(ip -details link show can$i | grep -oE 'state [A-Z-]+|bitrate [0-9]+' | tr '\n' ' ')"
  else
    echo "!! can$i missing (run host/setup_host.sh on the host)"
  fi
done
ls /dev/ttyUSB* /dev/ttyACM* /dev/input/js* 2>/dev/null | sed 's/^/-- device: /' || true

# Raw CAN capture from all buses, in the background, straight to the log folder.
if [ "${CAN_LOG:-1}" = "1" ] && command -v candump >/dev/null; then
  (cd "${RUN_DIR}" && candump -l any >/dev/null 2>&1 &)
  echo "-- candump -> ${RUN_DIR}/candump-*.log"
fi

exec "$@"
