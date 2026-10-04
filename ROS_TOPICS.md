# ROS 2 Topic Reference — ros2_rover

Snapshot of the active ROS graph on the `rover` container (Jazzy, full stack: Gazebo sim + Nav2 + RTAB-Map + Foxglove bridge). Captured via `ros2 topic list -t` on 2026-10-04. Topic *existence* reflects the launch files in this repo; which ones carry traffic at any moment depends on what's actually running (sim vs. real robot, nav goal active or not, etc.).

## 1. Velocity command chain (teleop / driving)

The path any teleop source (Foxglove Teleop panel, `teleop_keyboard_node`, joystick, or Nav2) takes to actually spin the wheels.

| Topic | Type | Description |
|---|---|---|
| `/cmd_vel` | `geometry_msgs/Twist` | Top-level velocity command for the rover body (linear.x, angular.z). Published by anything driving the robot: `foxglove_bridge` (Teleop panel), `teleop_twist_joy_node` (gamepad), `ros_gz_bridge`, Nav2's `controller_server`/`behavior_server`. Consumed by `vel_parser_node`. |
| `/cmd_vel_teleop` | `geometry_msgs/Twist` | Raw teleop-source velocity before it's merged/arbitrated with autonomous commands (twist_mux-style input). |
| `/cmd_vel_smoothed` | `geometry_msgs/Twist` | Output of Nav2's `velocity_smoother` — acceleration/jerk-limited version of the commanded velocity. |
| `/preempt_teleop` | `std_msgs/Empty` | Signal to drop manual teleop priority and hand control back to autonomy (twist_mux preemption). |
| `/motors_command` | `rover_msgs/MotorsCommand` | Rover-specific message: 6 drive-wheel speeds + 4 corner (steering) positions. Produced by `vel_parser_node` from `/cmd_vel` using the rover's kinematic (rocker-bogie) model. |
| `/velocity_controller/commands` | `std_msgs/Float64MultiArray` | Per-wheel velocity setpoints (6 values) for `ros2_control`'s `JointGroupVelocityController`. Produced by `motors_command_parser_node` from `/motors_command`. |
| `/position_controller/commands` | `std_msgs/Float64MultiArray` | Per-corner steering-joint position setpoints (4 values) for `ros2_control`'s `JointGroupPositionController`. Produced by `motors_command_parser_node`. |
| `/joy` | `sensor_msgs/Joy` | Raw gamepad input, consumed by `teleop_twist_joy_node` to produce `/cmd_vel`. |
| `/joy/set_feedback` | `sensor_msgs/JoyFeedbackArray` | Rumble/LED feedback sent back to the joystick driver. |
| `/speed_limit` | `nav2_msgs/SpeedLimit` | Dynamic speed cap published (e.g. by a costmap speed-limit layer) and applied by `velocity_smoother`/`controller_server`. |

## 2. Odometry, localization & transforms

| Topic | Type | Description |
|---|---|---|
| `/odom` | `nav_msgs/Odometry` | Wheel/base odometry (pose + twist) in the `odom` frame. |
| `/odom_rgbd` | `nav_msgs/Odometry` | Visual odometry estimate from RTAB-Map's RGB-D odometry node. |
| `/odom_info` / `/odom_info_lite` | `rtabmap_msgs/OdomInfo` | Diagnostic info about the visual odometry solve (inliers, features, timing); "lite" omits heavy debug fields. |
| `/odom_last_frame`, `/odom_local_map`, `/odom_local_scan_map` | `sensor_msgs/PointCloud2` | Debug point clouds from RTAB-Map's odometry (last processed frame / local map used for registration). |
| `/global_pose` | `geometry_msgs/PoseWithCovarianceStamped` | Fused global pose estimate (map frame). |
| `/localization_pose` | `geometry_msgs/PoseWithCovarianceStamped` | Localization-only pose output (e.g. from RTAB-Map/AMCL in localization mode). |
| `/initialpose` | `geometry_msgs/PoseWithCovarianceStamped` | Manual "2D Pose Estimate" input (RViz/Foxglove) to seed/correct localization. |
| `/set_pose` | `geometry_msgs/PoseWithCovarianceStamped` | Programmatic request to reset the robot's pose in the map. |
| `/accel` | `geometry_msgs/AccelWithCovarianceStamped` | Estimated body acceleration (from odometry filtering, e.g. `robot_localization`). |
| `/imu` | `sensor_msgs/Imu` | IMU orientation/angular velocity/linear acceleration. |
| `/tf` | `tf2_msgs/TFMessage` | Dynamic coordinate transforms (odom→base_link, map→odom, sensor links, etc.). |
| `/tf_static` | `tf2_msgs/TFMessage` | Static transforms (fixed sensor mounts, URDF joint offsets). |
| `/joint_states` | `sensor_msgs/JointState` | Measured position/velocity of every joint (wheels, corners, mast), published by `joint_state_broadcaster`; feeds robot_state_publisher for TF. |
| `/robot_description` | `std_msgs/String` | The rover's URDF/XACRO (as a string), published once (latched) for RViz/Foxglove/robot_state_publisher to parse. |

