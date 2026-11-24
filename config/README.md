# config/

Machine-specific files that you want under version control, mounted read-only into the
container at `/opt/roboto_ws/local_config`.

Suggested contents:

| File | Purpose |
|---|---|
| `udev-pi5.rules`, `udev-laptop.rules` | USB port → `canX` mapping per computer type |
| `robot.yaml` | your copy of `src/inference/robots/rpo/robot.yaml` (IMU baud rate, waist offset, ...) |

To use a local `robot.yaml`, copy it over the upstream file inside the container before
starting, e.g.:

```bash
cp /opt/roboto_ws/local_config/robot.yaml /opt/roboto_ws/src/inference/robots/rpo/robot.yaml
```
