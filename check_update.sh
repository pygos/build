#!/bin/bash

set -e

SCRIPTDIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

# dummy toolchain variables
PREFERED_PROVIDER[linux]="linux-lts"
export LAYERCONF=""

# utilities
source "$SCRIPTDIR/util/version.sh"
source "$SCRIPTDIR/util/override.sh"

# check all packages
for pkg in $SCRIPTDIR/pkg/*; do
	[ -d $pkg ] || continue;

	name=$(basename $pkg)
	echo "-- checking $name"
	source "$SCRIPTDIR/util/emptypkg.sh"
	source "$pkg/build"

	version=$(check_update)
	if [ ! -z $version ]; then
		echo "$name has newer version: $version"
	fi
done
