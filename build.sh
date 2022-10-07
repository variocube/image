#!/usr/bin/env bash

set -e

targets=${*:-amd64 raspi3 revpi}

echo "Building targets: ${targets}"

echo "Creating build directory"
mkdir -p ./build

# Build targets
for target in ${targets}
do
  echo "Building ${target}"
  "src/${target}.sh" "./build/${target}.img"
done