## 3. Nav2 — costmaps

Each costmap (global = whole-map planning, local = rolling window around the robot) publishes the same family of topics.

| Topic | Type | Description |
|---|---|---|
| `/global_costmap/costmap`, `/local_costmap/costmap` | `nav_msgs/OccupancyGrid` | Full occupancy grid used for planning (0–100 cost + unknown). |
| `/global_costmap/costmap_raw`, `/local_costmap/costmap_raw` | `nav2_msgs/Costmap` | Same grid in Nav2's native (non-ROS-standard) format, used internally by planners/controllers. |
| `/*/costmap_updates`, `/*/costmap_raw_updates` | `map_msgs/OccupancyGridUpdate`, `nav2_msgs/CostmapUpdate` | Incremental diffs so the whole grid doesn't need to be republished every cycle. |
| `/global_costmap/static_layer*`, `/global_costmap/static_layer_raw*` | `nav_msgs/OccupancyGrid`, `nav2_msgs/Costmap`, update variants | The static-map layer only (from `/map`), before obstacle/inflation layers are added. |
| `/local_costmap/voxel_layer*`, `/local_costmap/voxel_grid` | `nav_msgs/OccupancyGrid`, `nav2_msgs/Costmap`, `nav2_msgs/VoxelGrid` | 3D voxel obstacle layer (from point-cloud sensors) and its 2D projection used in the local costmap. |
| `/local_costmap/clearing_endpoints` | `sensor_msgs/PointCloud2` | Ray endpoints used to clear stale obstacles from the voxel layer. |
| `/*/footprint`, `/*/published_footprint` | `geometry_msgs/Polygon`, `PolygonStamped` | Robot footprint polygon used for collision checking, and the same footprint stamped at the current pose. |
| `/global_costmap/global_costmap/transition_event`, `/local_costmap/local_costmap/transition_event` | `lifecycle_msgs/TransitionEvent` | Lifecycle state transitions (unconfigured→inactive→active) for the costmap nodes. |

## 4. Nav2 — planning, control & behaviors

