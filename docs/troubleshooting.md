# Troubleshooting

| Problem | Check / fix |
|---|---|
| `canX missing` in the container | Run `./host/check_host.sh` on the host. Is `gs_usb` loaded (`lsmod \| grep gs_usb`)? Is the hub's data USB-C connected? |
| CAN interfaces swapped (wrong limb moves) | Port mapping rules: adapt `KERNELS==` paths for this computer ([host-setup.md](host-setup.md)). |
| `ulimit -r` shows 0 | Log out and in again after `setup_host.sh`; in the container check `cap_add: SYS_NICE` and `ulimits.rtprio`. |
| IMU not found | `ls /dev/ttyUSB*`; baud rate must match `robot.yaml` (default 921600). |
| `bash\r: No such file or directory` | Scripts were checked out with CRLF. `.gitattributes` prevents it; fix existing files with `sed -i 's/\r$//' **/*.sh`. |
| Container exits right after `start_robot.sh` | The script starts detached `screen` sessions and returns. Use `make start` (keeps a shell open) and `screen -r inference_session`. |
| Laptop does not see robot topics | Same `ROS_DOMAIN_ID`? Same subnet? On WSL2 use `networkingMode=mirrored` and allow UDP in the firewall. |
| `can state BUS-OFF` / `ERROR-PASSIVE` | Termination (120 Ω at both ends), wiring, motor power off while traffic is sent, wrong bitrate. `ip link set canX down && up` to recover. |
| Pi 5 warns "power supply not capable of 5 A" | Expected with the hub's 3 A USB-C; see [power-hub-v2.1.md](power-hub-v2.1.md). |
| Build fails on `rosdep` for a package | Add the missing apt package to `docker/Dockerfile` and open an issue upstream if the dependency is undeclared. |
