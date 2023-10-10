#!/bin/bash

die() {
	echo -e >&2 "$@"
	exit 1
}

apt -y install wget xz-utils kpartx progress || die "Error: Could not install required packages."

VERSION=$1
if [[ -z "$VERSION" ]] ; then
  die "Error: No version specified as command line argument.\n\nUsage: $0 <version>"
fi

if [[ "$EUID" -ne 0 ]] ; then
  die "Error: This script must be run as root."
fi

VC_USERS=$(cat /etc/passwd | grep variocube | wc -l)
if [[ "$VC_USERS" -eq 0 ]] ; then
  die "Error: No variocube users found, assuming that we are not running on a variocube device."
fi

VARIOCUBE_TEMP_MOUNT_POINT="/mnt/variocube-image"
mkdir -p "${VARIOCUBE_TEMP_MOUNT_POINT}" || die "Error: Could not create temporary mount point ${VARIOCUBE_TEMP_MOUNT_POINT}."

COMPRESSED_IMAGE="$2"

if [[ -z "${COMPRESSED_IMAGE}" ]] ; then
  echo "No path to a compressed image was provided, downloading from GitHub."

  FIRST_USB_STICK="/dev/sda"
  if [[ ! -b "$FIRST_USB_STICK" ]] ; then
    die "Error: No USB drive found."
  fi

  FIRST_USB_STICK_PARTITION="/dev/sda1"
  if [[ ! -b "$FIRST_USB_STICK_PARTITION" ]] ; then
    die "Error: No partition on USB drive found."
  fi

  read -p "We are going to format the USB stick currently connected. Do you really want to continue? (y/n)" -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]] || die "You cancelled the process."

  USB_TEMP_STORAGE="/mnt/usb-tmp-storage"
  mkdir -p "$USB_TEMP_STORAGE" || die "Error: Cannot create mount point for temporary USB storage."
  umount "$USB_TEMP_STORAGE"
  mkfs.ext4 -F "$FIRST_USB_STICK_PARTITION" || die "Error: Cloud not format USB drive."
  mount "$FIRST_USB_STICK_PARTITION" "$USB_TEMP_STORAGE" || die "Error: Could not mount USB drive."

  DOWNLOAD_URL="https://github.com/variocube/image/releases/download/${VERSION}/revpi.img.xz"
  COMPRESSED_IMAGE="$USB_TEMP_STORAGE/revpi-image-${VERSION}.img.xz"
  wget -O "$COMPRESSED_IMAGE" "$DOWNLOAD_URL" || die "Error: Could not download from $DOWNLOAD_URL."
fi

IMAGE="${COMPRESSED_IMAGE%.xz}"
if [[ "$COMPRESSED_IMAGE" == *.txt ]] ; then
  echo "Image ${COMPRESSED_IMAGE} is compressed, decompressing."
  xz -d "$COMPRESSED_IMAGE" || die "Error: Could not decompress image."
else
  echo "Image is not compressed using as is."
  IMAGE="$COMPRESSED_IMAGE"
fi

# TODO check image checksum

# TODO mount image as loopback device
losetup -f "${IMAGE}" || die "Error: Could not mount image ${IMAGE} as loopback device (losetup failed)."
LOOP_DEVICE=$(losetup --list | grep ${IMAGE} | head -1 | cut -f1 -d " ")
if [[ -z "$LOOP_DEVICE" ]] ; then
  die "Error: Could not mount image ${IMAGE} as loopback device (no loopback device found)."
fi

echo "Image ${IMAGE} setup as loopback device ${LOOP_DEVICE}, reading partition table."
kpartx -a "${LOOP_DEVICE}" || die "Error: Could not read partition table."

LOOP_DEVICE_NAME=$(basename "$LOOP_DEVICE")
VARIOCUBE_OS_PARTITION="/dev/mapper/${LOOP_DEVICE_NAME}p2"
mount "$VARIOCUBE_OS_PARTITION" "$VARIOCUBE_TEMP_MOUNT_POINT" || die "Error: Could not mount variocube image partition (${VARIOCUBE_OS_PARTITION} to ${VARIOCUBE_TEMP_MOUNT_POINT})."

echo "Mounted variocube image partition (${VARIOCUBE_OS_PARTITION}) to ${VARIOCUBE_TEMP_MOUNT_POINT}, configuring image."

echo "Copying /etc/hostname to image."
cp -a /etc/hostname "${VARIOCUBE_TEMP_MOUNT_POINT}/etc/hostname" || die "Error: Could not copy /etc/hostname to image."

echo "Unmounting variocube image partition (${VARIOCUBE_TEMP_MOUNT_POINT})."
umount "$VARIOCUBE_TEMP_MOUNT_POINT" || die "Error: Could not unmount variocube image partition (${VARIOCUBE_TEMP_MOUNT_POINT})."

echo "Unloading partition table"
kpartx -d "${LOOP_DEVICE}" || die "Error: Could not unload partition table."

echo "Detaching loopback device ${LOOP_DEVICE}."
losetup -d "${LOOP_DEVICE}" || die "Error: Could not detach loopback device ${LOOP_DEVICE}."

ROOT_BLOCK_DEVICE=/dev/mmcblk0
read -p "Image is prepared do you want to flash the prepared image ${IMAGE} to the root block device ${ROOT_BLOCK_DEVICE}? ATTENTION, this is the point of no return - do not power of the device or unplug the USB drive until the device reboots. (y/n)" -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] || die "You cancelled the process."

echo "Remounting (root partition) / as read only."
mount -f -o remount,ro / || die "Error: Could not remount (root partition) / as read only."

echo "Copying image ${IMAGE} to root block device ${ROOT_BLOCK_DEVICE}."
dd if="${IMAGE}" of="${ROOT_BLOCK_DEVICE}" bs=4M status=progress || die "Error: Could not copy image ${IMAGE} to root block device ${ROOT_BLOCK_DEVICE}."

echo "Syncing unwritten blocks to disk."
sync
echo "Rebooting"
reboot