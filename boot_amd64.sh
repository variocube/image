#!/usr/bin/env bash

sudo qemu-system-x86_64 -smp 2 -enable-kvm -m 1024 \
  -drive file=build/amd64.img,format=raw,index=0,media=disk \
  -boot once=c,menu=off -net user -name variocube-amd64