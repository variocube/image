#!/usr/bin/env bash

set -e

targets=${*:-amd64 raspi3 revpi3}

echo "Building targets: ${targets}"

echo "Creating build directory"
mkdir -p ./build

vagrant up
vagrant rsync
vagrant ssh-config >.vagrant/ssh-config

# Build targets
for target in ${targets}
do
  echo "Building ${target}"
  vagrant ssh -c "cd / && sudo src/${target}.sh /image.img"
  scp -F .vagrant/ssh-config default:/image.img "./build/${target}.img"
done

vagrant halt
