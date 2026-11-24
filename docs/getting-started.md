# Step-by-step setup

No Linux experience is required. Every command can be copied with the copy button in the
top-right corner of the code box and pasted into a terminal. Do the steps in order; times
are typical for a Raspberry Pi 5 (a laptop is faster).

## What you need

| Item | Notes |
|---|---|
| Robot computer | Raspberry Pi 5 (4 or 8 GB), RDK X5, Orange Pi 5 Plus, or any 64-bit Linux laptop / mini-PC |
| microSD card, 32 GB+ | For the Raspberry Pi system. A fast A2 card shortens the build |
| Your laptop | Windows, macOS or Linux, on the same Wi-Fi network as the robot |
| Roboto Origin robot | Power hub V2.x, battery, IMU and gamepad connected as in the hardware manual |
| Two USB-C cables | Hub power output → Pi power input; hub data port → a blue USB 3 port |
| Stand and cut-off | The robot hangs on a stand; a 48 V emergency switch is within reach |

## Checklist

- [ ] 1. Install the operating system
- [ ] 2. Connect from your laptop
- [ ] 3. Update the system
- [ ] 4. Download this project
- [ ] 5. Prepare the computer
- [ ] 6. Connect the robot and check the hardware
- [ ] 7. Get the control software
- [ ] 8. Start logging on your laptop
- [ ] 9. First start
- [ ] 10. Stop safely

---

## 1. Install the operating system

:material-clock-outline: 15 min
{ .step-time }

On your laptop, install [Raspberry Pi Imager](https://www.raspberrypi.com/software/) and
insert the microSD card.

1. Device: **Raspberry Pi 5**. Operating system: **Raspberry Pi OS Lite (64-bit)**.
   Storage: your card.
2. Click **Next → Edit settings**. Set hostname `roboto`, a username (e.g. `pi`) and
   password, your Wi-Fi name and password, and your country.
3. On the **Services** tab tick **Enable SSH** with password authentication. Save and write
   the card.
4. Put the card in the Pi. Do not connect the robot yet.

!!! tip "Laptop or mini-PC as the robot computer?"
    Install **Ubuntu 22.04 LTS** on it, open a terminal and continue from step 3.

## 2. Connect from your laptop

:material-clock-outline: 5 min
{ .step-time }

Power the Pi with its own USB-C supply for now and wait about one minute. Then open a
terminal on your laptop:

=== "Windows"

    Press ++win++, type **Terminal** (or **PowerShell**) and press ++enter++.

=== "macOS"

    Press ++cmd+space++, type **Terminal** and press ++enter++.

=== "Linux"

    Press ++ctrl+alt+t++.

Log in (replace `pi` with your username). Type `yes` at the first question, then your
password; nothing is shown while you type it.

```bash
ssh pi@roboto.local
```

??? question "Could not resolve hostname?"
    Find the Pi's IP address in your router's device list and use it instead, for example
    `ssh pi@192.168.1.23`.

## 3. Update the system

:material-clock-outline: 10 min
{ .step-time }

All following commands run on the robot computer, in the SSH window.

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y git make curl
```

## 4. Download this project

:material-clock-outline: 2 min
{ .step-time }

```bash
git clone https://github.com/AntonVynohradov/roboto-origin-runtime.git roboto-origin-runtime
cd roboto-origin-runtime
cp .env.example .env
```

Optional: open the settings with `nano .env`. The defaults work. Save with ++ctrl+o++,
++enter++, exit with ++ctrl+x++.

## 5. Prepare the computer

:material-clock-outline: 10 min
{ .step-time }

This installs Docker, the CAN bus drivers and real-time permissions, and sets the
Raspberry Pi 5 power options. Then it restarts the computer.

```bash
sudo ./host/setup_host.sh
sudo reboot
```

Wait one minute, log in again with the `ssh` command from step 2, then
`cd roboto-origin-runtime`.

## 6. Connect the robot and check the hardware

:material-clock-outline: 10 min
{ .step-time }

!!! danger "Safety"
    Robot on its stand, 48 V motor button **off**. Only the computer gets power in this step.

1. Shut the Pi down: `sudo poweroff`. Unplug its own supply.
2. Connect the hub's **power** USB-C to the Pi's power input and the hub's **data** USB-C to
   a blue USB 3 port. Plug in the IMU and gamepad.
3. Connect the battery and press the **computer (5 V) button**. Log in again.

```bash
cd roboto-origin-runtime
./host/check_host.sh
```

You should see **[OK]** for `can0` to `can3` with `bitrate 1000000`, an IMU at
`/dev/ttyUSB0` and, on a Pi, `EXT5V` of 4.9 V or more.

!!! warning "Which bus is which limb?"
    The control software expects `can0` = left leg, `can1` = right leg + waist,
    `can2` = left arm, `can3` = right arm. The order depends on the USB ports, so it must be
    pinned once per computer type. Follow
    [Host setup → Map USB ports to CAN buses](host-setup.md#2-map-usb-ports-to-can-buses)
    before enabling any motor.

## 7. Get the control software

:material-clock-outline: 5 min to download, or 30–60 min to build
{ .step-time }

The control software (ROS 2 + Roboparty code) comes as a Docker image. Choose one way:

=== "Download the ready image (recommended)"

    A ready image for Raspberry Pi (arm64) and PCs (amd64) is published on GitHub. Docker
    picks the right one for your computer automatically.

    1. Open the settings: `nano .env`
    2. Make sure this line is there (it is the default):

        ```bash
        IMAGE=ghcr.io/antonvynohradov/roboto-origin-runtime:humble
        ```

    3. Download the image:

        ```bash
        docker compose -f compose.robot.yml pull
        ```

    !!! warning "Do not run `make build` afterwards"
        `make build` compiles the image locally and replaces the downloaded one. You only
        need it if you change the Dockerfile or want to build yourself.

=== "Build it yourself"

    Compiles everything on this computer. Use it when no image is published yet, or you
    changed `docker/Dockerfile`. It runs by itself; keep the SSH window open.

    ```bash
    make build
    ```

    On a Raspberry Pi 5 this takes 30–60 minutes the first time.

??? question "Access denied when downloading?"
    The image is private. Either ask the owner to make the package public, or log in once
    with a GitHub token that has the `read:packages` permission (paste the token as the
    password):

    ```bash
    docker login ghcr.io -u YOUR-GITHUB-USER
    ```

## 8. Start logging on your laptop

:material-clock-outline: 5 min
{ .step-time }

Before the first motor test, record everything on your laptop, running on its own battery.
If the robot computer loses power, the last seconds are still saved. Setup for Windows,
macOS and Linux is described in [Debug laptop](debug-station.md).

```bash
make logs
```

## 9. First start

:material-clock-outline: 5 min
{ .step-time }

!!! danger "Before you continue"
    Robot hanging free on the stand, nobody within reach of the limbs, your hand next to the
    48 V cut-off.

```bash
make start POLICY=default
```

1. The container starts and prints a hardware check. Look for four CAN buses and the IMU.
2. Press the **48 V motor button**.
3. Watch the control program with `screen -r inference_session`. Leave it without stopping
   it with ++ctrl+a++ then ++d++.
4. Enable the motors with the gamepad as described in the Roboparty operation guide.

## 10. Stop safely

:material-clock-outline: 1 min
{ .step-time }

```bash
ros2 service call /stop_inference std_srvs/srv/Trigger
ros2 service call /deinit_motors std_srvs/srv/Trigger
exit
```

Then switch off the **48 V motor button**, and only after that the computer:
`sudo poweroff`, then the 5 V button.

Next: [Daily use](daily-use.md)
