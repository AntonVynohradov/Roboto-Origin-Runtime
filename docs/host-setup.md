# Host setup

Supported host operating systems (64-bit only):

- Raspberry Pi OS (Bookworm, 64-bit) on Raspberry Pi 5
- Ubuntu 22.04 / 24.04 (RDK X5, Orange Pi 5 Plus, laptops, mini-PCs)
- Debian 12

## 1. Run the setup script

```bash
sudo ./host/setup_host.sh /path/to/99-auto-up-devs-<board>.rules
sudo reboot
```

The script:

1. installs Docker and adds your user to the `docker` group;
2. loads `can`, `can_raw`, `can_dev`, `gs_usb` now and at every boot;
3. installs a udev rule that brings every `canX` interface up at **1 Mbit/s**
   (`/usr/local/bin/roboto-can-up`);
4. optionally installs the port-mapping rules from `roboparty_deploy/assets/`;
5. adds `rtprio 98` and `memlock unlimited` for your user in `/etc/security/limits.conf`;
6. on a Raspberry Pi 5:
   - sets `usb_max_current_enable=1` and `enable_uart=1` in `/boot/firmware/config.txt`,
   - makes the system journal persistent with a 1 s sync interval.

## 2. Map USB ports to CAN buses

The order in which the four USB→CAN channels appear depends on the USB topology of each
computer. `roboparty_deploy` expects a fixed mapping (can0 = left leg, ...), so the udev
rules pin each interface to a physical port path.

```bash
sudo udevadm monitor --kernel --subsystem-match=net
# plug the hub in and note the KERNELS=="x-y.z:1.0" path of each canX
```

Edit the `KERNELS==` entries in the rules file for this computer, then:

```bash
sudo udevadm control --reload && sudo udevadm trigger
ip -details link show | grep -A2 can
```

> Keep one rules file per computer type in `config/` (e.g. `config/udev-pi5.rules`,
> `config/udev-laptop.rules`) so switching computers is one copy command.

## 3. Verify

```bash
./host/check_host.sh
```

Expected: four `canX` interfaces UP with `bitrate 1000000`, `rtprio limit 98`, IMU at
`/dev/ttyUSB*`, and on the Pi 5 `EXT5V` ≥ 4.9 V with `throttled=0x0`.

## Raspberry Pi 5 notes

- The power hub feeds the Pi through a USB-C plug that advertises only **5 V / 3 A**
  (10 kΩ CC pull-ups, no USB-PD). The Pi 5 then limits all USB ports together to
  **600 mA** unless `usb_max_current_enable=1` is set. The USB→CAN section of the hub is
  powered from the Pi's USB port, so this limit matters. Only enable it if the hub's 5 V
  rail really delivers 5 A. See [power-hub-v2.1.md](power-hub-v2.1.md).
- The Pi 5 has a 3-pin **debug UART** connector between the HDMI ports. With a USB-UART
  adapter (e.g. Raspberry Pi Debug Probe) on the laptop you can read kernel messages up to
  the very last moment before a reset.
- The RT kernel is optional for bench tests. For walking, a PREEMPT_RT kernel is
  recommended (the official boards ship one).

## Real-time kernel (optional)

| Board | How |
|---|---|
| RDK X5 | preinstalled |
| Orange Pi 5 Plus | `.deb` packages in `roboparty_deploy/assets` |
| Ubuntu 22.04/24.04 x86 | `sudo pro enable realtime-kernel` (Ubuntu Pro, free for personal use) |
| Raspberry Pi 5 | build the kernel with the `PREEMPT_RT` patch, or build a 6.12+ kernel with `CONFIG_PREEMPT_RT=y` |
