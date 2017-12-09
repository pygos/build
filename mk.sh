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

SQFS="$BUILDROOT/$CFG/rootfs.img"
SQFS_DIR="$BUILDROOT/$CFG/squashfs"

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

echo "toolchain" > "$BUILDROOT/$CFG/rawpkg"
dependencies "$BUILDROOT/$CFG/rawpkg" "$PACKAGELIST" "tcpkg"
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

cat "$SCRIPTDIR/cfg/$CFG/PACKAGES" "$SCRIPTDIR/cfg/$CFG/SQUASHFS" | \
	sort -u > "$BUILDROOT/$CFG/rawpkg"

dependencies "$BUILDROOT/$CFG/rawpkg" "$PACKAGELIST" "pkg"
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

############################### squashfs image ###############################

echo "--- building squashfs ---"

cat "$SCRIPTDIR/cfg/$CFG/SQUASHFS" | sort -u > "$BUILDROOT/$CFG/rawpkg"
dependencies "$BUILDROOT/$CFG/rawpkg" "$PACKAGELIST" "pkg"
echo "toolchain" >> "$PACKAGELIST"

mkdir -p "$SQFS_DIR"

while read pkg; do
	if [ -e "$PKGDEPLOYDIR/$pkg" ]; then
		cp -ru --remove-destination ${PKGDEPLOYDIR}/${pkg}/* "$SQFS_DIR"
		echo "$pkg"
	fi
done < "$PACKAGELIST"

if [ -f "$SQFS" ]; then
	rm "$SQFS"
fi

mksquashfs "$SQFS_DIR" "$SQFS" -all-root -no-progress -no-xattrs 2>&1 > "$PKGLOGDIR/rootfs.log"

############################## release package ###############################

echo "--- building release package ---"

RELEASEDIR="$BUILDROOT/$CFG/release-$CFG"

if [ -d "$RELEASEDIR" ]; then
	rm -r "$RELEASEDIR"
fi

mkdir -p "$RELEASEDIR"

unset -f build_release
source "$SCRIPTDIR/cfg/$CFG/release"

build_release "$RELEASEDIR" "$SQFS"

if [ -e "${BUILDROOT}/${CFG}/release-${CFG}.tar.gz" ]; then
	rm "${BUILDROOT}/${CFG}/release-${CFG}.tar.gz"
fi

pushd "$BUILDROOT/$CFG" > /dev/null
tar czf "${BUILDROOT}/${CFG}/release-${CFG}.tar.gz" "release-${CFG}"
popd  > /dev/null

