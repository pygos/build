# Pygos GNU/Linux

## Overview

This directory contains the build system for Pygos GNU/Linux, a small, heavily
customizable operating system for embedded devices and other special purpose
systems.

The build system generates a compressed, read only root filesystem image, boot
loader, kernel binary and a setup script for installing the system on the target
board, all bundled up in a release tar ball.

An additional disk partition or UBI volume is created for mutable configuration
files with overlay mount points for directories like /etc or /var/lib.

For details on the Pygos file system layout, see
[docs/filesystem.md](docs/filesystem.md).

An automated firmware update mechanism is currently still in development.
For details, see [docs/update.md](docs/update.md).

The build system in this directory downloads the necessary source packages,
builds a cross compiler toolchain and compiles the entire system from scratch
for the intended target.

For details on how the build system works or how to add or configure packages,
see [docs/build.md](docs/build.md).

For an overview of the available documentation see [docs/index.md](docs/index.md).

By the way, before you ask: the default root password for the demo setup is
*reindeerflotilla*. The baud rate on the ALIX board is set to *38400* and on
all other boards to *115200*.

The wireless network is called *Pygos Demo Net* and the password
is *righteous*.

## Target configuration

The Pygos build system is driven by toolchain and package configurations
that are split across multiple *layers*.

From the product name, a layer configuration file in the `product` sub
directory is read, specifying what configuration layers to use and in
what order (later layers can override earlier layers).

The actual configuration for the build system is in the coresponding sub
directories in `layer/<name>`.

For details on the configuration layers see [docs/layers.md](docs/layers.md).


### Demo configuration

The system currently contains configurations for the following products:

 - `qemu-test` - A simple target for testing with Qemu (64 bit x86). The boot
   partition is a directory that is exposed as VFAT formated virtio drive.
   The overlay partition is a local directory mounted via 9PFS via virtio.

 - `router-alix` - A pc-engines ALIX board based router (32 bit x86). A DHCP
   server serves IP addresses on the first two interfaces and configures the
   board as default gateway and DNS server. DNS queries are resulved using
   a local unbound resolver. The remaining interface is configured via DHCP
   and packets from the first two are NAT translated and forwarded. The two
   ports have different IP subnets and are not allowed to talk to each other.
   A local SSH server can be reached via the first two ports. A user has to
   be added first, since root login is disabled. A local Nginx web server
   can be reached via the first two ports that serves a simple demo landing
   page.

 - `router-rpi3` - A Raspberry Pi 3 based wireless access point (32 bit ARM).
   A DHPC server serves IP addresses and configures the board as default
   gateway and DNS server. DNS queries are resolved using a local unbound
   resolver. The ethernet interface is configured via DHCP and packets
   are NAT translated and forwarded. A local SSH server can be reached on the
   WLAN interface. A user has to be added first, since root login is disabled.
   A local Nginx web server can be reached on the WLAN interface that serves
   a simple demo landing page.


## How to build the system

The system can be built by running the mk.sh script as follows:

    mk.sh <product>

This will start to download and build the cross toolchain and system in the
current working directory. The command can (and should) be run from somewhere
outside the source tree.

Once the script is done, the final release package is stored in the following
location (relative to the build directory):

    <product>/deploy/release-<board>/release-<board>.tar.gz

## Directory overview

The build system directory contains the following files and sub directories:

 - docs/
     Contains further documentation that goes into more detailed aspects of
     the build system and the final Pygos installation itself.
 - layer/
     Contains the layer specific configuration files. E.g. layer/bsp-alix/
	 contains a base configuration for building images for the ALIX board.
 - pkg/
     Contains package build scripts. Each package occupies a sub directory
     with a script named "build" that is used to download, compile and
     install the package.
 - product/
     Contains product configurations. E.g. product/router-alix.layers holds
     the list of layers to apply to build the `router-alix` product.
 - util/
     Contains utility scripts used by mk.sh
 - LICENSE
     A copy of the GNU GPLv3
 - mk.sh
     The main build script that builds the entire system
 - README.md
     This file
