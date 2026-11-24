# Laptop as debug station

The laptop **observes** the robot; it never drives the motors in this mode. Run it on its
own battery (charger unplugged) so it keeps logging when the robot's supply collapses, and
so its ground is not tied to mains earth.

## What you get

| Command | Result |
|---|---|
| `make logs` | `logs/remote_<ts>/dmesg.log`, `journal.log`, `power.csv` (Pi 5 input voltage every 100 ms), `ping.log` |
| `make station` | shell with `ros2 topic list/echo/hz`, `ros2 service call` |
| `make record` | `ros2 bag record -a` (mcap) into `logs/<run>/bag` |

## Linux laptop

```bash
cp .env.example .env     # ROBOT_HOST, ROBOT_USER, ROS_DOMAIN_ID
ssh-copy-id pi@raspberrypi.local
make logs                # terminal 1
make record              # terminal 2
make station             # terminal 3: ros2 topic hz /imu ...
```

`stream_logs.sh` needs passwordless `sudo dmesg` on the robot, e.g.:

```bash
echo "pi ALL=(ALL) NOPASSWD: /usr/bin/dmesg" | sudo tee /etc/sudoers.d/roboto-dmesg
```

## Windows laptop (WSL2)

1. Install WSL2 with Ubuntu 22.04: `wsl --install -d Ubuntu-22.04`.
2. Enable mirrored networking so ROS 2 DDS multicast reaches the robot. In
   `%UserProfile%\.wslconfig`:

   ```ini
   [wsl2]
   networkingMode=mirrored
   ```

   then `wsl --shutdown`.
3. Install Docker Engine inside WSL2 (or Docker Desktop with the WSL2 backend).
4. Allow the WSL/Hyper-V firewall to pass UDP for DDS, or test with the Windows firewall
   temporarily disabled for the private network.
5. Clone this repository **inside WSL** (e.g. `~/roboto-origin-runtime`) and use the Linux
   commands above. `.gitattributes` forces LF line endings, so a clone made on the Windows
   side also works.

## Network between laptop and robot

- Same Wi-Fi network, or the robot's own access point (`create_ap`, default SSID `atom`).
- Same `ROS_DOMAIN_ID` in `.env` on both machines.
- Check discovery: `ros2 topic list` in `make station` should show the robot topics.
- Wi-Fi drops? Use an Ethernet cable directly between laptop and robot computer.

## Laptop as robot computer (bench only)

A Linux laptop can replace the Raspberry Pi completely: run `host/setup_host.sh` on it,
connect the hub's USB-C data cable, and use `compose.robot.yml`. Use a **powered USB hub**
if the laptop has too few ports, and consider a USB isolator if ground noise resets the
laptop's USB controller. Robot hanging on a stand only.
