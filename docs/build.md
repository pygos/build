# The Pygos Build System

The Pygos system can be built by running the `mk.sh` shell script with
the following two arguments:

* the target board to build the system for
* the product to build


The shell script can be run from anywhere on the file system. All
configuration files and scripts are accessed relative to the source location
of the script and all generated files are accessed relative to the current
working directory.

Actually it is even strongly encouraged to run the build system from outside
the git tree to have the generated files cleanly separated from the build
system.


A second script named `check_update.sh` is provided to automatically query
all upstream package sources to check if newer versions are available.


The `mk.sh` creates a `download` and a `src` directory. In the former it stores
downloaded package tar balls, in the later it extracts the tar balls.

For target specific files, a `<BOARD>-<PRODUCT>` directory is created.
Throughout the build system, this directory is refereed to as *build root*.

Inside the build root a `deploy` directory is created. Build output for each
package is deployed to a sub directory named after the package.

The cross toolchain is stored in `<BOARD>-<PRODUCT>/toolchain`.

Outputs and diagnostic messages of the build processes are stored in
`<BOARD>-<PRODUCT>/toolchain/log/<package>-<stage>.log`.


## Package Build Scripts

The directory `pkg` contains a sub directory for each package. Each package
directory is expected to contain a shell script named `build`.

The build script is expected to set the following variables:

* `VERSION` containing a package version number.
* `URL` containig a URL from which to download a source tar ball.
* `TARBALL` containing the name of the source tar ball. This is appended to
  the URL to download the package.
* `SHA256SUM` containing the SHA-256 check sum of the source tar ball.
* `SRCDIR` containing the name of the source directory unpacked from the
  tar ball.
* `DEPENDS` containing a space separated list of packages that the package
  in question depends on. Those packages are built first. Their headers and
  libraries are copied into the cross toolchain before building the current
  package and removed after building it.


Using the specified variables, the build system automatically downloads,
verifies and unpacks the source tar balls (unless that has already been done)
and determines the order in which to build the packages.


The `build` script is also expected to implement the following functions:

* `prepare` is run after unpacking the source tar ball. The current working
  directory is set to the source directory. The path to the package directory
  is passed as first argument, so the function can easily access patch files
  stored in the package directory. All output and error messages from the
  script are stored in `<packagename>-prepare.log`.
* `build` is run to compile the package. The current working directory is a
  temporary directory inside the build root directory. The source directory
  is passed as first argument. The second argument is a path to the *deploy*
  directory where generated files are installed. All standard output and error
  messages from the script are piped to `<packagename>-build.log`.
* `deploy` is run after compilation to install the build output to the deploy
  directory. Arguments and working directory are the same as for `build`. All
  output and error messages from the script are piped to
  `<packagename>-deploy.log`. Once the function returns, the `mk.sh` script
  strips everything installed to `bin` and `lib`, so the implementation doesn't
  have to do that. In fact `install-strip` Makefile targets should not be used
  since many implementations are broken for cross compilation.
* `check_update` is only used by the `check_update.sh` script. It is supposed
  to find out if the package has a newer version available, and if so, echo it
  to stdout.


### Environment Variables

The `mk.sh` sets a number of shell variables that package scripts can use.

The following variables describe the target system and the build environment:

* `BOARD` contains the target board specified on the command line
* `PRODUCT` contains the product name specified on the command line
* `TARGET` specifies the host triplet of the target board
* `OS_NAME` is statically set to `Pygos`
* `OS_RELEASE` holds a version string generated using `git-describe`
* `NUMJOBS` contains the number of processors available for parallel builds
* `HOSTTUPLE` contains the host triplet of the machine that the build system
  is running on for compiling toolchain packages.
* `CMAKETCFILE` contains the absolute path to a CMake toolchain file that can
  be used for compiling CMake based packages with the cross toolchain.


And a number of variables containing special directories:

* `BUILDROOT` contains the absolute path to the build root directory, i.e. the
  working directory in which the `mk.sh` script was executed.
* `SCRIPTDIR` contains the absolute path to the script directory, i.e. the git
  tree with the build system in it.
* `TCDIR` contains the absolute path to the cross toolchain directory.
* `PKGBUILDDIR` contains the absolute path of the temporary directory in which
  the package is being built.
* `PKGSRCDIR` contains the root directory of all unpacked package tar balls
* `PKGDEPLOYDIR` contains the root directory of all package deploy directories
* `PKGLOGDIR` holds the absolute path of the directory containing all log files
* `PKGDOWNLOADDIR` holds the absolute path of the directory containing all
  package tar balls

The toolchain bin directory containing the executable prefixed with `$TARGET-`
is also prepended to `PATH`.

### Utility Functions

Some utility functions are provided for common package build tasks:

* `apply_patches` can be used inside the `prepare` function to automatically
  apply patches stored in the package directory to the source tree.
