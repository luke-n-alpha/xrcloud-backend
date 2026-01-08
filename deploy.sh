#!/bin/bash
set -e
cd "$(dirname "$0")"

# ENV 파일을 .env로 복사
cp "$ENV" .env

. $ENV

# Check if package-lock.json exists and run npm install if it doesn't
if [ ! -f "package-lock.json" ]; then
    echo "package-lock.json not found. Running npm install..."
    npm install
fi

DOCKER_CONTAINER=$(basename "$PWD")
DOCKER_IMAGE="$DOCKER_CONTAINER:$(date +%s)"

docker network create xrcloud || true

docker_compose() {
    export ENV DOCKER_CONTAINER DOCKER_IMAGE LOG_DIRECTORY STORAGE_DIR
    docker compose -f ./docker-compose.yml --env-file $ENV $@
}

docker_compose --profile service down
docker_compose --profile service up -d --build
