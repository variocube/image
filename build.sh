#!/usr/bin/env bash

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
    -v "$(pwd)/config:/config" \
    -v "$(pwd)/rootfs:/rootfs" \
    -v "$(pwd)/rootfs-amd64:/rootfs-amd64" \
    -v "/proc:/proc" \
    -v "/dev:/dev" \
    buildenv "$@"
}

# Build targets
for target in ${targets}
do
  echo "Building ${target}"
  docker_run /usr/bin/vmdb2 \
    --rootfs-tarball "/build/${target}_rootfs.tar.gz" \
    --log "/build/${target}.log" \
    --output "/build/${target}.img" \
    "/config/${target}.yaml"
done
