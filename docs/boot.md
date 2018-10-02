# Pygos Boot Process

The boot loader of the board loads the Linux kernel (and possibly device tree
files) into memory and jumps into the kernel.

The Linux kernel of the Pygos system has an initial ram disk built in with a
small setup script that mounts the actual root file system, an overlay
filesystem and does a switch_root.


## Filesystem Setup

The init script processes the following parameters from the kernel
command line to set up the VFS root:

 * `root` the path to a device file containing the root filesystem image.
   This parameter is mandatory.
 * `root_sfs` the path to a Squashfs image on the `root` device. If this
   parameter is missing, the `root` partition is mounted to the VFS root
   instead of the Squashfs image.
 * `overlay_dev` the path to a device file containing the overlay filesystem.
   The device is mounted to `/cfg/overlay` and an overlay mount to `/etc` is
   created with the lower directory in `/cfg/preserve/etc` and the upper
   in `/cfg/overlay/etc`. If the `overlay_dev` parameter is omitted, a bind
   mount to `/cfg/preserve/etc` is created instead.


The additional parameters `root_type` and `overlay_type` can be used to specify
additional mount options for the boot and overlay partitions respectively.

The following type options are currently supported:

 * `hwdevice` (default if the option is missing). Wait in a loop until the
   specified device special file exists, then attempt to mount it and let
   the kernel auto-detect the filesystem.
 * `qemu` specifies that the device is actually a mount tag for a virtio
   connected 9p network filesystem.
 * Every other option is passed to the `mount` command as filesystem type
   without waiting for the device file to be present.


After mounting the `overlay_dev` device, the script populates the mount point
with expected default directories, so even a freshly formatted filesystem
partition can be used without further preparation.


## Examples

The following kernel command line mounts a the Squashfs image `rootfs.img`
stored on `/dev/sda1` to the filesystem root with a `tmpfs` overlay:

	root=/dev/sda1 root_sfs=rootfs.img overlay_dev=none overlay_type=tmpfs


For a Qemu virtual machine, the following command line mounts a virtio attached
disk to the filesystem root and attaches as overlay device a directory on the
host system via a virtio attached 9p network mount:

	root=/dev/vda1 overlay_dev=ovdef overlay_type=qemu


## Switchroot Transition

Once the setup script completes, it switches to the newly mounted and
configured filesystem root.

If the option `singleuser` is present on the kernel command line, it executes
a shell, otherwise it launches the init system.
