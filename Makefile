# Convenience targets. Run on Linux (robot computer or laptop).
ROBOT   = docker compose -f compose.robot.yml
STATION = docker compose -f compose.station.yml
POLICY ?= default

.PHONY: help build buildx shell start check record station logs

help:
	@echo "make build     - build image for this machine"
	@echo "make buildx    - build arm64+amd64 images (needs docker buildx)"
	@echo "make check     - host health check (CAN, RT, power)"
	@echo "make shell     - shell inside the robot container"
	@echo "make start     - start control stack (POLICY=default|amp|...)"
	@echo "make station   - ros2 shell on the debug laptop"
	@echo "make record    - record all ROS topics on the debug laptop"
	@echo "make logs      - stream robot logs to this laptop over SSH"

build:
	$(ROBOT) build

buildx:
	docker buildx build --platform linux/arm64,linux/amd64 -f docker/Dockerfile -t roboto-origin-runtime:humble .

check:
	./host/check_host.sh

shell:
	$(ROBOT) run --rm robot

start:
	$(ROBOT) run --rm robot bash -c "bash tools/start_robot.sh --robot rpo --policy $(POLICY); exec bash"

station:
	$(STATION) run --rm station

record:
	$(STATION) up recorder

logs:
	./tools/debug/stream_logs.sh
