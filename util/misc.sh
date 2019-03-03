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
		[ ! -L "$f" ] || continue;

		if [ -d "$f" ]; then
			strip_files ${f}/*
		fi

		[ -f "$f" ] || continue;

		if file -b $f | grep -q -i elf; then
			${TARGET}-strip --discard-all "$f"
		fi
	done
}

deploy_dev_cleanup() {
	local f

	if [ -d "$1/share/pkgconfig" ]; then
		mkdir -p "$1/lib/pkgconfig"
		mv $1/share/pkgconfig/* "$1/lib/pkgconfig"
		rmdir "$1/share/pkgconfig"
	fi

	for f in ${1}/lib/*.la; do
		[ ! -e "$f" ] || rm "$f"
	done
}

unfuck_libtool() {
	local libdir="$PKGDEPLOYDIR/$PKGNAME/lib"
	local f

	for f in $(find $PKGBUILDDIR -type f -name '*.la' -o -name '*.lai'); do
		sed -i "s#libdir='.*'#libdir='$libdir'#g" "$f"
	done

	sed -i -r "s/(finish_cmds)=.*$/\1=\"\"/" "$PKGBUILDDIR/libtool"
	sed -i -r "s/(hardcode_into_libs)=.*$/\1=no/" "$PKGBUILDDIR/libtool"

	sed -i "s#libdir='\$install_libdir'#libdir='$libdir'#g" "$PKGBUILDDIR/libtool"
}
