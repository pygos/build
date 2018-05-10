#!/bin/bash

set -e

if [ ! $# -eq 2 ]; then
	echo "usage: $0 <board> <product>"
	exit 1
fi

BOARD="$1"
PRODUCT="$2"

################################ basic setup ################################
BUILDROOT=$(pwd)
SCRIPTDIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
NUMJOBS=$(grep -e "^processor" /proc/cpuinfo | wc -l)
HOSTTUPLE=$($SCRIPTDIR/util/config.guess)

if [ ! -d "$SCRIPTDIR/product/$PRODUCT" ]; then
	echo "No configuration for this product: $PRODUCT"
	exit 1
fi

if [ ! -d "$SCRIPTDIR/board/$BOARD" ]; then
	echo "No configuration for this board: $BOARD"
	exit 1
fi

if [ -e "$SCRIPTDIR/product/$PRODUCT/BOARDS" ]; then
	if ! grep -q "$BOARD" "$SCRIPTDIR/product/$PRODUCT/BOARDS"; then
		echo "Error, $PRODUCT cannot be built for $BOARD"
		exit 1
	fi
fi

TCDIR="$BUILDROOT/${BOARD}-${PRODUCT}/toolchain"
PKGBUILDDIR="$BUILDROOT/${BOARD}-${PRODUCT}/build"
PKGSRCDIR="$BUILDROOT/src"
PKGDEPLOYDIR="$BUILDROOT/${BOARD}-${PRODUCT}/deploy"
PKGDEVDEPLOYDIR="$BUILDROOT/${BOARD}-${PRODUCT}/deploy-dev"
PKGLOGDIR="$BUILDROOT/${BOARD}-${PRODUCT}/log"
PKGDOWNLOADDIR="$BUILDROOT/download"
PACKAGELIST="$BUILDROOT/${BOARD}-${PRODUCT}/pkglist"

mkdir -p "$PKGDOWNLOADDIR" "$PKGSRCDIR" "$PKGLOGDIR"
mkdir -p "$PKGDEPLOYDIR" "$PKGDEVDEPLOYDIR" "$TCDIR/bin"

export PATH="$TCDIR/bin:$PATH"

pushd "$SCRIPTDIR" > /dev/null
OS_NAME="Pygos"
OS_RELEASE=$(git describe --always --tags --dirty)
popd > /dev/null

############################# include utilities ##############################
source "$SCRIPTDIR/util/depends.sh"
source "$SCRIPTDIR/util/download.sh"
source "$SCRIPTDIR/util/pkgcmd.sh"
source "$SCRIPTDIR/util/toolchain.sh"
source "$SCRIPTDIR/util/misc.sh"

############################## toolchain config ##############################
include_merge "TOOLCHAIN"

mkdir -p "$TCDIR/$TARGET"

CMAKETCFILE="$TCDIR/toolchain.cmake"

############################### build packages ###############################
echo "--- resolving package dependencies ---"

include_pkg "release-${BOARD}"
dependencies | tsort | tac > "$PACKAGELIST"
cat "$PACKAGELIST"

echo "--- downloading package files ---"

while read pkg; do
	include_pkg "$pkg"
	fetch_package
done < "$PACKAGELIST"

echo "--- building packages ---"

while read pkg; do
	if [ ! -e "$PKGLOGDIR/.$pkg" ]; then
		include_pkg "$pkg"
		install_build_deps
		run_pkg_command "build"
		run_pkg_command "deploy"
		restore_toolchain

		rm -rf "$PKGBUILDDIR"
		touch "$PKGLOGDIR/.$pkg"
	fi
done < "$PACKAGELIST"

echo "--- done ---"

