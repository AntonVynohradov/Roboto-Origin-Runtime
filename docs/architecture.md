# Architecture

## Components of the robot

| Part | Function | Interface to the computer |
|---|---|---|
| 23 Damiao motors (DM 4340P, DM 10010L) | joints | CAN 1 Mbit/s, 4 buses |
| Power hub V2.x | 48 V distribution, 5 V for the computer, 4× USB→CAN | USB-C (data) + USB-C (5 V supply) |
| IMU (HiPNUC) | orientation, 500 Hz | USB serial, 921600 baud |
| Gamepad | operator commands | USB HID / `joy` |
| Robot computer | runs `roboparty_deploy` (ONNX policy, motor + IMU drivers) | – |

CAN bus mapping used by `roboparty_deploy`:

| Interface | Limbs |
|---|---|
| `can0` | left leg |
| `can1` | right leg + waist |
| `can2` | left arm |
| `can3` | right arm |

## Layers

```
┌───────────────────────────────────────────────────────────┐
│ Container (docker/Dockerfile)                             │
│  ROS 2 Humble · roboparty_deploy (built) · can-utils      │
│  entrypoint: hardware check, /logs/<run>/, candump        │
├───────────────────────────────────────────────────────────┤
│ Host (host/setup_host.sh)                                 │
│  Linux kernel · gs_usb + SocketCAN · udev port mapping    │
│  can0..can3 @ 1 Mbit/s · rtprio 98 / memlock · (RT kernel)│
├───────────────────────────────────────────────────────────┤
│ Hardware: Pi 5 / RDK X5 / Orange Pi 5 Plus / x86 PC       │
└───────────────────────────────────────────────────────────┘
```

### Why hardware stays on the host

- **SocketCAN interfaces are kernel network devices.** A container sees them only with
  `network_mode: host`. Bitrate and up/down are configured on the host by udev.
- **Kernel modules** (`gs_usb`, `can_raw`) cannot be loaded from a container.
- **Real-time scheduling** depends on the host kernel. The container only receives the
  permission (`SYS_NICE`, `rtprio 98`, unlimited `memlock`).
- **Device names** (`/dev/ttyUSB*` for the IMU, `/dev/input/js*`) are created by host udev;
  `/dev` is bind-mounted so hot-plugged devices stay visible.

### Why Windows cannot be the robot computer

SocketCAN exists only on Linux, and USB pass-through into WSL2 (usbipd) adds latency and
jitter that a 500 Hz balance loop does not tolerate. Windows is fine as the **debug station**
(see [debug-station.md](debug-station.md)).

## Multi-architecture image

The same `docker/Dockerfile` builds for:

| Platform | Machines |
|---|---|
| `linux/arm64` | Raspberry Pi 5 (64-bit OS), RDK X5, Orange Pi 5 Plus |
| `linux/amd64` | laptops, NUC / N100 mini-PCs |

Build locally with `make buildx`, or let GitHub Actions publish
`ghcr.io/<owner>/roboto-origin-runtime:humble` on every push to `main`.

The upstream code version is pinned with the `DEPLOY_REF` build argument (branch, tag or
commit of `roboparty_deploy`), so every robot computer runs exactly the same build.

## Logs

Every container start creates `logs/<YYYYmmdd_HHMMSS>/` on the host:

| File | Source |
|---|---|
| `ros/` | ROS 2 node logs (`ROS_LOG_DIR`) |
| `candump-*.log` | raw frames from all CAN buses (`candump -l any`) |
| `bag/` | `ros2 bag` recording (station recorder) |

`tools/debug/stream_logs.sh` adds `logs/remote_<timestamp>/` **on the laptop** with
`dmesg.log`, `journal.log`, `power.csv` and `ping.log` – this survives a power loss of
the robot computer.
