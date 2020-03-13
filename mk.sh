#!/bin/bash

set -e

if [ ! $# -eq 1 ]; then
	echo "usage: $0 <product>"
	exit 1
fi

PRODUCT="$1"

################################ basic setup ################################
BUILDROOT="$(pwd)/$PRODUCT"
SCRIPTDIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
NUMJOBS=$(grep -e "^processor" /proc/cpuinfo | wc -l)

LAYERCONF="$SCRIPTDIR/product/${PRODUCT}.layers"

if [ ! -f "$LAYERCONF" ]; then
	echo "Cannot find layer configuration for $PRODUCT"
	exit 1
fi

PKGSRCDIR="$(pwd)/src"
PKGDOWNLOADDIR="$(pwd)/download"
PKGBUILDDIR="$BUILDROOT/build"
PKGDEPLOYDIR="$BUILDROOT/deploy"
PKGLOGDIR="$BUILDROOT/log"
PACKAGELIST="$BUILDROOT/pkglist"
REPODIR="$BUILDROOT/repo"
DEPENDSLIST="$BUILDROOT/depends"
PROVIDESLIST="$BUILDROOT/provides"
PREFERESLIST="$BUILDROOT/preferes"
SYSROOT="$BUILDROOT/sysroot"

declare -A PREFERED_PROVIDER

mkdir -p "$PKGDOWNLOADDIR" "$PKGSRCDIR" "$PKGLOGDIR" "$REPODIR" "$SYSROOT"

pushd "$SCRIPTDIR" > /dev/null
OS_NAME="Pygos"
OS_RELEASE=$(git describe --always --tags --dirty)
export SOURCE_DATE_EPOCH=$(git show -s --format=%ct)
popd > /dev/null

export BUILD_PATH_PREFIX_MAP="$PKGSRCDIR=src:$BUILDROOT=build"

############################# include utilities ##############################
source "$SCRIPTDIR/util/download.sh"
source "$SCRIPTDIR/util/pkgcmd.sh"
source "$SCRIPTDIR/util/misc.sh"
source "$SCRIPTDIR/util/override.sh"
source "$SCRIPTDIR/util/autotools.sh"
source "$SCRIPTDIR/util/build_package.sh"

############################## toolchain config ##############################
include_merge "TOOLCHAIN"

HOSTTUPLE=$($SCRIPTDIR/util/config.guess)
TCDIR="$BUILDROOT/toolchain"

export PATH="$TCDIR/bin:$PATH"

mkdir -p "$TCDIR/$TARGET" "$TCDIR/bin"

CMAKETCFILE="$TCDIR/toolchain.cmake"

############################### build packages ###############################
echo "--- boot strap phase ---"

for pkg in tc-pkgtool tc-squashfs; do
	include_pkg "$pkg"
	build_package
done

echo "--- resolving package dependencies ---"

truncate -s 0 "$DEPENDSLIST" "$PROVIDESLIST" "$PREFERESLIST"

for pkg in $SCRIPTDIR/pkg/*; do
	include_pkg $(basename $pkg)

	for DEP in $SUBPKG; do
		echo "$PKGNAME,$DEP" >> "$PROVIDESLIST"
	done
	for DEP in $DEPENDS; do
		echo "$PKGNAME,$DEP" >> "$DEPENDSLIST"
	done
done

for pkg in "${!PREFERED_PROVIDER[@]}"; do
	echo "$pkg,${PREFERED_PROVIDER[$pkg]}" >> "$PREFERESLIST"
done

pkg buildstrategy -p "$PROVIDESLIST" -d "$DEPENDSLIST" -P "$PREFERESLIST" \
    "release" > "$PACKAGELIST"
cat "$PACKAGELIST"

echo "--- building packages ---"

export PKG_CONFIG_SYSROOT_DIR="$SYSROOT"
export PKG_CONFIG_LIBDIR="$SYSROOT/lib/pkgconfig"
export PKG_CONFIG_PATH="$SYSROOT/lib/pkgconfig"

while read pkg; do
	include_pkg "$pkg"
	build_package
done < "$PACKAGELIST"

echo "--- done ---"
