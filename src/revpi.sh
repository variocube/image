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

qemu-img create -f raw "${output}" 3G

parted -s "${output}" mklabel msdos
parted -s "${output}" mkpart primary fat32 4MiB 260MiB
parted -s "${output}" mkpart primary ext4 260MiB 100%

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
src/bootstrap.sh "$ROOT_DIR" armhf common,raspi3,revpi binutils linux-image-armmp

# Install and run rpi-update
curl -L --output "$ROOT_DIR"/usr/sbin/rpi-update https://raw.githubusercontent.com/raspberrypi/rpi-update/master/rpi-update
chmod +x "$ROOT_DIR"/usr/sbin/rpi-update
chroot "$ROOT_DIR" env        \
  ROOT_PATH=/                 \
  BOOT_PATH=/boot/firmware    \
  SKIP_WARNING=1              \
  WANT_32BIT=1                \
  WANT_64BIT=1                \
  WANT_PI4=1                  \
  /usr/sbin/rpi-update

cat >"$FIRMWARE_DIR"/cmdline.txt <<- EOF
dwc_otg.lpm_enable=0 console=tty1 root=LABEL=ROOT rootfstype=ext4 elevator=deadline rootwait quiet splash
EOF

cat >"$FIRMWARE_DIR"/config.txt <<- EOF
hdmi_drive=2
hdmi_force_hotplug=1
initramfs initrd.img

[pi4]
[cm4s]
dtoverlay=dwc2,dr_mode=host

EOF