#!/usr/bin/env bash

qemu-img resize build/revpi.img 4G

qemu-system-aarch64 \
  -kernel build/revpi.img-firmware/kernel8.img \
  -dtb build/revpi.img-firmware/bcm2710-rpi-3-b.dtb \
  -initrd build/revpi.img-firmware/initrd.img \
  -append "root=/dev/mmcblk0p2 console=ttyAMA0,115200" \
  -machine raspi3b \
  -cpu cortex-a53 \
  -serial stdio \
  -device usb-net,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::5022-:22 \
  -drive id=hd-root,file=build/revpi.img,format=raw \
  -usbdevice keyboard \
  -name variocube-revpi
