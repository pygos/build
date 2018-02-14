#!/bin/sh

set -u -e

CONFIRM="Yes, I am"
DEVICE=$1
MOUNTED=0

function do_cleanup() {
	[ $MOUNTED -ne 0 ] && umount /tmp/mnt.$$
	rmdir /tmp/mnt.$$
}

trap do_cleanup ERR INT

cd `dirname $0`

echo "Are you *really* sure to use $DEVICE?"
echo "If so, type \"$CONFIRM\""
read input
[ "x$input" != "x$CONFIRM" ] && exit 1

[ ! -b $DEVICE ] && {
	echo "Error, $DEVICE is not a block device"
	exit 1
}

count=$(grep -c -e "^$DEVICE" /proc/mounts || true)
[ $count -ne 0 ] && {
	echo "Error, $DEVICE is mounted"
	exit 1
}

dd if=/dev/zero of=$DEVICE bs=512 count=1
parted --script $DEVICE \
	"mklabel msdos" \
	"mkpart primary fat32 1M 256M" \
	"mkpart primary btrfs 256M 100%" \
	"set 1 boot on"

mkfs.vfat ${DEVICE}1
mkfs.btrfs -f ${DEVICE}2

mkdir /tmp/mnt.$$
mount -t vfat ${DEVICE}1 /tmp/mnt.$$
MOUNTED=1

syslinux --install ${DEVICE}1
cp syslinux.cfg /tmp/mnt.$$/syslinux.cfg
cp -r VERSIONDIR /tmp/mnt.$$/

umount /tmp/mnt.$$
MOUNTED=0

mount -t btrfs ${DEVICE}2 /tmp/mnt.$$
MOUNTED=1
mkdir /tmp/mnt.$$/etc /tmp/mnt.$$/etc_work
mkdir /tmp/mnt.$$/var_lib /tmp/mnt.$$/var_lib_work
mkdir /tmp/mnt.$$/root /tmp/mnt.$$/root_work
chmod 750 /tmp/mnt.$$/root /tmp/mnt.$$/root_work
chown 0:0 /tmp/mnt.$$/root /tmp/mnt.$$/root_work
umount /tmp/mnt.$$
MOUNTED=0

rmdir /tmp/mnt.$$

dd if=mbr.bin of=$DEVICE