* `strip_files` takes a list of files as argument and runs the cross toolchain
  strip program on those that are valid ELF binaries. If a directory is
  encountered, the function recursively processes the sub directory. Usually
  you don't need to use this. The `mk.sh` script uses this function to after
  the deploy step to process the `bin` and `lib` directories.
* `verson_find_greatest` can be used in `check_update` to find the largest
  version number from a list. The list of version numbers is read from stdin.
  Version numbers can have up to four dot separated numbers or characters.

## Configuration Files

Generally, when the build system tries to access configuration files, it
checks the following three locations in order:

* `product/<product>/<board>`
* `product/<product>/`
* `board/<board>/`

In most cases, if one location contains a file, searching stops. This means,
that a product configuration can *override* settings from the basic board
configuration and the product itself can contain *board specific* settings
that can override the *generic* product configuration.

In some cases, it makes more sense to merge the files from all three locations
to achieve the desired behavior. For files that contains shell variables,
merging is done in reverse order, this results in the same override behavior,
but on shell variable level.


The build system currently uses the following configuration files:

* `ROOTFS` contains a list of packages that should be built and installed to
  the root filesystem. This file is merged from all three config locations.
* `TOOLCHAIN` contains shell variables for the cross compiler toolchain.
  Merged from all three config locations. See below for more detail.
* `LDPATH` contains a list of directories where the loader should look
  for dynamic libraries. Merged from all three config locations.
* `INIT` contains shell variables configuring the init system. Merged from
  all three config locations. See below for more detail.
* `BOARDS` contains a list of supported boards. It is directly read from
  the product directory to check if a product can be built for the specified
  board.

### Utility Functions

For working with configuration files, the following utility functions
can be used:

* `file_path_override` takes a file name and looks for it in the standard
  config locations. The absolute path of the first found file is returned.
* `cat_file_override` takes a file name and looks for it in the standard
  config locations. The first file found is printed to stdout.
* `cat_file_merge` takes a file name and looks for it in the standard
  config locations. Every found file is printed to stdout.
* `include_override` takes a file name and looks for it in the standard
  config locations. The first file found is included using the `source`
  shell builtin.
* `include_merge` takes a file name and looks for it in the standard
  config locations. Every found file is included using the `source`
  shell builtin. Locations are processed in reverse to get default override
  behavior on shell variable and function level.


### Toolchain Configuration

The toolchain configuration file contains a list of shell variables for
configuring the cross toolchain packages, as well as some other packages
that need to know information about the target system.

Currently, the following variables are used:

* `TARGET` specifies the target triplet for the cross toolchain, which is also
  the host triplet for packages cross compiled with autotools.
* `GCC_CPU` specifies the target processor for GCC.
* `GCC_EXTRACFG` extra configure arguments passed to GCC. For instance, this
  may contain FPU configuration for ARM targets.
* `MUSL_CPU` contains the target CPU architecture for the Musl C library.
* `LINUXPKG` contains the name of the kernel package. There is a default
  package called 'linux' that builds a standard, main line kernel. Other
  packages can be specified for building vendor kernels.
* `LINUX_CPU` contains the value of the `ARCH` variable passed to the kernel
  build system. Used by the generic main line kernel package.
* `LINUX_TGT` contains the make target for the generic main line kernel
  package.
* `OPENSSL_TARGET` contains the target architecture for the OpenSSL package.


### Init System Configuration

The INIT configuration file contains a list of shell variables for configuring
the init system.

Currently, the following variables are used:

* `GETTY_TTY` contains a space separated list of ttys on which to start agetty
  on system boot.
* `HWCLOCK` is set to yes if the system has a hardware clock that the time
  should be synchronized with during system boot and shutdown.
* `DHCP_PORTS` contains a space separated list of network interfaces on which
  to operate a DHCP client for network auto configuration.
* `SERVICES` contains a space separated list of raw service names to enable.


For configuring network interfaces, a file `ifrename` exists that assigns
persistent, predictable names to network interfaces.

The default naming scheme of the Pygos system is to rename the Ethernet
interfaces installed on the board to *port<X>* where X is an index starting
with 0.

For each network interface, addresses, mtu, offloading, etc can be configured
in a file `interfaces/<name>`, where *name* is the interface name *after*
renaming.

For more details, please refer to the not yet existing network documentation.

### Package Specific Configuration Files

Additional configuration files may be present that are used by various packages.

The following files are currently used (with default override behavior):

* `linux.config` contains the kernel build configuration. The same name is
  currently used by both the main line and the board specific vendor kernels.
* `dnsmasq.conf` is installed to `/etc` by the dnsmasq package.
* `unbound.conf` is installed to `/etc` by the unbound package.
* `dhcpcd.conf` is installed to `/etc` by the dhcpcd package.
