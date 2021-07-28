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
  if [[ -n "${EFI_DIR}" ]]; then
    umount "${EFI_DIR}"
  fi
  if [[ -n "${ROOT_DIR}" ]]; then
    umount "${ROOT_DIR}/dev"
    umount "${ROOT_DIR}/proc"
    umount "${ROOT_DIR}/sys"
    umount "${ROOT_DIR}"
  fi
  if [[ -n "${ROOT_DEV}" ]]; then
    kpartx -dsv "$output"
  fi
}
trap cleanup EXIT

qemu-img create -f raw "${output}" 1500M

parted -s "${output}" mklabel gpt
parted -s "${output}" mkpart ESP fat32 4MiB 132MiB \
  name 1 EFI \
  set 1 esp on
parted -s "${output}" mkpart primary ext4 132MiB 100% \
  name 2 ROOT \
  set 2 msftdata on

mapfile -t LOOP_NAMES< <(kpartx -asv "$output" | awk '{print $3}')

EFI_DEV="/dev/mapper/${LOOP_NAMES[0]}"
ROOT_DEV="/dev/mapper/${LOOP_NAMES[1]}"

echo "Creating filesystems..."
mkfs -t vfat -n EFI "$EFI_DEV"
mkfs -t ext4 -L ROOT "$ROOT_DEV"

# Mount root
ROOT_DIR=$(mktemp -d -p /mnt rootfs-XXXXXX)
mount "$ROOT_DEV" "$ROOT_DIR"

# Mount EFI
EFI_DIR="$ROOT_DIR/boot/efi"
mkdir -p "$EFI_DIR"
mount "$EFI_DEV" "$EFI_DIR"

mkdir -p "$ROOT_DIR/dev" "$ROOT_DIR/proc" "$ROOT_DIR/sys"
mount --bind /dev "$ROOT_DIR/dev"
mount --bind /proc "$ROOT_DIR/proc"
mount --bind /sys "$ROOT_DIR/sys"

# Bootstrap
targets/bootstrap.sh amd64 "$ROOT_DIR" amd64 linux-image-amd64 grub-efi-amd64

chroot "$ROOT_DIR" update-grub
chroot "$ROOT_DIR" grub-install
