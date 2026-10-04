
$container = docker ps -q -f "name=^rover$"

if (-not $container) {
    docker run -dit --rm `
        --name rover `
        -p 8765:8765 `
        rover

    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

docker exec -it rover tmux new-session -A -s rover
