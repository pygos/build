file_path_override() {
	local fname="$1"

	if [ -e "$SCRIPTDIR/product/$PRODUCT/${fname}.${BOARD}" ]; then
		echo "$SCRIPTDIR/product/$PRODUCT/${fname}.${BOARD}"
		return
	fi
	if [ -e "$SCRIPTDIR/product/$PRODUCT/$fname" ]; then
		echo "$SCRIPTDIR/product/$PRODUCT/$fname"
		return
	fi
	if [ -e "$SCRIPTDIR/board/$BOARD/$fname" ]; then
		echo "$SCRIPTDIR/board/$BOARD/$fname"
		return
	fi
	if [ -e "$SCRIPTDIR/product/common/$fname" ]; then
		echo "$SCRIPTDIR/product/common/$fname"
		return
	fi
}

cat_file_override() {
	local path=$(file_path_override "$1")

	if [ ! -z "$path" ]; then
		cat "$path"
	fi
}

cat_file_merge() {
	local fname="$1"

	if [ -e "$SCRIPTDIR/product/$PRODUCT/${fname}.${BOARD}" ]; then
		cat "$SCRIPTDIR/product/$PRODUCT/${fname}.${BOARD}"
	fi
	if [ -e "$SCRIPTDIR/product/$PRODUCT/$fname" ]; then
		cat "$SCRIPTDIR/product/$PRODUCT/$fname"
	fi
	if [ -e "$SCRIPTDIR/board/$BOARD/$fname" ]; then
		cat "$SCRIPTDIR/board/$BOARD/$fname"
	fi
	if [ -e "$SCRIPTDIR/product/common/$fname" ]; then
		cat "$SCRIPTDIR/product/common/$fname"
	fi
}

apply_patches() {
	local PATCH

	for PATCH in $SCRIPTDIR/pkg/$PKGNAME/*.patch; do
		if [ -f $PATCH ]; then
			patch -p1 < $PATCH
		fi
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
		mkdir -p "$2/lib/pkgconfig"
		mv $1/lib/pkgconfig/* "$2/lib/pkgconfig"
		rmdir "$1/lib/pkgconfig"
	fi

	if [ -d "$1/share/pkgconfig" ]; then
		mkdir -p "$2/lib/pkgconfig"
		mv $1/share/pkgconfig/* "$2/lib/pkgconfig"
		rmdir "$1/share/pkgconfig"
	fi

	for f in ${1}/lib/*.la; do
		if [ -e "$f" ]; then
			rm "$f"
		fi
	done

	for f in ${1}/lib/*.a; do
		if [ -f "$f" ]; then
			mkdir -p "$2/lib"
			mv ${1}/lib/*.a "$2/lib"
		fi

		break
	done
}
