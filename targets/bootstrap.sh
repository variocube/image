#!/usr/bin/env bash

TARGET=$1
ROOT_DIR=$2
ARCH=$3

shift 3

usage() {
  echo "Usage: $0 TARGET ROOT_DIR ARCH PACKAGES..."
  exit 1
}

if [[ -z "$TARGET" ]]; then
  echo "TARGET not specified."
  usage
fi

if [[ ! -d "$ROOT_DIR" ]]; then
  echo "ROOT_DIR not specified, or directory does not exist."
  usage
fi

if [[ -z "$ARCH" ]]; then
  echo "ARCH not specified."
  usage
fi

set -e
set -x

# Copy common rootfs
rsync -rptv "rootfs/common/" "${ROOT_DIR}/"

# Copy target specific rootfs
rsync -rptv "rootfs/${TARGET}/" "${ROOT_DIR}/"

# Bootstrap base system
debootstrap --arch "$ARCH" \
  --components main,contrib,non-free \
  bullseye "$ROOT_DIR" http://deb.debian.org/debian

# Install packages
chroot "$ROOT_DIR" apt-get update
chroot "$ROOT_DIR" apt-get install -y --no-install-recommends \
  systemd-sysv locales sudo \
  netcat iproute2 iputils-ping iw wpasupplicant \
  usbutils lshw \
  parted dosfstools \
  ssh \
  vim less gnupg curl \
  variocube-unit variocube-app-host \
  "$@" # additional packages supplied as arguments

# Clean up archive cache (likely not useful) and lists (likely outdated) to
# reduce image size by several hundred megabytes.
chroot "$ROOT_DIR" apt-get clean
chroot "$ROOT_DIR" rm -rf /var/lib/apt/lists

# Clear /etc/machine-id and /var/lib/dbus/machine-id, as both should
# be auto-generated upon first boot. From the manpage
# (machine-id(5)):
#
#   For normal operating system installations, where a custom image is
#   created for a specific machine, /etc/machine-id should be
#   populated during installation.
#
# Note this will also trigger ConditionFirstBoot=yes for systemd.
chroot "$ROOT_DIR" rm -f /etc/machine-id /var/lib/dbus/machine-id
