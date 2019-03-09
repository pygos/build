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
