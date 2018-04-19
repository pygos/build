#!/bin/sh

set -u -e

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

if [ -e "$FILE" ]; then
	echo "Error, $FILE exists"
	exit 1
fi

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

cp -r boot/* /tmp/mnt.$$/

umount /tmp/mnt.$$
MOUNTED=0

mount -t btrfs ${LODEV}p2 /tmp/mnt.$$
MOUNTED=1
mkdir /tmp/mnt.$$/etc /tmp/mnt.$$/etc_work
mkdir /tmp/mnt.$$/var_lib /tmp/mnt.$$/var_lib_work
mkdir -p /tmp/mnt.$$/usr/root /tmp/mnt.$$/usr_work
chmod 750 /tmp/mnt.$$/usr/root /tmp/mnt.$$/usr_work
chown 0:0 /tmp/mnt.$$/usr/root
umount /tmp/mnt.$$
MOUNTED=0

losetup -d ${LODEV}
LOOPATTACHED=0

rmdir /tmp/mnt.$$