| Topic | Type | Description |
|---|---|---|
| `/goal_pose`, `/move_base_simple/goal` | `geometry_msgs/PoseStamped` | Navigation goal target (the latter is the legacy move_base-style alias Foxglove/RViz "Nav Goal" tools publish to). |
| `/goal_out` | `geometry_msgs/PoseStamped` | Current active goal as republished by the BT navigator / behavior tree. |
| `/goal_reached` | `std_msgs/Bool` | Whether the current navigation goal has been reached. |
| `/plan`, `/plan_smoothed` | `nav_msgs/Path` | Global path from the planner, and the smoothed version after `smoother_server`. |
| `/unsmoothed_plan` | `nav_msgs/Path` | Pre-smoothing raw global plan (debug). |
| `/received_global_plan` | `nav_msgs/Path` | The plan as received by the controller server (confirms what it's actually tracking). |
| `/local_path` | `nav_msgs/Path` | Short-horizon path the local controller is currently following. |
| `/lookahead_point`, `/curvature_lookahead_point` | `geometry_msgs/PointStamped` | Lookahead target point(s) used by the pure-pursuit-style path-tracking controller. |
| `/lookahead_collision_arc` | `nav_msgs/Path` | Projected arc checked for collisions ahead of the robot. |
| `/is_rotating_to_heading` | `std_msgs/Bool` | Whether the controller is currently doing an in-place rotation to face the path. |
| `/expansions` | `geometry_msgs/PoseArray` | Planner search-expansion debug (nodes explored by the global planner, e.g. Smac). |
| `/planned_footprints`, `/smoothed_footprints` | `visualization_msgs/MarkerArray` | Footprint polygons along the (smoothed) path, for visualizing collision margins. |
| `/planner_selector`, `/controller_selector` | `std_msgs/String` | Runtime selection of which named planner/controller plugin to use. |
| `/behavior_tree_log` | `nav2_msgs/BehaviorTreeLog` | Live log of behavior-tree node state transitions (for the BT navigator). |
| `/bond` | `bond/msg/Status` | Liveliness heartbeat between the lifecycle manager and managed Nav2 servers. |
| `/controller_server/transition_event`, `/planner_server/transition_event`, `/smoother_server/transition_event`, `/behavior_server/transition_event`, `/bt_navigator/transition_event`, `/waypoint_follower/transition_event`, `/velocity_smoother/transition_event` | `lifecycle_msgs/TransitionEvent` | Lifecycle transitions for each managed Nav2 node. |
| `/clicked_point` | `geometry_msgs/PointStamped` | Ad-hoc point clicked in RViz/Foxglove (debugging/waypoint tooling). |

## 5. RTAB-Map SLAM & mapping

| Topic | Type | Description |
|---|---|---|
| `/map` | `nav_msgs/OccupancyGrid` | 2D occupancy grid map built/maintained by RTAB-Map, consumed by Nav2's static layer. |
| `/mapData` | `rtabmap_msgs/MapData` | Full graph + node data of RTAB-Map's internal map (loop closures, signatures). |
| `/mapGraph`, `/mapOdomCache` | `rtabmap_msgs/MapGraph` | Pose graph of the map (and a cached odom-indexed variant) for visualization/debug. |
| `/mapPath` | `nav_msgs/Path` | Path traced through the map graph's optimized node poses. |
| `/grid_prob_map` | `nav_msgs/OccupancyGrid` | Probabilistic occupancy grid before thresholding to the final `/map`. |
| `/global_path`, `/global_path_nodes` | `nav_msgs/Path`, `rtabmap_msgs/Path` | RTAB-Map's own global path planning output (map-graph based, separate from Nav2's planner). |
| `/local_path_nodes` | `rtabmap_msgs/Path` | Local segment of the RTAB-Map path graph. |
| `/goal_node` | `rtabmap_msgs/Goal` | Navigation goal expressed as a target node in RTAB-Map's map graph. |
| `/cloud_map`, `/cloud_ground`, `/cloud_obstacles` | `sensor_msgs/PointCloud2` | Assembled 3D map cloud, and its ground/obstacle-classified subsets. |
| `/local_grid_empty`, `/local_grid_ground`, `/local_grid_obstacle` | `sensor_msgs/PointCloud2` | Per-frame local grid classification (free space / ground / obstacle) before merging into the global map. |
| `/octomap_full`, `/octomap_binary` | `octomap_msgs/Octomap` | Full-probability and binary-compressed 3D octree map. |
| `/octomap_grid` | `nav_msgs/OccupancyGrid` | 2D projection of the octomap. |
| `/octomap_occupied_space`, `/octomap_empty_space`, `/octomap_ground`, `/octomap_obstacles`, `/octomap_global_frontier_space` | `sensor_msgs/PointCloud2` | Octomap contents split by cell classification, incl. frontier cells for exploration. |
| `/odom_rgbd_image` | `rtabmap_msgs/RGBDImage` | Synchronized RGB + depth image pair fed into RTAB-Map's odometry. |
| `/odom_sensor_data/raw`, `/odom_sensor_data/features`, `/odom_sensor_data/compressed` | `rtabmap_msgs/SensorData` | Sensor data packaged for odometry at different processing stages (raw, feature-extracted, compressed for transport/logging). |
| `/rtabmap/republish_node_data` | `std_msgs/Int32MultiArray` | Request to republish stored data for specific map-graph node IDs (e.g. for loop-closure review). |
| `/user_data_async` | `rtabmap_msgs/UserData` | Arbitrary extra user data attached asynchronously to map nodes. |
| `/info` | `rtabmap_msgs/Info` | Per-frame RTAB-Map processing stats (loop closure status, timing, memory). |
| `/landmark_detection`, `/landmark_detections` | `rtabmap_msgs/LandmarkDetection(s)` | Detected fiducial/landmark observations fed into the map graph as constraints. |
| `/landmarks` | `geometry_msgs/PoseArray` | Known landmark poses for visualization. |
| `/labels` | `visualization_msgs/MarkerArray` | Text labels (e.g. node IDs) overlaid on the map in RViz/Foxglove. |
| `/env_sensor` | `rtabmap_msgs/EnvSensor` | Generic environmental sensor reading attached to the map (e.g. a gas/temperature sensor). |

