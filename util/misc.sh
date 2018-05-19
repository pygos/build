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

unfuck_libtool() {
	local libdir="$PKGDEPLOYDIR/$PKGNAME/lib"
	local f

	for f in $(find $PKGBUILDDIR -type f -name '*.la'); do
		sed -i "s#libdir='.*'#libdir='$libdir'#g" "$f";
	done

	sed -i -r "s/(finish_cmds)=.*$/\1=\"\"/" "$PKGBUILDDIR/libtool"
	sed -i -r "s/(hardcode_into_libs)=.*$/\1=no/" "$PKGBUILDDIR/libtool"
}
