fetch_package() {
	echo "$PKGNAME - download"

	if [ -z "$TARBALL" ]; then
		return
	fi

	if [ ! -e "$PKGDOWNLOADDIR/$TARBALL" ]; then
		curl -o "$PKGDOWNLOADDIR/$TARBALL" --silent --show-error \
		     -L "$URL/$TARBALL"
	fi

	pushd "$PKGDOWNLOADDIR" > /dev/null
	echo "$SHA256SUM  ${TARBALL}" > "${TARBALL}.sha256"
	sha256sum -c --quiet "${TARBALL}.sha256"
	rm "${TARBALL}.sha256"
	popd > /dev/null

	if [ ! -e "$PKGSRCDIR/$SRCDIR" ]; then
		local LOGFILE="$PKGLOGDIR/${PKGNAME}-prepare.log"

		echo "$PKGNAME - unpack"
		tar -C "$PKGSRCDIR" -xf "$PKGDOWNLOADDIR/$TARBALL"

		pushd "$PKGSRCDIR/$SRCDIR" > /dev/null
		echo "$PKGNAME - prepare"
		prepare "$SCRIPTDIR/$PKGDIR/$PKGNAME" &>> "$LOGFILE" < /dev/null
		popd > /dev/null
	fi
}