## 6. Perception sensors

| Topic | Type | Description |
|---|---|---|
| `/camera/image_raw` | `sensor_msgs/Image` | Raw RGB camera feed. |
| `/camera/depth/image_raw` | `sensor_msgs/Image` | Raw depth image, paired with the RGB feed for RTAB-Map's RGB-D pipeline. |
| `/camera/camera_info` | `sensor_msgs/CameraInfo` | Camera intrinsics/calibration matching the image streams. |
| `/camera/points` | `sensor_msgs/PointCloud2` | Point cloud generated from the depth camera. |
| `/scan` | `sensor_msgs/LaserScan` | 2D lidar scan (Hokuyo via `urg_node`, or simulated equivalent). |
| `/laser_status` | `urg_node_msgs/Status` | Hokuyo driver status/diagnostics (connection state, sensor health). |
| `/gps/fix` | `sensor_msgs/NavSatFix` | GPS position fix. |
| `/apriltag/detections`, `/tag_detections` | `apriltag_msgs/AprilTagDetectionArray` | Detected AprilTag fiducials and their poses. |
| `/aruco/detections` | `aruco_msgs/MarkerArray` | Detected ArUco markers (`aruco_ros`-style). |
| `/aruco_opencv/detections` | `aruco_opencv_msgs/ArucoDetection` | Detected ArUco markers from the `aruco_opencv` node (alternate detector). |

## 7. Hardware interface / controller manager (`ros2_control`)

| Topic | Type | Description |
|---|---|---|
| `/controller_manager/activity` | `controller_manager_msgs/ControllerManagerActivity` | Snapshot of which controllers/hardware interfaces are currently active. |
| `/controller_manager/introspection_data/{names,values,full}` | `pal_statistics_msgs/*` | Named + valued introspection data for live controller debugging. |
| `/controller_manager/statistics/{names,values,full}` | `pal_statistics_msgs/*` | Timing/performance statistics for the controller manager's update loop. |

## 8. System / misc

| Topic | Type | Description |
|---|---|---|
| `/clock` | `rosgraph_msgs/Clock` | Simulation time source (published by Gazebo) when `use_sim_time` is set. |
| `/rosout` | `rcl_interfaces/Log` | Aggregated log messages from all nodes. |
| `/diagnostics` | `diagnostic_msgs/DiagnosticArray` | Structured health/status reports from hardware and software components. |
| `/parameter_events` | `rcl_interfaces/ParameterEvent` | Notifications whenever any node's parameters are declared/changed. |

---

### Notes on the live graph (as observed)

- `/cmd_vel` currently has **10 publishers** (Foxglove bridge, two `teleop_twist_joy_node` instances, `ros_gz_bridge`, `controller_server`, 4× `behavior_server`) and **3** `vel_parser_node` subscriptions — more than one bringup/nav stack appears to be running concurrently in the container (see earlier conversation). Worth cleaning up before relying on manual teleop, since Nav2 will fight your commands if a goal is active.
- The full `/cmd_vel → vel_parser_node → /motors_command → motors_command_parser_node → /velocity_controller/commands + /position_controller/commands` chain was verified live: publishing `linear.x: 0.3` produced `drive_motor: [300,300,300,-300,-300,-300]`, `corner_motor: [500,500,500,500]` on `/motors_command`.
- `/scan` reports errors in the current session (`could not open serial device /dev/ttyACM0`) — expected since no physical Hokuyo is attached; harmless in simulation unless something downstream hard-depends on it.
