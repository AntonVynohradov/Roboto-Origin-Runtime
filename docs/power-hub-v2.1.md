# RBE PWR HUB V2.1 – schematic analysis

Source: `SCH_RBE_PWR_HUB_V2.1_2026-04-09.pdf` (3 sheets, part no. RBEA0000012).
This is a reading of the schematic, not of the PCB; component values should be checked on
the real board.

## Block diagram

```
 Battery 48 V ──► 48VIN ──┬─► TVS SMBJ60CA, 2×100 µF + 2×100 µF + ceramics
                          │
                          ├─► [external lit push-button, pads U14/U15] ──► 48V ──► 4× XT30(2+2) ─► motors
                          │                                                       (48V, GND, CAN_H, CAN_L)
                          │
                          └─► LM5148 buck ──► 5V_1 ──► [external lit button, pads U4/U7] ──► 5V_OUT
                                                                                          │
                                                                  USB-C "power only" (USB1)▼ ──► Raspberry Pi
                                                                    CC: 10 kΩ pull-ups = "5 V / 3 A"

 Raspberry Pi USB ──► USB-C data (USB2) ──► F1 1 A polyfuse ──► +5V ──► TLV75733 ──► 3.3V
                                │                                │
                                ▼                                ├─► 2× VPS8505 + transformer + TPS76350
                       SL2.1A USB 2.0 hub                         │      ──► ISO1_5V, ISO2_5V (isolated)
                     ┌───────┬───────┬───────┐                    │
                  STM32G431 ×4 (USB device + FDCAN, SWD header, 2 LEDs each)
                     │       │       │       │
                  ISO1050 ×4 isolated CAN transceivers, 120 Ω termination (0 Ω jumper), ESD
                     │       │       │       │
                   CAN1    CAN2    CAN3    CAN4  ──► XT30 connectors
```

## Sheet 1 – 48 V distribution

- `48VIN`: battery input, protected by a bidirectional TVS **SMBJ60CA** and bulk
  capacitance (C1, C21 = 100 µF).
- The motor supply switch is **off-board**: pads U14 (`48VIN`) and U15 (`48V`) take a
  lit push-button wired "normally open" (wiring picture on sheet 2). The button carries the
  **full motor current**.
- `48V` feeds four XT30 (2+2) connectors U2, U3, U5, U6 – each one CAN bus plus power.
- **No pre-charge / inrush limiting** and no current sensing on the motor rail.

## Sheet 2 – 5 V supply for the computer

- Synchronous buck **LM5148** (Q6 NVMFS6H836 high side, Q5 BSC028N06NS low side,
  L2 6.8 µH, R32 5 mΩ current sense), output ≈ 520 µF (4×47 µF + 330 µF).
- Supplied from **`48VIN`**, i.e. **before** the motor switch – the computer stays powered
  when the motor button is off. Ground is shared with the motors.
- A second lit push-button (pads U4/U7/U8/U9) switches `5V_1` → `5V_OUT`.
- `5V_OUT` leaves through a power-only USB-C (USB1). CC1/CC2 have **10 kΩ pull-ups to 5 V**,
  which advertises a **3 A** source. There is no USB-PD controller.

## Sheet 3 – USB to 4× CAN

- USB-C with data (USB2) to the computer; 5.1 kΩ pull-downs on CC (the hub is a USB device).
- The whole section is **powered by the computer's USB port** through a 1 A polyfuse.
- SL2.1A 4-port USB 2.0 hub (12 MHz crystal) → four **STM32G431C8T6**, each a USB→CAN
  bridge (appears as a SocketCAN interface on the host).
- **ISO1050** isolated CAN transceivers. Bus side powered by two isolated supplies
  (VPS8505 transformer drivers + TPS76350 LDOs): `ISO1_5V`, `ISO2_5V`.
- Q1 (SI2301) / Q2 (SS8050) with R71 1 MΩ and C124 22 µF: delayed switch-on of
  `3.3V-CAN` (logic side of the transceivers) a few seconds after power-up, so the bus sees
  no garbage while the MCUs boot.
- Each MCU has an SWD header (U11, U13, U16, U17) and STAT/WORD LEDs.

## Findings relevant to "computer dies when motors are enabled"

1. **Inrush on the motor switch.** Closing the button connects 48 V to the input capacitors
   of all motor drivers at once, limited only by wiring resistance. Possible effects:
   - battery BMS short-circuit protection trips → everything turns off, including the computer;
   - line inductance rings → over-voltage on `48VIN`. SMBJ60CA clamps at roughly 90+ V at
     high current, while the LM5148 input is rated to about 80 V.
2. **Shared ground.** Motor return current and the computer's supply share `GND`. Fast
   current steps shift the ground seen by the computer. The CAN isolation does not help here,
   because the computer is grounded through its supply cable anyway.
3. **Pi 5 USB current limit.** With a 3 A source the Pi 5 limits its USB ports to 600 mA
   in total. The 4 MCUs, the hub, two isolated DC/DC converters and four transceivers
   (dominant-state current grows with bus load), plus IMU and gamepad, approach that limit
   once all buses carry 500 Hz traffic.
4. **Pi 5 red LED.** Solid red usually means 5 V is present but the SoC is off/halted –
   consistent with a short dip after which the Pi did not restart, rather than a complete
   loss of 5 V. Measure whether 5 V is still present at USB-C after the event.

## Suggested hardware improvements

- Pre-charge circuit or NTC inrush limiter (bypassed by a relay/MOSFET) on the motor rail,
  or a dedicated hot-swap / e-fuse controller instead of a bare push-button.
- More bulk capacitance close to the hub on `48VIN` (low-ESR electrolytics).
- USB-PD source controller (or a separate 5 V / 5 A PD supply) for the Raspberry Pi 5.
- Separate 5 V supply for the USB→CAN section instead of the Pi's USB VBUS.
- Check the voltage and DC current rating of both push-buttons.
