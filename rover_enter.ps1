
$container = docker ps -q -f "name=^rover$"

if (-not $container) {
    docker run -dit --rm `
        --name rover `
        -p 8765:8765 `
        --shm-size=512m `
        rover

    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

# Create the session once: left pane runs the moon simulation, right pane runs the Foxglove bridge
docker exec rover tmux has-session -t rover 2>$null

if ($LASTEXITCODE -ne 0) {
    docker exec rover tmux new-session -d -s rover
    docker exec rover tmux split-window -h -t rover:0
    docker exec rover tmux send-keys -t rover:0.1 "foxglove" Enter
    docker exec rover tmux send-keys -t rover:0.0 "ros2 launch rover_gazebo moon.launch.py" Enter
    docker exec rover tmux select-pane -t rover:0.0
}

docker exec -it rover tmux attach-session -t rover
