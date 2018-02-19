#!/bin/bash

set -e

if [ ! $# -eq 1 ]; then
	echo "usage: $0 <config>"
	exit 1
fi

BOARD="$1"

################################ basic setup ################################
BUILDROOT=$(pwd)
SCRIPTDIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
NUMJOBS=$(grep -e "^processor" /proc/cpuinfo | wc -l)
HOSTTUPLE=$(uname -m)-$OSTYPE

TCDIR="$BUILDROOT/$BOARD/toolchain"
PKGBUILDDIR="$BUILDROOT/$BOARD/build"
PKGSRCDIR="$BUILDROOT/src"
PKGDEPLOYDIR="$BUILDROOT/$BOARD/deploy"
PKGDEVDEPLOYDIR="$BUILDROOT/$BOARD/deploy-dev"
PKGLOGDIR="$BUILDROOT/$BOARD/log"
PKGDOWNLOADDIR="$BUILDROOT/download"
PACKAGELIST="$BUILDROOT/$BOARD/pkglist"

mkdir -p "$PKGDOWNLOADDIR" "$PKGSRCDIR" "$PKGLOGDIR"
mkdir -p "$PKGDEPLOYDIR" "$PKGDEVDEPLOYDIR" "$TCDIR/bin"

export PATH="$TCDIR/bin:$PATH"

source "$SCRIPTDIR/board/$BOARD/TOOLCHAIN"

mkdir -p "$TCDIR/$TARGET"

CMAKETCFILE="$TCDIR/toolchain.cmake"

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

