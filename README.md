# Image

Image builder for Variocube OS.

Inspired by:
 - https://salsa.debian.org/raspi-team/image-specs/-/tree/master
 - https://github.com/onlinegroupat/variocube_os_image

Bootstrapping, especially cross-arch with qemu, heavily depends on the Kernel and qemu version. Therefore, it's best
to build the image in virtual machine running the target system version (for now: bullseye).   

TODO:
 - open ssh server does not start
 - variocube-unit: npm rebuild fails during bootstrap
 - locale: https://askubuntu.com/questions/599808/cannot-set-lc-ctype-to-default-locale-no-such-file-or-directory
 - build on Github

## initramfs

Across all targets an initramfs is deployed that does the following:

 - Resize the root filesystem to the available disk space
 - Generate the hostname (UUID)

## Targets

### amd64

The `amd64` image supports both BIOS and EFI boot, each requiring a separate partition. The build installs GRUB with
both the `x86_64-efi` and the `i386-pc` target.

Please note that the BIOS partition is not meant to be mounted and therefore not listed in `/etc/fstab`. It serves
as additional space for grub to store its `core.img`.

### raspi3

The `raspi3` image contains a boot partition with the firmware required for boot. 

### revpi

The compute module in the RevolutionPi does not work with the mainline kernel. Therefore we use `rpi-update` to
install the firmware and kernel to the boot partition.

We still need an init ramdisk to resize the root fs. Therefore, we do install a mainline kernel. Once it supports
the RevolutionPi, an upgrade is basically installing `raspi-firmware`. This would automatically replace the existing
firmware with the one from the mainline kernel.

## Packages

Currently, the image only contains the `variocube-unit` package. Other packages must be installed on the running system.

It would be desirable to install `variocube-kiosk` and `variocube-app-host`, but this is prevented by a SEGFAULT during
installation of python when running on qemu.

## Resources

 - https://elinux.org/R-Pi_Troubleshooting#Coloured_splash_screen
 - https://raspi.debian.net/
 - https://www.raspberrypi.org/documentation/configuration/config-txt/boot.md
 - https://salsa.debian.org/debian/raspi-firmware/
 - https://github.com/Hexxeh/rpi-update/blob/master/rpi-update