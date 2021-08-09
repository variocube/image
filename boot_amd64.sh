#!/usr/bin/env bash

sudo qemu-system-x86_64 -smp 2 -enable-kvm -m 1024 -boot once=c,menu=off -net user -name variocube-amd64 build/amd64.img