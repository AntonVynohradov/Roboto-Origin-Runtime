# Roboto Origin (RPO) – ROS 2 Humble control stack in a container.
# Builds for arm64 (Raspberry Pi 5, RDK X5, Orange Pi 5 Plus) and amd64 (laptop / mini-PC).
#
#   docker buildx build --platform linux/arm64,linux/amd64 -f docker/Dockerfile -t roboto-origin-runtime:humble .
#
# Hardware (SocketCAN can0..can3, IMU serial, gamepad) stays on the HOST.
# The container only uses it: see compose.robot.yml.

ARG ROS_DISTRO=humble
FROM ros:${ROS_DISTRO}-ros-base-jammy

ARG ROS_DISTRO
ARG DEPLOY_REPO=https://github.com/Roboparty/roboparty_deploy.git
ARG DEPLOY_REF=main
ENV DEBIAN_FRONTEND=noninteractive \
    ROS_DISTRO=${ROS_DISTRO} \
    WS=/opt/roboto_ws

# Dependencies from docs/rpo_deploy.md + debugging tools (can-utils, iproute2, screen).
RUN apt-get update && apt-get install -y --no-install-recommends \
        git ccache build-essential cmake \
        libfmt-dev libspdlog-dev libeigen3-dev zlib1g-dev \
        python3-yaml python3-numpy python3-pip \
        ros-${ROS_DISTRO}-joy \
        ros-${ROS_DISTRO}-rosbag2-storage-mcap \
        ros-${ROS_DISTRO}-rmw-cyclonedds-cpp \
        can-utils iproute2 screen usbutils joystick nano \
    && rm -rf /var/lib/apt/lists/*

# Source code (pinned ref => reproducible image on every computer).
RUN git clone --recursive --branch ${DEPLOY_REF} ${DEPLOY_REPO} ${WS} \
    && cd ${WS} && git submodule update --init --recursive

WORKDIR ${WS}

# Remaining package deps declared in package.xml files.
RUN apt-get update \
    && rosdep update --rosdistro ${ROS_DISTRO} \
    && rosdep install --from-paths src --ignore-src -y -r --rosdistro ${ROS_DISTRO} \
    && rm -rf /var/lib/apt/lists/*

# Build once at image build time (start_robot.sh would otherwise build on every start).
RUN . /opt/ros/${ROS_DISTRO}/setup.sh \
    && colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh \
    && echo "source /opt/ros/${ROS_DISTRO}/setup.bash && source ${WS}/install/setup.bash" >> /root/.bashrc

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
