apply_patches() {
	local PATCH

	for PATCH in $SCRIPTDIR/pkg/$PKGNAME/*.patch; do
		if [ -f $PATCH ]; then
			patch -p1 < $PATCH
		fi
	done
}

pkg_scan_dir() {
	local sp="$PKGDEPLOYDIR/$1"

	find -H "$sp" -type d -printf "dir \"%p\" 0%m 0 0\\n" | tail -n +2 |\
		sed "s#$PKGDEPLOYDIR/##g"

	find -H "$sp" -type l -printf "slink \"%p\" 0%m 0 0 %l\\n" |\
		sed "s#$PKGDEPLOYDIR/##g"

	find -H "$sp" -type f -printf "file \"%p\" 0%m 0 0\\n" |\
		sed "s#$PKGDEPLOYDIR/##g"
}

fetch_package() {
	echo "$PKGNAME - download"

	if [ -z "$TARBALL" ]; then
		return
	fi

	if [ ! -e "$PKGDOWNLOADDIR/$TARBALL" ]; then
		curl -o "$PKGDOWNLOADDIR/$TARBALL" --silent --show-error \
		     -L "$URL/$TARBALL"
	fi

	echo "$SHA256SUM  $PKGDOWNLOADDIR/${TARBALL}" | sha256sum -c --quiet "-"

	if [ ! -e "$PKGSRCDIR/$SRCDIR" ]; then
		local LOGFILE="$PKGLOGDIR/${PKGNAME}-prepare.log"

		echo "$PKGNAME - unpack"
		tar -C "$PKGSRCDIR" -xf "$PKGDOWNLOADDIR/$TARBALL"

		pushd "$PKGSRCDIR/$SRCDIR" > /dev/null
		echo "$PKGNAME - prepare"
		prepare "$SCRIPTDIR/pkg/$PKGNAME" &>> "$LOGFILE" < /dev/null
		popd > /dev/null

		gzip -f "$LOGFILE"
	fi
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
			${TARGET}-strip --discard-all "$f" 2> /dev/null || true
		fi
	done
}

deploy_dev_cleanup() {
	local f

	if [ -d "$PKGDEPLOYDIR/share/pkgconfig" ]; then
		mkdir -p "$PKGDEPLOYDIR/lib/pkgconfig"
		mv $PKGDEPLOYDIR/share/pkgconfig/* "$PKGDEPLOYDIR/lib/pkgconfig"
		rmdir "$PKGDEPLOYDIR/share/pkgconfig"
	fi

	for f in $PKGDEPLOYDIR/lib/*.la; do
		[ ! -e "$f" ] || rm "$f"
	done
}

unfuck_libtool() {
	local libdir="$PKGDEPLOYDIR/lib"
	local f

	for f in $(find $PKGBUILDDIR -type f -name '*.la' -o -name '*.lai'); do
		sed -i "s#libdir='.*'#libdir='$libdir'#g" "$f"
	done

	sed -i -r "s/(finish_cmds)=.*$/\1=\"\"/" "$PKGBUILDDIR/libtool"
	sed -i -r "s/(hardcode_into_libs)=.*$/\1=no/" "$PKGBUILDDIR/libtool"

	sed -i "s#libdir='\$install_libdir'#libdir='$libdir'#g" "$PKGBUILDDIR/libtool"
}

download() {
	fetch_package
}

prepare() {
	apply_patches
}

set_scene() {
	if [ ! -z "$DEPENDS" ]; then
		pkg install -omD $DEPENDS
	fi
}

build() {
	return
}

deploy() {
	return
}

package() {
	deploy_dev_cleanup
	strip_files ${PKGDEPLOYDIR}/{bin,lib}

	for f in $SUBPKG; do
		rm -f "$REPODIR/${f}.pkg"

		pkg pack -d "$PKGDEPLOYDIR/${f}.desc" \
			 -l "$PKGDEPLOYDIR/${f}.files"
	done
}

check_update() {
	return
}
