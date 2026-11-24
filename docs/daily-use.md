# Daily use

Always switch things on and off in the same order.

<div class="order" markdown>
<div markdown>**Computer on**<br>5&nbsp;V button, wait 15 V button, wait 1 minnbsp;min</div>
<div markdown>**Logging on**<br>`make logs` on the laptop</div>
<div markdown>**Software on**<br>`make start` on the robot</div>
<div markdown>**Motors on**<br>48&nbsp;V button, then gamepad</div>
<div markdown>**Stop**<br>services, 48&nbsp;V off, then 5&nbsp;V</div>
</div>

## Commands

| Command | Where | What it does |
|---|---|---|
| `make check` | robot | Health check: CAN buses, real-time limits, Pi supply voltage |
| `make shell` | robot | Opens a terminal inside the control container |
| `make start POLICY=default` | robot | Starts the control stack (policies: `default`, `amp`, …) |
| `screen -r inference_session` | robot, in container | Shows the control program; leave with ++ctrl+a++, ++d++ |
| `make logs` | laptop | Streams kernel log, journal and supply voltage to the laptop |
| `make station` | laptop | Terminal with `ros2` tools connected to the robot |
| `make record` | laptop | Records all ROS 2 topics to `logs/` |
| `make build` | robot | Rebuilds the image, e.g. after changing `DEPLOY_REF` |

## Stopping

```bash
ros2 service call /stop_inference std_srvs/srv/Trigger
ros2 service call /deinit_motors std_srvs/srv/Trigger
exit
```

Then 48 V motor button off, `sudo poweroff`, 5 V button off.

## CAN buses

| Interface | Limbs |
|---|---|
| `can0` | Left leg |
| `can1` | Right leg and waist |
| `can2` | Left arm |
| `can3` | Right arm |

## Updating

```bash
cd roboto-origin-runtime
git pull
make build
```

To run a specific version of the Roboparty control code, set `DEPLOY_REF` (branch, tag or
commit) in `.env` before `make build`.
