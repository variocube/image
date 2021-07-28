FROM debian:bullseye-slim
RUN apt update
RUN apt install --no-install-recommends -y dosfstools qemu-utils qemu-user-static debootstrap binfmt-support time \
    parted kpartx rsync
