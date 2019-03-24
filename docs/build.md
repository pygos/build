# The Pygos Build System

The Pygos build system creates a number of binary packages from a set of
source packages using a cross toolchain, installs them to a compressed file
system image and neatly packages it with an install script for the target
board.

The Pygos system can be built by running the `mk.sh` shell script in the root
of the git tree, with the desired product configuration as argument.

The shell script can be run from anywhere on the file system. All
configuration files and scripts are accessed relative to the source location
of the script and all generated files are accessed relative to the current
working directory.

It is strongly encouraged to run the build system from outside the git tree to
have the generated files cleanly separated from the build system.

A second script named `check_update.sh` is provided to automatically query
all upstream package sources to check if newer versions are available.

The `mk.sh` creates a `download` and a `src` directory. In the former it stores
downloaded source tar balls, in the later it extracts the tar balls and applies
patches.

For all other files and directories, a sub directory named after the product
configuration is created, referred to as *build root*.

Inside the build root the directories `log`, `repo` and `toolchain` are
created. The compiled binary packages are stored in `repo`, the cross
toolchain is stored in `toolchain`. Outputs and diagnostic messages of the
build processes are stored in `log` and are each compressed after successfully
building a package.


If you are in a real hurry in building the system, you may wish to store the
input git tree and output build directory on an SSD and create the build root
directory ahead of time with a tmpfs mounted to it.


## Packages and Dependcies

The build system distinguishes between binary packages and source packages.

A binary package is an archive containing files and meta data, such as
dependency information. Installing a binary package means extracting its
contents (and recursively that of its dependencies) to a target location.

A source package is at its minimum a shell script that is run by the build
system to produce binary packages. A source package can produce more than one
binary package (e.g. a program, its utility libraries and development headers
for the libraries could all be packaged separately).

