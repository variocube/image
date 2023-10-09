#!/bin/bash

die() {
	echo -e >&2 "$@"
	exit 1
}

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

mkfs.ext4 "$FIRST_USB_STICK_PARTITION" || die "Error: Cloud not format USB drive."
USB_TEMP_STORAGE="/mnt/usb-tmp-storage"
mkdir -p "$USB_TEMP_STORAGE" || die "Error: Cannot create mount point for temporary USB storage."
mount "$FIRST_USB_STICK_PARTITION" "$USB_TEMP_STORAGE" || die "Error: Could not mount USB drive."

DOWNLOAD_URL="https://github.com/variocube/image/releases/download/${VERSION}/revpi.img.xz"
curl -o "$USB_TEMP_STORAGE/current-image.img.xz" "$DOWNLOAD_URL" || die "Error: Could not download from $DOWNLOAD_URL."

# TODO unpack image
# TODO check image checksum
# TODO mount image as loopback device
# TODO write current hostname to /etc/hostname
# TODO unmount image
# TODO remount / as readonly
# TODO dd image to mmc block device
# TODO reboot