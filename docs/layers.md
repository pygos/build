# Build System Layers

The layer configuration is currently organized into 4 different kinds
of layers:

* BSP layers that configure the toolchain and kernel build for a
  specific board. All other layers are stacked on top.
* Mid-level program layers that simply add generic programs of some kind.
  For instance `pygos-cli` configures packages for a simple, command line
  based system on top of a BSP layer.
* Product base layers that add hardware independent configuration for a
  specific kind of product. For instance `router-base` adds programs and
  configurations for the `router` group of products, but that don't depend
  on the specific board.
* Product and board specific layers that add the missing configuration for a
  product running on a *specific* board. For instance `router-rpi3` adds the
  final configurations to the `router-base` product for the Raspberry Pi 3.


As an example, the product `router-rpi` currently uses the following layer
configuration:

	bsp-rpi3
	pygos-cli
	pygos-cli-net
	router-base
	router-rpi3


## Layer Index

This section contains an overview of the currently available configuration
layers.

### BSP Layers

 - `bsp-alix` configures the cross toolchain for the AMD Geode LX based
   PC Engines brand ALIX 2d3 or 2d13 board (3 Ethernet ports, real time clock).
   A main line LTS kernel is used. The kernel configuration is tuned for
   usage as some kind of network appliance. The release package is
   called `release-alix` and contains a shell script for installing on a CF
   card or generating a disk image that can be dumped onto a CF card.

 - `bsp-rpi3` configures the cross toolchain for the Raspberry Pi 3. The output
   is 32 bit ARM code. The kernel is a recent vendor kernel supplied by the
   Raspberry Pi foundation. The kernel config is mostly based on the upstream
   default config with additional networking options enabled and many options
   not used by the Pygos system disabled (filesystem drivers, etc.). The
   release package is called `release-rpi3` and contains a shell script
   for installing on a micro SD card or generating an image for a micro
   SD card.

 - `bsp-qemu64` configures the cross toolchain for a generic 64 bit x86 target.
   The main line LTS kernel with a stripped down default and kvm config. The
   release package is called `release-qemu` and contains a shell script for
   running the system using direct kernel boot in a KVM accelerated Qemu with
   a virtio GPU, virtio network card with user mode networking and overlay
   partition on a 9PFS mounted host directory.

### Mid-level Program Layers

 - `pygos-cli` is the base layer for command line interface based images.
   It adds the `bash` shell, the init system and basic command line programs
   like `coreutils`.

 - `pygos-cli-net` adds command line programs for networked systems such as
   `ldns`, `nftables` or `iproute2`.

### Product Specific Layers

 - `router-base` contains basic configuration for the router class of products.
   It adds `unbound`, `dnsmasq`, `openssh`, `nginx` and `tcpdump`. The kernel
   parameters are configured to enable IP forwarding, `resolv.conf` is set to
   resolve names through the local DNS resolver.

 - `router-alix` extends `router-base` with interface configuration for the
   ALIX board and appropriate nftable rules.

 - `router-rpi3` adds `hostapd` and extends `router-rpi3` with interface and
   wireless configuration for the Raspberry Pi 3 and appropriate nftable rules.
