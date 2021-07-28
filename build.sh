#!/usr/bin/env bash

set -e

targets=${*:-amd64 raspi3}

echo "Building targets: ${targets}"

echo "Building build environment"
docker build -t buildenv ./buildenv

echo "Creating build directory"
mkdir -p ./build

# Runs a command in the build environment
docker_run() {
  docker run --privileged \
    -v "$(pwd)/build:/build" \
    -v "$(pwd)/targets:/targets" \
    -v "$(pwd)/rootfs:/rootfs" \
    -v "/proc:/proc" \
    -v "/dev:/dev" \
    -v "/sys:/sys" \
    buildenv "$@"
}

# Build targets
for target in ${targets}
do
  echo "Building ${target}"
  docker_run "/targets/${target}/build.sh" "/build/${target}.img"
done

