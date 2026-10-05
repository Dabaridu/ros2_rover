# ros2_rover

This is a ROS 2 version of the [Sawppy the Rover](https://github.com/Roger-random/Sawppy_Rover). A [C++](./rover_motor_controller_cpp) version and a [Python](./rover_motor_controller) version of the lx16a controller are included. Besides, a [PS3 joy controller](./rover_bringup/launch/joy_teleop.launch.py) and a [hokuyo laser](./rover_bringup/launch/urg_node.launch.py) can be used.

<div align="center">

[![License: MIT](https://img.shields.io/badge/GitHub-MIT-informational)](https://opensource.org/license/mit) [![GitHub release](https://img.shields.io/github/release/mgonzs13/ros2_rover.svg)](https://github.com/mgonzs13/ros2_rover/releases) [![Code Size](https://img.shields.io/github/languages/code-size/mgonzs13/ros2_rover.svg?branch=jazzy)](https://github.com/mgonzs13/ros2_rover?branch=jazzy) [![Last Commit](https://img.shields.io/github/last-commit/mgonzs13/ros2_rover.svg)](https://github.com/mgonzs13/ros2_rover/commits/maijazzyn) [![GitHub issues](https://img.shields.io/github/issues/mgonzs13/ros2_rover)](https://github.com/mgonzs13/ros2_rover/issues) [![GitHub pull requests](https://img.shields.io/github/issues-pr/mgonzs13/ros2_rover)](https://github.com/mgonzs13/ros2_rover/pulls) [![Contributors](https://img.shields.io/github/contributors/mgonzs13/ros2_rover.svg)](https://github.com/mgonzs13/ros2_rover/graphs/contributors) [![Python Formatter Check](https://github.com/mgonzs13/ros2_rover/actions/workflows/python-formatter.yml/badge.svg?branch=jazzy)](https://github.com/mgonzs13/ros2_rover/actions/workflows/python-formatter.yml?branch=jazzy) [![C++ Formatter Check](https://github.com/mgonzs13/ros2_rover/actions/workflows/cpp-formatter.yml/badge.svg?branch=jazzy)](https://github.com/mgonzs13/ros2_rover/actions/workflows/cpp-formatter.yml?branch=jazzy)

| ROS 2 Distro |                             Branch                             |                                                                                                        Build status                                                                                                         |                                                             Docker Image                                                             | Documentation                                                                                                                                                    |
| :----------: | :------------------------------------------------------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :----------------------------------------------------------------------------------------------------------------------------------: | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|  **Jazzy**  | [`jazzy`](https://github.com/mgonzs13/ros2_rover/tree/jazzy) | [![Jazzy Build](https://github.com/mgonzs13/ros2_rover/actions/workflows/jazzy-docker-build.yml/badge.svg?branch=jazzy)](https://github.com/mgonzs13/ros2_rover/actions/workflows/jazzy-docker-build.yml?branch=jazzy) | [![Docker Image](https://img.shields.io/badge/Docker%20Image%20-jazzy-blue)](https://hub.docker.com/r/mgons/rover/tags?name=jazzy) | [![Doxygen Deployment](https://github.com/mgonzs13/ros2_rover/actions/workflows/doxygen-deployment.yml/badge.svg)](https://mgonzs13.github.io/ros2_rover/latest) |
|   **Kilted**   | [`jazzy`](https://github.com/mgonzs13/ros2_rover/tree/jazzy) |    [![Kilted Build](https://github.com/mgonzs13/ros2_rover/actions/workflows/kilted-docker-build.yml/badge.svg?branch=jazzy)](https://github.com/mgonzs13/ros2_rover/actions/workflows/kilted-docker-build.yml?branch=jazzy)    |   [![Docker Image](https://img.shields.io/badge/Docker%20Image%20-kilted-blue)](https://hub.docker.com/r/mgons/rover/tags?name=kilted)   | [![Doxygen Deployment](https://github.com/mgonzs13/ros2_rover/actions/workflows/doxygen-deployment.yml/badge.svg)](https://mgonzs13.github.io/ros2_rover/latest) |

</div>

## Table of Contents

1. [Installation](#installation)
2. [Docker](#docker---ulrc-2027-use-this)
   - [Windows Scripts](#windows-scripts)
   - [Foxglove](#foxglove)
3. [Usage](#usage)
   - [Linux Service](#linux-service)
4. [Gazebo Simulation](#gazebo-simulation)
5. [Citations](#citations)

## Installation

```shell
cd ~/ros2_ws/src
git clone https://github.com/mgonzs13/ros2_rover
cd ~/ros2_ws
rosdep install --from-paths src -r -y
colcon build
```

## Docker - ULRC 2027 use this!!!

You can create a docker image to test this repo. Use the following common inside the directory of ros2_rover.

```shell
docker build -t rover .
```

After the image is created, run a docker container with the following command.

```shell
docker run -it --rm -p 8765:8765 --shm-size=512m rover
```

Port 8765 is published so Foxglove can reach the bridge running inside the container.

### Windows Scripts

Two PowerShell scripts wrap the commands above. Run them from the directory of ros2_rover.

| Script            | What it does                                                                                                                                                                                              |
| ----------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `rover_build.ps1` | Builds the `rover` image (`docker build -t rover .`). Run it again after changing the code or the Dockerfile.                                                                                              |
| `rover_enter.ps1` | Starts the `rover` container if it is not running (port 8765 published, 512 MB of shared memory), starts the moon simulation and the Foxglove bridge, and attaches to its `rover` tmux session. Running it again attaches to the same container and session. |

```powershell
.\rover_build.ps1
.\rover_enter.ps1
```

`rover_enter.ps1` opens the tmux session with two side by side panes:

- **Left pane**: the moon simulation, already started with `ros2 launch rover_gazebo moon.launch.py`. Press `Ctrl+c` to stop it and launch something else.
- **Right pane**: the Foxglove bridge, already started with the `foxglove` alias.

Useful tmux keys (the prefix is `Ctrl+b`):

| Keys                         | Action                                       |
| ---------------------------- | -------------------------------------------- |
| `Ctrl+b` then `o`            | Move to the other pane                       |
| `Ctrl+b` then `c`            | Open a new window                            |
| `Ctrl+b` then `p` / `n`      | Previous / next window                       |
| `Ctrl+b` then `d`            | Detach (the container keeps running)         |
| `Ctrl+b` then `k`            | Close all tmux terminals (kills the session) |

`Ctrl+b` then `k` is a custom binding added by the Dockerfile (`bind-key k kill-session` in `/root/.tmux.conf`). It closes both panes, which stops the simulation and the Foxglove bridge and returns to PowerShell. The container keeps running, so `rover_enter.ps1` opens a fresh session with both panes started again. To close a single pane instead, use `Ctrl+b` then `x`.

The container is started with `--rm`, so it is removed when stopped with `docker stop rover`.

### Foxglove

1. Enter the container with `rover_enter.ps1`. The bridge is already running in the right pane. In a container started by hand, run it in a second tmux pane (`Ctrl+b` then `%`):

```shell
foxglove
```

2. The moon simulation is already running in the left pane. In a container started by hand, launch the rover or a simulation there.
3. In [Foxglove](https://foxglove.dev/), choose `Open connection`, select `Foxglove WebSocket` and connect to:

```
ws://localhost:8765
```

4. Import the layout [`Ros2_ERC_rover.json`](./Ros2_ERC_rover.json): open the layout menu, choose `Import from file...` and select the file.

The layout contains the following panels:

| Panel       | Topic                                         | Purpose                                                                                                   |
| ----------- | --------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| 3D          | all visible topics                            | Scene view that follows the rover, with a 10 m grid. Publishes clicked points to `/clicked_point`.          |
| Teleop      | `/cmd_vel`                                    | Drive pad publishing at 10 Hz: up / down set `linear.x` to 1 / -1, left / right set `angular.z` to 1 / -1. |
| Image       | `/camera/image_raw` and `/camera/camera_info` | Camera view of the rover.                                                                                 |
| Publish (2) | `/cmd_vel`                                    | Send a single `Twist` with `linear.x` 1 and `angular.z` 1 (forward left) or -1 (forward right).           |

The Teleop panel does not send a stop command when a button is released, so use its stop button to halt the rover.

The `foxglove` alias runs `ros2 launch foxglove_bridge foxglove_bridge_launch.xml port:=8765 address:=0.0.0.0`. Only one bridge can use the port, so starting it a second time fails with `Address already in use`. Connect to `localhost`, not to the IP of the container, which is not reachable from Windows.

## Usage

<div align="center">
    <img src="docs/rover.png" width="75%"/>
</div>

```shell
ros2 launch rover_bringup rover.launch.py
```

### Linux Service

A Linux service can be created to control the execution and launch everything at boot time. To create the rover service, the following commands are used:

```shell
cd ~/ros2_ws/src/ros2_rover/rover_service
sudo ./install.sh
```

Check rover service:

```shell
sudo service rover status
```

## Gazebo Simulation

### Moon

```shell
ros2 launch rover_gazebo moon.launch.py
```

<div>
    <img src="docs/moon.png" width="100%"/>
</div>

### Mars

```shell
ros2 launch rover_gazebo mars.launch.py
```

<div>
    <img src="docs/mars.png" width="100%"/>
</div>

### Forest

```shell
ros2 launch rover_gazebo forest.launch.py
```

<div>
    <img src="docs/forest.png" width="100%"/>
</div>

## Citations

The `v0.7` version has been used in the work `Comparison of Concentric Surface Planetary Explorations Using an Ackerman Rover in a Lunar Simulation` from the `2024 International Conference on Space Robotics (iSpaRo)`.

```bibtex
@INPROCEEDINGS{10685849,
  author={González-Santamarta, Miguel Á. and Rodríguez-Lera, Francisco J.},
  booktitle={2024 International Conference on Space Robotics (iSpaRo)},
  title={Comparison of Concentric Surface Planetary Explorations Using an Ackerman Rover in a Lunar Simulation},
  year={2024},
  volume={},
  number={},
  pages={239-244},
  keywords={Spirals;Navigation;Moon;Cameras;Sensors;Visual odometry;Testing},
  doi={10.1109/iSpaRo60631.2024.10685849}
}
```