Running a build script may require development headers and libraries of other
packages to be installed to an intermediate staging sysroot used by the cross
toolchain. Thus, a source package can itself depend on binary packages that
have to be built first and are installed to the staging sysroot before
the build process begins. The resulting binary packages can have a completely
different set of dependencies (e.g. they don't need the library headers).

For simplicity, the cross toolchain, rootfs image and packaging are also
implemented as source packages and the build system takes care of building
everything in the right order.


## Package Build Scripts

The directory `pkg` contains a sub directory for each source package. Each
package directory is expected to contain a shell script named `build`.

The build script is expected to set the following variables:

* `VERSION` containing a package version number.
* `URL` containing a URL from which to download a source tar ball.
* `TARBALL` containing the name of the source tar ball. This is appended to
  the URL to download the package.
* `SHA256SUM` containing the SHA-256 check sum of the source tar ball.
* `SRCDIR` containing the name of the source directory unpacked from the
  tar ball.
* `DEPENDS` containing a space separated list of packages that have to be built
  first and installed to the cross toolchains sysroot.
* `SUBPKG` containing a space sperated list of binary packages produced. If
  left empty, the build system assumes one binary package with the same name
  as the source package.


The `build` script is also expected to implement the following functions:

* `prepare` is run after unpacking the source tar ball. The current working
  directory is set to the source directory. The path to the package directory
  is passed as first argument, so the function can easily access patch files
  stored in the package directory.
* `build` is run to compile the package. The current working directory is a
  temporary directory inside the build root directory. The source directory
  is passed as first argument.
* `deploy` is run after compilation to install the build output to a staging
  directory. Arguments and working directory are the same as for `build`.
  The function is expected to generate a `*.files` and a `*.desc` file for
  each sub package, so the build system can automatically package it.
* `check_update` is only used by the `check_update.sh` script. It is supposed
  to find out if the package has a newer version available, and if so, echo it
  to stdout.


### Directory Variables

A number of directories exist that can be accessed through global variables
from package build scripts.

The following shell variables are globally visible and identify special
directories that build scripts might be interested in:

* `SCRIPTDIR` points to the git tree containging the build system.
* `PKGDOWNLOADDIR` points to the directory to which source tar balls
  are downloaded.
* `PKGSRCDIR` points to the directory into which source tar balls are unpacked.
* `BUILDROOT` points to the build root directory.
* `PKGLOGDIR` points to the directory where log files are written to stored.
* `REPODIR` points to the directory where binary packages are stored.
* `TCDIR` points to the cross toolchain directory.

While building a package, additional staging directories are temporarily
created inside the build root directory:

* `PKGBUILDDIR` points to a temporary directory inside the build root that is
  used as working directory for the `build` and `deploy` functions.
* `PKGDEPLOYDIR` points to another such temporary directory that the `deploy`
  function is expected to install binaries to.


### Additional Variables

The following variables describe the target system and the build environment:

* `PRODUCT` contains the product name specified on the command line
* `LAYERCONF` contains path to the list of active configuration layers for the
  target product
* `TARGET` specifies the host triplet of the target board
* `OS_NAME` is statically set to `Pygos`
* `OS_RELEASE` holds a version string generated using `git-describe`
* `NUMJOBS` contains the number of processors available for parallel builds
* `HOSTTUPLE` contains the host triplet of the machine that the build system
  is running on for compiling toolchain packages.
* `CMAKETCFILE` contains the absolute path to a CMake toolchain file that can
  be used for compiling CMake based packages with the cross toolchain.
* `PACKAGELIST`, `DEPENDSLIST`, `PROVIDESLIST` hold data used internally for
  dependency management.

The cross toolchain directory containing the executable prefixed with `$TARGET-`
is also prepended to `PATH`.

### Utility Functions

Some utility functions are provided for common package build tasks:

* `apply_patches` can be used inside the `prepare` function to automatically
  apply patches stored in the package directory to the source tree.
* `strip_files` takes a list of files as argument and runs the cross toolchain
  strip program on those that are valid ELF binaries. If a directory is
  encountered, the function recursively processes the sub directory. Usually
  you don't need to use this. The `mk.sh` script uses this function after
  the deploy step to process the `bin` and `lib` directories.
* `unfuck_libtool` may have to be used before running `make install` on
  packages that build shared libraries with libtool. GNU libtool is an utter
  piece of garbage from hell. This function removes the global `/lib` search
  path from the `*.la` files, so libtool doesn't crap itself during its stupid
  relink phase, trying to link against libraries from the host system, after
  already successfully cross compiling the libraries.
* `verson_find_greatest` can be used in `check_update` to find the largest
  version number from a list. The list of version numbers is read from stdin.
  Version numbers can have up to four dot separated numbers or characters.
* `run_configure` can be used to run `autoconf` generated `configure` scripts
  with all the required options set for cross compilation. Extra options can
  be added to the options passed to `configure`.

## Configuration Files

The configuration for the build system is organized in layers, stored in
the `layer` directory in the git tree.

The configuration on how to build an image for a specific target is a file
in the `product` sub directory that specifies, what configuration layers
to use and how to stack them on top of each other. Layers that are further
down in the file override the ones before them.

From the layer configuartion, the build system itself merges (in layer
precedence order) and processes the following configuration files:

* `ROOTFS` contains a list of packages that should be built and installed to
  the root filesystem.
* `TOOLCHAIN` contains shell variables for the cross compiler toolchain.
  See below for more detail.
* `LDPATH` contains a list of directories where the loader should look
  for dynamic libraries.
* `INIT` contains shell variables configuring the init system. See below
  for more detail.

### Utility Functions

For working with configuration files, the following utility functions
can be used:

* `file_path_override` takes a file name and looks for the last layer that
  contains it. The absolute path of the first found file is `echo`ed.
* `cat_file_override` looks for the last layer that contains a file and
  prints it to standard output.
* `cat_file_merge` prints the content of a file to standard output, for every
  layer that contains the file, in layer precedence order.
* `include_override` includes a file using the `source` builtin from the last
  layer that contains the file.
* `include_merge` includes a file using the `source` builtin from every layer
  that contains the file, in layer precedence order.


### Toolchain Configuration

The toolchain configuration file contains a list of shell variables for
configuring the cross toolchain packages, as well as some other packages
that need to know information about the target system.

Currently, the following variables are used:

* `RELEASEPKG` contains the name of the release package to build to trigger a
  build of the entire system. Typically this package depends on the `rootfs`
  package, which in turn pulls all configured packages as dependencies. It gets
  built last and packages the root filesystem image and boot loader files in
  some device specific way, so they can be installed easily on the target
  hardware.
* `LINUXPKG` contains the name of the kernel package. There is a default
  package called 'linux' that builds a standard, main line LTS kernel. Other
  packages can be specified for building vendor kernels.
* `TARGET` specifies the target triplet for the cross toolchain, which is also
  the host triplet for packages cross compiled with autotools.
* `GCC_CPU` specifies the target processor for GCC.
* `GCC_EXTRACFG` extra configure arguments passed to GCC. For instance, this
  may contain FPU configuration for ARM targets.
* `BINUTILS_EXTRACFG` extra configure arguments passed to binutils.
* `LINUX_TGT` contains the space seperated make targets for the generic,
  main line, LTS kernel package.
* `CPU_IS_64BIT` is set to `yes` for 64 bit CPUs. This is needed for some
  packages like nginx that need a little help for cross compiling.
* `TC_HARDENING` is set to `yes` to build user space binaries position
  independent, with read only relocation, immediate binding and with GCCs
  stack protector enabled for all functions.


### Init System Configuration

The INIT configuration file contains a list of shell variables for configuring
the init system.

Currently, the following variables are used:

* `GETTY_TTY` contains a space separated list of ttys on which to start agetty
  on system boot.
* `HWCLOCK` is set to yes if the system has a hardware clock that the time
  should be synchronized with during system boot and shutdown. If set to
  anything else, the init system is configured to keep track of time using
  `ntpdate` and a file on persistent storage.
* `DHCP_PORTS` contains a space separated list of network interfaces on which
  to operate a DHCP client for network auto configuration.
* `SERVICES` contains a space separated list of raw service names to enable.
* `MODULES` contains a space seperated list of kernel modules that should be
  loaded during system boot.


For configuring network interfaces, a file `ifrename` exists that assigns
persistent, predictable names to network interfaces.

The default naming scheme of the Pygos system is to rename the Ethernet
interfaces installed on the board to *port<X>* where X is an index starting
with 0.

For each network interface, addresses, mtu, offloading, etc can be configured
in a file `interfaces/<name>`, where *name* is the interface name *after*
renaming.

If the files `nftables.rules` or `sysctl.conf` are found, they are copied to
the target system image and the coresponding services are enabled.

For more details, please refer to the not yet existing network documentation.

### Package Specific Configuration Files

Additional configuration files may be present that are used by various packages.

The following files are currently used (with default override behavior):

* `linux.config` contains the kernel build configuration. The same name is
  currently used by both the main line and the board specific vendor kernels.
* `dnsmasq.conf` is installed to `/etc` by the dnsmasq package.
* `unbound.conf` is installed to `/etc` by the unbound package.
* `dhcpcd.conf` is installed to `/etc` by the dhcpcd package.
* `nginx.conf` is installed to `/etc/nginx` by the nginx package.
