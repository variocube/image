#!/usr/bin/env bash

# TODO: we need the kernel and initrd for booting the revpi image.
# They should be extracted during build.
# A nic might be emulated by default, but would need to be configured.

sudo qemu-system-aarch64 \
  -machine raspi3b \
  -smp 4 -m 1024 \
  -serial stdio \
  -drive file=build/revpi.img,format=raw,index=0,media=disk \
  -boot once=c,menu=off,strict=off \
  -name variocube-revpi
# -kernel build/revpi/kernel.img
# -initrd build/revpi/initrd.img