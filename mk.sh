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
PKGLOGDIR="$BUILDROOT/$BOARD/log"
PKGDOWNLOADDIR="$BUILDROOT/download"
PACKAGELIST="$BUILDROOT/$BOARD/pkglist"

mkdir -p "$PKGDOWNLOADDIR" "$PKGSRCDIR" "$PKGBUILDDIR" "$PKGLOGDIR"
mkdir -p "$PKGDEPLOYDIR" "$TCDIR/bin"

export PATH="$TCDIR/bin:$PATH"

source "$SCRIPTDIR/board/$BOARD/TOOLCHAIN"

mkdir -p "$TCDIR/$TARGET"

CMAKETCFILE="$TCDIR/toolchain.cmake"

############################# include utilities ##############################
source "$SCRIPTDIR/util/depends.sh"
source "$SCRIPTDIR/util/download.sh"
source "$SCRIPTDIR/util/pkgcmd.sh"
source "$SCRIPTDIR/util/toolchain.sh"
source "$SCRIPTDIR/util/cmake.sh"

############################## build toolchain ###############################
echo "--- resolving toolchain dependencies ---"

include_pkg "tcpkg" "toolchain"
dependencies | tsort | tac > "$PACKAGELIST"
cat "$PACKAGELIST"

echo "--- downloading toolchain files ---"

while read pkg; do
	include_pkg "tcpkg" "$pkg"
	fetch_package
done < "$PACKAGELIST"

echo "--- building toolchain ---"

gen_cmake_toolchain_file

while read pkg; do
	include_pkg "tcpkg" "$pkg"
	run_pkg_command "build" "toolchain"
	run_pkg_command "deploy" "toolchain"
done < "$PACKAGELIST"

echo "--- backing up toolchain sysroot ---"

save_toolchain

############################### build packages ###############################
echo "--- resolving package dependencies ---"

include_pkg "pkg" "release-${BOARD}"
dependencies | tsort | tac > "$PACKAGELIST"
cat "$PACKAGELIST"

echo "--- downloading package files ---"

while read pkg; do
	include_pkg "pkg" "$pkg"
	fetch_package
done < "$PACKAGELIST"

echo "--- building package ---"

while read pkg; do
	include_pkg "pkg" "$pkg"

	install_build_deps

	run_pkg_command "build" "$PKGNAME"
	run_pkg_command "deploy" "$PKGNAME"

	restore_toolchain
done < "$PACKAGELIST"

