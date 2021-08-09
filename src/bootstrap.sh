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
rsync -rptv "src/rootfs/common/" "${ROOT_DIR}/"

# Copy target specific rootfs
rsync -rptv "src/rootfs/${TARGET}/" "${ROOT_DIR}/"

# Bootstrap base system
debootstrap --arch "$ARCH" \
  --components main,contrib,non-free \
  bullseye "$ROOT_DIR" http://deb.debian.org/debian

# Install packages
chroot "$ROOT_DIR" apt-get update
chroot "$ROOT_DIR" env DEBIAN_FRONTEND=noninteractive apt-get install \
  -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" --force-yes -y --no-install-recommends \
    systemd-sysv locales sudo \
    netcat iproute2 iputils-ping iw wpasupplicant \
    usbutils lshw \
    parted dosfstools \
    ssh \
    vim less gnupg curl ca-certificates \
    "$@" # additional packages supplied as arguments

# Create variocube user
echo "Creating user variocube..."
chroot "$ROOT_DIR" adduser --system --shell /bin/bash --home /home/variocube --group variocube
chroot "$ROOT_DIR" usermod -a -G sudo variocube
echo "variocube:ooCoo1uv!" | chroot "$ROOT_DIR" chpasswd

# Set hostname
echo "variocube" >${ROOT_DIR?}/etc/hostname

# Clear SSH host keys, so they get regenerated on first boot
rm -f ${ROOT_DIR?}/etc/ssh/ssh_host_*_key*

# Print df here, because that's the max space we need
df

# Clean up archive cache (likely not useful) and lists (likely outdated) to
# reduce image size by several hundred megabytes.
chroot "$ROOT_DIR" apt-get clean
chroot "$ROOT_DIR" rm -rf /var/lib/apt/lists

# Clear /etc/machine-id, as it should be auto-generated upon first boot.
# Note this will also trigger ConditionFirstBoot=yes for systemd.
chroot "$ROOT_DIR" truncate -s0 /etc/machine-id
