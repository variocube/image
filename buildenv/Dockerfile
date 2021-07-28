FROM debian:bullseye-slim
RUN apt update
RUN apt install -y vmdb2 dosfstools qemu-utils qemu-user-static debootstrap binfmt-support time kpartx
VOLUME ["/build"]
