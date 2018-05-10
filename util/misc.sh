file_path_override() {
	if [ -e "$SCRIPTDIR/product/$PRODUCT/$BOARD/$1" ]; then
		echo "$SCRIPTDIR/product/$PRODUCT/$BOARD/$1"
		return
	fi
	if [ -e "$SCRIPTDIR/product/$PRODUCT/$1" ]; then
		echo "$SCRIPTDIR/product/$PRODUCT/$1"
		return
	fi
	if [ -e "$SCRIPTDIR/board/$BOARD/$1" ]; then
		echo "$SCRIPTDIR/board/$BOARD/$1"
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
	if [ -e "$SCRIPTDIR/product/$PRODUCT/$BOARD/$1" ]; then
		cat "$SCRIPTDIR/product/$PRODUCT/$BOARD/$1"
	fi
	if [ -e "$SCRIPTDIR/product/$PRODUCT/$1" ]; then
		cat "$SCRIPTDIR/product/$PRODUCT/$1"
	fi
	if [ -e "$SCRIPTDIR/board/$BOARD/$1" ]; then
		cat "$SCRIPTDIR/board/$BOARD/$1"
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
