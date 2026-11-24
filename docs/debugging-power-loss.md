# Debugging: controller loses power when motors are enabled

Symptom: when the motors are enabled the Raspberry Pi 5 turns off, its LED stays red and no
logs are saved on the SD card.

## 0. Safety

Robot hanging on a stand, 48 V emergency cut-off within reach, motors enabled with
kp = 0 and small kd.

## 1. Answer the key question first

**Does the Pi die when the 48 V button is pressed, or when software enables the motors
(`ros2 service call /init_motors ...`)?**

| Moment | Most likely cause | Go to |
|---|---|---|
| Pressing the 48 V button | inrush / over-voltage, BMS trip | step 4 |
| `/init_motors`, motors start holding position | current steps, ground shift, USB current | steps 3, 5 |
| Only after the policy starts | high torque / regeneration, bus load | steps 5, 6 |

## 2. Capture logs that survive

On the laptop (own battery):

```bash
make logs          # dmesg, journal, power.csv (EXT5V every 100 ms), ping.log
```

Optionally connect a USB-UART adapter to the Pi 5 debug UART connector
(`enable_uart=1`) and keep a serial terminal open at 115200 baud.

After the event, look at the last lines of `power.csv` and `dmesg.log`:

- `EXT5V` dropping below ~4.8 V, `throttled` bit 0 set → supply dip.
- `usb ... over-current` or `can: bus-off` messages → USB / CAN side.
- Nothing at all, `ping.log` goes `DOWN` instantly → hard power cut (BMS or buck).

## 3. Separate the Pi supply

Power the Pi 5 from an official 27 W USB-C PD supply instead of the hub's USB-C power
output. Keep the data USB-C cable to the hub. If the problem disappears, the hub's 5 V path
is the culprit (step 5).

## 4. Check the 48 V side

- Bench supply? Its current limit collapses the voltage on enable – raise it or use the
  battery.
- Battery: does the BMS cut off? (Battery output LED, voltage at `48VIN` drops to 0.)
- Oscilloscope: CH1 on `48VIN`, CH2 on `5V_OUT`, trigger on falling edge of CH2,
  ~10 ms/div, then zoom in. Look for a dip, or for ringing above 60 V.

## 5. Narrow down by bus and motor

```bash
make shell
candump -tz can0                     # watch traffic per bus
```

Enable one bus at a time (disconnect the other XT30s), then one motor at a time. A single
motor that kills the system points to a shorted or faulty driver.

## 6. Reduce load during tests

- `usb_max_current_enable=1` on the Pi 5 (see [host-setup.md](host-setup.md)).
- Start with zero-torque enable, then increase gains gradually.
- Check `./host/check_host.sh` before and after each attempt (`throttled` flag history).

## 7. Replace the controller

If the Pi keeps failing, run the same container on a Linux laptop on its own battery
(see [debug-station.md](debug-station.md), "Laptop as robot computer"). If the laptop's USB
also resets on enable, the problem is ground/EMI on the hub, not the Pi.
