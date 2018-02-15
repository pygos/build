apply_patches() {
	local PATCH

	for PATCH in $SCRIPTDIR/$PKGDIR/$PKGNAME/*.patch; do
		patch -p1 < $PATCH
	done
}

strip_files() {
	local f

	for f in $@; do
		if [ ! -f "$f" ]; then
			continue
		fi

		if file $f | grep -q -i elf; then
			${TARGET}-strip --discard-all "$f"
		fi
	done
}

split_dev_deploy() {
	local lib f

	if [ -d "$1/include" ]; then
		mv "$1/include" "$2"
	fi

	if [ -d "$1/lib/pkgconfig" ]; then
		mkdir -p "$2/lib"
		mv "$1/lib/pkgconfig" "$2/lib"
	fi

	for f in ${1}/lib/*.a; do
		if [ -f "$f" ]; then
			mkdir -p "$2/lib"
			mv ${1}/lib/*.a "$2/lib"
		fi

		break
	done
}
