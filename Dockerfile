ARG ROS_DISTRO=jazzy
FROM ros:${ROS_DISTRO} AS deps
ARG ROS_DISTRO

# Create ros2_ws and copy files
WORKDIR /root/ros2_ws
SHELL ["/bin/bash", "-c"]
ENV DISPLAY=host.docker.internal:0.0 \
    QT_X11_NO_MITSHM=1 \
    FASTDDS_SHM_TRANSPORT_DISABLE=1
EXPOSE 8765
COPY . /root/ros2_ws/src

# Install dependencies
RUN apt-get update \
    && apt-get -y --quiet --no-install-recommends install \
    gcc \
    git \
    tmux \
    wget \
    python3 \
    python3-pip \
    ros-${ROS_DISTRO}-foxglove-bridge \
    ros-${ROS_DISTRO}-ros2controlcli \
    x11-xserver-utils
RUN rosdep install --from-paths src --ignore-src -r -y

# Colcon the ws
FROM deps AS builder
ARG CMAKE_BUILD_TYPE=Release
RUN source /opt/ros/${ROS_DISTRO}/setup.bash && colcon build

# Source the ROS 2 setup file
RUN echo "source /root/ros2_ws/install/setup.bash" >> ~/.bashrc
RUN echo "alias foxglove='ros2 launch foxglove_bridge foxglove_bridge_launch.xml port:=8765 address:=0.0.0.0'" >> ~/.bashrc
RUN printf '%s\n' \
    'bind-key -n S-Left previous-window' \
    'bind-key -n S-Right next-window' \
    'bind-key k kill-session' \
    > /root/.tmux.conf

# Run a default command, e.g., starting a bash shell
CMD ["bash"]

