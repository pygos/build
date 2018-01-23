#!/bin/sh

set -u -e -x

FILE=$1
MOUNTED=0
LOOPATTACHED=0

function do_cleanup() {
	[ $MOUNTED -ne 0 ] && umount /tmp/mnt.$$
	[ $LOOPATTACHED -ne 0 ] && losetup -d ${LODEV}
	rmdir /tmp/mnt.$$
}

trap do_cleanup ERR INT

cd `dirname $0`

truncate -s 1G $FILE

parted --script $FILE \
	"mklabel msdos" \
	"mkpart primary fat32 1M 256M" \
	"mkpart primary btrfs 256M 100%" \
	"set 1 boot on"

LODEV=$(losetup -f)
losetup -P ${LODEV} ${FILE}
LOOPATTACHED=1

mkfs.vfat ${LODEV}p1
mkfs.btrfs -f ${LODEV}p2

mkdir /tmp/mnt.$$
mount -t vfat ${LODEV}p1 /tmp/mnt.$$
MOUNTED=1

syslinux --install ${LODEV}p1
cp syslinux.cfg /tmp/mnt.$$/syslinux.cfg
cp ROOTFSFILE /tmp/mnt.$$/
cp KERNELFILE /tmp/mnt.$$/

umount /tmp/mnt.$$
MOUNTED=0

mount -t btrfs ${LODEV}p2 /tmp/mnt.$$
MOUNTED=1
mkdir /tmp/mnt.$$/etc /tmp/mnt.$$/etc_work
mkdir /tmp/mnt.$$/var_lib /tmp/mnt.$$/var_lib_work
mkdir /tmp/mnt.$$/root /tmp/mnt.$$/root_work
umount /tmp/mnt.$$
MOUNTED=0

losetup -d ${LODEV}
LOOPATTACHED=0

dd if=mbr.bin of=$FILE conv=notrunc

rmdir /tmp/mnt.$$
