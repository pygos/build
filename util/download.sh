fetch_package() {
	local PKGDIR="$1"
	local NAME="$2"
	echo "$NAME"

	unset -f build deploy prepare
	unset -v VERSION TARBALL URL SRCDIR SHA256SUM
	source "$SCRIPTDIR/$PKGDIR/$NAME/build"

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
		local LOGFILE="$PKGLOGDIR/${NAME}-prepare.log"

		echo "unpacking..."
		tar -C "$PKGSRCDIR" -xf "$PKGDOWNLOADDIR/$TARBALL"

		pushd "$PKGSRCDIR/$SRCDIR" > /dev/null
		echo "preparing..."
		prepare "$SCRIPTDIR/$PKGDIR/$NAME" &>> "$LOGFILE" < /dev/null
		popd > /dev/null
	fi
}
