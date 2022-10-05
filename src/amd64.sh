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
  if [[ -n "${BIOS_DIR}" ]]; then
    umount "${BIOS_DIR}"
  fi
  if [[ -n "${BIND_MOUNTS}" ]]; then
    umount "${ROOT_DIR}/dev"
    umount "${ROOT_DIR}/proc"
    umount "${ROOT_DIR}/sys"
  fi
  if [[ -n "${ROOT_DIR}" ]]; then
    umount "${ROOT_DIR}"
  fi
  if [[ -n "${ROOT_DEV}" ]]; then
    kpartx -dsv "$output"
  fi
}
trap cleanup EXIT

# Create image
qemu-img create -f raw "${output}" 3G

# Partition
parted -s "${output}" mklabel gpt
parted -s "${output}" mkpart primary fat32 4MiB 8MiB \
  name 1 BIOS \
  set 1 bios_grub on
parted -s "${output}" mkpart ESP fat32 8MiB 136MiB \
  name 2 EFI \
  set 2 esp on
parted -s "${output}" mkpart primary ext4 136MiB 100% \
  name 3 ROOT \
  set 3 msftdata on

# Devices files
mapfile -t LOOP_NAMES< <(kpartx -asv "$output" | awk '{print $3}')

EFI_DEV="/dev/mapper/${LOOP_NAMES[1]}"
ROOT_DEV="/dev/mapper/${LOOP_NAMES[2]}"

DEV=$(kpartx "${output}" | head -n 1 | awk '{print $5}')

# Create filesystems
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

# Bootstrap
src/bootstrap.sh "$ROOT_DIR" amd64 common,amd64 linux-image-amd64 grub-efi-amd64 grub-pc-bin

# Install GRUB
mkdir -p "$ROOT_DIR/dev" "$ROOT_DIR/proc" "$ROOT_DIR/sys"
mount --bind /dev "$ROOT_DIR/dev"
mount --bind /proc "$ROOT_DIR/proc"
mount --bind /sys "$ROOT_DIR/sys"
BIND_MOUNTS=yes

chroot "$ROOT_DIR" update-grub
chroot "$ROOT_DIR" grub-install --target=x86_64-efi --efi-directory=/boot/efi --removable --recheck "${DEV}"
chroot "$ROOT_DIR" grub-install --target=i386-pc --recheck "${DEV}"

df
