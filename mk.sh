#!/bin/bash

set -e

if [ ! $# -eq 1 ]; then
	echo "usage: $0 <config>"
	exit 1
fi

CFG="$1"

################################ basic setup ################################
BUILDROOT=$(pwd)
SCRIPTDIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
NUMJOBS=$(grep -e "^processor" /proc/cpuinfo | wc -l)
HOSTTUPLE=$(uname -m)-$OSTYPE

TCDIR="$BUILDROOT/$CFG/toolchain"
PKGBUILDDIR="$BUILDROOT/$CFG/build"
PKGSRCDIR="$BUILDROOT/src"
PKGDEPLOYDIR="$BUILDROOT/$CFG/deploy"
PKGLOGDIR="$BUILDROOT/$CFG/log"
PKGDOWNLOADDIR="$BUILDROOT/download"
PACKAGELIST="$BUILDROOT/$CFG/pkglist"

mkdir -p "$PKGDOWNLOADDIR" "$PKGSRCDIR" "$PKGBUILDDIR" "$PKGLOGDIR"
mkdir -p "$PKGDEPLOYDIR" "$TCDIR/bin"

export PATH="$TCDIR/bin:$PATH"

source "$SCRIPTDIR/cfg/$CFG/TOOLCHAIN"

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

dependencies "toolchain" "tcpkg" > "$PACKAGELIST"
cat "$PACKAGELIST"

echo "--- downloading toolchain files ---"

while read pkg; do
	fetch_package "tcpkg" "$pkg"
done < "$PACKAGELIST"

echo "--- building toolchain ---"

gen_cmake_toolchain_file

while read pkg; do
	run_tcpkg_command "$pkg" "build"
	run_tcpkg_command "$pkg" "deploy"
done < "$PACKAGELIST"

echo "--- backing up toolchain sysroot ---"

save_toolchain

############################### build packages ###############################
echo "--- resolving package dependencies ---"

dependencies "release-${CFG}" "pkg" > "$PACKAGELIST"
cat "$PACKAGELIST"

echo "--- downloading package files ---"

while read pkg; do
	fetch_package "pkg" "$pkg"
done < "$PACKAGELIST"

echo "--- building package ---"

while read pkg; do
	install_build_deps "$pkg"

	run_pkg_command "$pkg" "build"
	run_pkg_command "$pkg" "deploy"

	restore_toolchain
done < "$PACKAGELIST"

