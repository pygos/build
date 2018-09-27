#!/bin/sh

SCRIPTDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)

BOOT="$SCRIPTDIR/bootfs"
OVERLAY="$SCRIPTDIR/overlay"

KERNEL=$(cat "$BOOT/kernel.txt")
CMDLINE=$(cat "$BOOT/cmdline.txt")

RAM="256M"
MAC0="52:54:00:12:34:56"

mkdir -p ${OVERLAY}/{etc,etc_work,usr,usr_work,var_lib,var_lib_work}

qemu-system-x86_64 \
	-drive "file=fat:rw:$BOOT,readonly=off,format=raw,if=virtio" \
	-m "$RAM" -accel kvm -cpu host \
	-vga virtio -display sdl \
	-netdev user,id=netdev0 \
	-device virtio-net-pci,netdev=netdev0,mac="$MAC0" \
	-fsdev "local,id=overlay,path=$OVERLAY,security_model=mapped" \
	-device "virtio-9p-pci,fsdev=overlay,mount_tag=overlay" \
	-kernel "$BOOT/$KERNEL" -append "$CMDLINE"
