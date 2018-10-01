# Pygos Filesystem Layout

## Sub Hierarchy Merge

The filesystem hierarchy has received some cleanups and simplifications that
typical GNU/Linux distributions don't have. First of all, there is no `/usr`
sub hierarchy split and there is no `/bin` vs `/sbin` split.

The `/usr` split and the `/bin` vs `/sbin` split are historical artifacts. Of
course, over the years, people started to pretend that it was a deliberate
design choice and invented lots of interesting reasoning to justify why this is
the way to go, despite the original technical reasons being obsolete for a
really long time now. Please refer to [this thread on the BusyBox mailing list](http://lists.busybox.net/pipermail/busybox/2010-December/074114.html)
for further discussion.


The directories typically found in `/usr` have been merged back into the
filesystem root (`/usr/bin` and `/usr/sbin` to `/bin`  and `/usr/lib`
to `/lib`).

The `/usr/share` directory containing application data has also been moved to
the filesystem root (i.e. there is a `/share`).

Many systems have a `/usr/libexec` directory containing executables not intended
to be run by people but by programs. This has been moved to `/lib/libexec`.

The `/usr` directory is still present but now serves its original purpose again.
Storing user home directories. For instance, the `/root` directory has been
moved to `/usr/root`.

Since build tools, source code and headers are typically not installed, there
is currently no need to think about where to put `/usr/include` or `/usr/src`.


## Basic Filesystem Mount Points

A compressed, read only squashfs image is mounted to the root node of the
virtual filesystem hierarchy.

The directories `/dev`, `/proc` and `/sys` do not contain any files and are
used as mount points for devtmpfs, procfs and sysfs respectively.

The directories `/tmp`, `/run` and `/var` are used as mount points for tmpfs
mounts. The sub hierarchy in `/var` is constructed during system boot.

See below on how changes to `/var/lib` are persisted and preserved across
reboots.


The directories `/boot` and `/mnt` are used as mount points for temporary
mounts. The former specifically for mounting the boot medium containing the
kernel and squasfs image in order to apply updates, the later for other
temporary mounts.


## Persistent Configuration Changes

A directory `/cfg` was added to implement an overlay mount setup. The directory
`/cfg/preserve` contains the original versions of files built into the
compressed, read only root filesystem.

For instance, the original contents of `/etc` are actually stored in
`/cfg/preserve/etc`.

The directory `/cfg/overlay` is used as a mount point for a read/write
partition that is used to override and persist changes to the base
configuration.

During system boot, an overlay filesystem is mounted to `/etc` with the lower
directory set to `/cfg/preserve/etc` and the upper directory set to
`/cfg/overlay/etc`.

As a result, the `/etc` directory initially contains files stored in the
squashfs image, but changes can be made. The altered files are stored on the
dedicated partition or device mounted to `/cfg/overlay`.


A similar setup is used for the `/var/lib` and the `/usr` directories. The
`/var/lib` directory combines `/cfg/preserve/var_lib` with overlays from
`/cfg/overlay/var_lib`.


This setup allows for simple management of site local configuration changes,
simple backups and a simple "factory reset" (i.e. wiping the overlay partition
or device).

On systems where this is possible, BTRFS is used for the overlay partition.
BTRFS sub volumes can be used to make snapshots of the changed configuration
and if something should break, allows for a simple revert to the last known
good state.


The overlay setup can also be disabled (resulting in bind mounts to
`/cfg/preserve`) or configured to use a tmpfs as backing store.


## Multiarch Directories

Some processors support executing op codes for slightly different architectures.
For instance, many 64 bit processors can be set into 32 bit mode and run 32 bit
programs. Such programs then require additional 32 bit versions of shared
libraries, already built for the 64 bit system, creating the necessity for
having two different versions of the `/lib` directory.


For the time being, it has been decided to not include multiarch support.
All packages are built for a single target architecture. This simplifies both
the build process and the final system as well as reducing the memory footprint
of the system image. A proposal exists for creating a separate `/system32` sub
hierarchy on 64 bit targets that require 32 bit binaries.
