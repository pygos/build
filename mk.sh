#!/bin/bash

set -e

if [ ! $# -eq 1 ]; then
	echo "usage: $0 <product>"
	exit 1
fi

PRODUCT="$1"

################################ basic setup ################################
BUILDROOT=$(pwd)
SCRIPTDIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
NUMJOBS=$(grep -e "^processor" /proc/cpuinfo | wc -l)

LAYERCONF="$SCRIPTDIR/product/${PRODUCT}.layers"

if [ ! -f "$LAYERCONF" ]; then
	echo "Cannot find layer configuration for $PRODUCT"
	exit 1
fi

PKGSRCDIR="$BUILDROOT/src"
PKGDOWNLOADDIR="$BUILDROOT/download"
PKGBUILDDIR="$BUILDROOT/$PRODUCT/build"
PKGDEPLOYDIR="$BUILDROOT/$PRODUCT/deploy"
PKGLOGDIR="$BUILDROOT/$PRODUCT/log"
PACKAGELIST="$BUILDROOT/$PRODUCT/pkglist"
REPODIR="$BUILDROOT/$PRODUCT/repo"
DEPENDSLIST="$BUILDROOT/$PRODUCT/depends"
PROVIDESLIST="$BUILDROOT/$PRODUCT/provides"

mkdir -p "$PKGDOWNLOADDIR" "$PKGSRCDIR" "$PKGLOGDIR"
mkdir -p "$REPODIR"

pushd "$SCRIPTDIR" > /dev/null
OS_NAME="Pygos"
OS_RELEASE=$(git describe --always --tags --dirty)
popd > /dev/null

############################# include utilities ##############################
source "$SCRIPTDIR/util/download.sh"
source "$SCRIPTDIR/util/pkgcmd.sh"
source "$SCRIPTDIR/util/misc.sh"
source "$SCRIPTDIR/util/override.sh"
source "$SCRIPTDIR/util/autotools.sh"

############################## toolchain config ##############################
include_merge "TOOLCHAIN"

HOSTTUPLE=$($SCRIPTDIR/util/config.guess)
TCDIR="$BUILDROOT/$PRODUCT/toolchain"

export PATH="$TCDIR/bin:$PATH"

mkdir -p "$TCDIR/$TARGET" "$TCDIR/bin"

CMAKETCFILE="$TCDIR/toolchain.cmake"

############################### build packages ###############################
echo "--- resolving package dependencies ---"

g++ "$SCRIPTDIR/util/depgraph.cpp" -o "$TCDIR/bin/depgraph"

truncate -s 0 $DEPENDSLIST $PROVIDESLIST

for pkg in $SCRIPTDIR/pkg/*; do
	include_pkg $(basename $pkg)

	for DEP in $SUBPKG; do
		echo "$PKGNAME,$DEP" >> "$PROVIDESLIST"
	done
	for DEP in $DEPENDS; do
		echo "$PKGNAME,$DEP" >> "$DEPENDSLIST"
	done
done

depgraph "$PROVIDESLIST" "$DEPENDSLIST" "$RELEASEPKG" > "$PACKAGELIST"
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

		rm -rf "$TCDIR/$TARGET"
		mkdir -p "$TCDIR/$TARGET"

		if [ ! -z "$DEPENDS" ]; then
			pkg install -omD -r "$TCDIR/$TARGET" -R "$REPODIR" $DEPENDS
		fi

		run_pkg_command "build"
		run_pkg_command "deploy"
		deploy_dev_cleanup
		strip_files ${PKGDEPLOYDIR}/{bin,lib}

		for f in $SUBPKG; do
			pkg pack -r "$REPODIR" \
			    -d "$PKGDEPLOYDIR/${f}.desc" \
			    -l "$PKGDEPLOYDIR/${f}.files"
		done

		rm -rf "$PKGBUILDDIR" "$PKGDEPLOYDIR"
		touch "$PKGLOGDIR/.$pkg"
	fi
done < "$PACKAGELIST"

echo "--- done ---"

