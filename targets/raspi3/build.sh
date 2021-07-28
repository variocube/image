#!/usr/bin/env bash

set -e
set -x

output="$1"

if [[ -z "$output" ]]; then
  echo "No output specified";
  exit 1;
fi

cleanup() {
  echo "Cleaning up..."
  if [[ -n "${FIRMWARE_DIR}" ]]; then
    umount "${FIRMWARE_DIR}"
  fi
  if [[ -n "${ROOT_DIR}" ]]; then
    umount "${ROOT_DIR}"
  fi
  if [[ -n "${ROOT_DEV}" ]]; then
    kpartx -dsv "$output"
  fi
}
trap cleanup EXIT

qemu-img create -f raw "${output}" 1500M

parted -s "${output}" mklabel msdos
parted -s "${output}" mkpart primary fat32 4MiB 68MiB
parted -s "${output}" mkpart primary ext4 68MiB 100%

mapfile -t LOOP_NAMES< <(kpartx -asv "$output" | awk '{print $3}')

FIRMWARE_DEV="/dev/mapper/${LOOP_NAMES[0]}"
ROOT_DEV="/dev/mapper/${LOOP_NAMES[1]}"

echo "Creating filesystems..."
mkfs -t vfat -n FIRMWARE "$FIRMWARE_DEV"
mkfs -t ext4 -L ROOT "$ROOT_DEV"

# Mount root
ROOT_DIR=$(mktemp -d -p /mnt rootfs-XXXXXX)
mount "$ROOT_DEV" "$ROOT_DIR"

# Mount firmware
FIRMWARE_DIR="$ROOT_DIR/boot/firmware"
mkdir -p "$FIRMWARE_DIR"
mount "$FIRMWARE_DEV" "$FIRMWARE_DIR"

# Bootstrap
targets/bootstrap.sh raspi3 "$ROOT_DIR" arm64 raspi3-firmware linux-image-arm64 firmware-brcm80211

