# Image

Image builder for Variocube OS on multiple architectures.

Inspired by:
 - https://salsa.debian.org/raspi-team/image-specs/-/tree/master
 - https://github.com/onlinegroupat/variocube_os_image

Bootstrapping, especially cross-arch with qemu, heavily depends on the Kernel and qemu version. It is required to
run this on a fairly recent version of a Debian-based distribution:
 - In a virtual machine with the Vagrant setup included in this repo (see [vagrant_build.sh](vagrant_build.sh) and [Vagrantfile](Vagrantfile)) using Debian Bullseye
 - On GitHub using the new `ubuntu-22.04` image (see [release workflow](.github/workflows/release.yml))

TODO:
 - boot graphics (grub, plymouth, transition to X)

## initramfs

Across all targets an initramfs is deployed that does the following:

 - Show a simple text based splash screen (might be replaced with graphical boot)
 - Resize the root filesystem to the available disk space
 - Generate the hostname (UUID)

## Targets

### amd64

The `amd64` image supports both BIOS and EFI boot, each requiring a separate partition. The build installs GRUB with
both the `x86_64-efi` and the `i386-pc` target.

Please note that the BIOS partition is not meant to be mounted and therefore not listed in `/etc/fstab`. It serves
as additional space for grub to store its `core.img`.

### raspi3

The `raspi3` target uses the mainline kernel and the `arm64` architecture.

The image contains a boot partition with the firmware required for boot. 

### revpi

The Compute Module in the RevolutionPi does not work with the mainline kernel. Therefore, we use `rpi-update` to
install the firmware and kernel to the boot partition. Please note that this setup also requires using the `armhf`
architecture.

The `revpi` image is confirmed to run on:
 - RevPi Core S
 - RevPi Core 3+

We still need an init ramdisk to resize the root fs. Therefore, we do install a mainline kernel. Once it supports
the RevolutionPi, an upgrade is basically installing `raspi-firmware`. This would automatically replace the existing
firmware with the one from the mainline kernel.

## Resources

 - https://elinux.org/R-Pi_Troubleshooting#Coloured_splash_screen
 - https://raspi.debian.net/
 - https://www.raspberrypi.org/documentation/configuration/config-txt/boot.md
 - https://salsa.debian.org/debian/raspi-firmware/
 - https://github.com/Hexxeh/rpi-update/blob/master/rpi-update