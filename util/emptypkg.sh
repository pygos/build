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

download() {
	fetch_package
}

prepare() {
	apply_patches
}

build() {
	return
}

deploy() {
	return
}

check_update() {
	return
}
