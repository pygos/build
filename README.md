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
*reindeerflotilla*.

## Target configuration

The Pygos build system is driven by toolchain and package configurations
that are divided into three categories:

 - Common settings shared by all targets
   - Contains things like a bare minimum default package set
 - Board specific settings
   - Mostly board specific cross toolchain and kernel configuration
   - Can add additional packages required for that board
 - Product specific settings
   - Specifies a list of boards for which the product can be built
   - Specifies and configures extra packages needed
   - Can override board settings and provide configuration files
     specific to *that* product running on *that* board

### Demo configuration

The system currently contains configurations that allows it to run on the
following boards:

 - Raspberry Pi 3 (ARM, 32 bit)
 - pc-engines ALIX board (x86, 32 bit)

The following demo products for those boards are planned, but currently
still in development:

 - "router" builds for all of the above boards. A DHCP server offers
   addresses on two of the ALIX boards Ethernet ports or on the
   Raspberry Pi 3 wireless interface. A DHCP client configures the
   remaining interface, uses it as default route and does NAT routing.
   DNS queries are resolved via a local root resolver.


## How to build the system

The system can be built by running the mk.sh script as follows:

    mk.sh <board> <product>

This will start to download and builds the cross toolchain and system in the
current working directory. The command can (and should) be run from somewhere
outside the source tree.

Once the script is done, the final release package is stored in the following
location (relative to the build directory):

    deploy/release-<board>/release-<board>.tar.gz

## Directory overview

The build system directory contains the following files and sub directories:

 - board/
     Contains the board specific configuration files. E.g. board/alix/ holds
     files specific for the ALIX board.
 - docs/
     Contains further documentation that goes into more detailed aspects of
     the build system and the final Pygos installation itself.
 - pkg/
     Contains package build scripts. Each package occupies a sub directory
     with a script named "build" that is used to download, compile and
     install the package.
 - product/
     Contains product specific configuration files. E.g. product/router/ holds
     files for the "router" product.
 - util/
     Contains utility scripts used by mk.sh
 - LICENSE
     A copy of the GNU GPLv3
 - mk.sh
     The main build script that builds the entire system
 - README.md
     This file

