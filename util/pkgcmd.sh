include_pkg() {
	PKGNAME="$1"		# globally visible package name

	unset -f build deploy prepare check_update
	unset -v VERSION TARBALL URL SRCDIR SHA256SUM DEPENDS SUBPKG
	source "$SCRIPTDIR/pkg/$PKGNAME/build"

	if [ -z "$SUBPKG" ]; then
		SUBPKG="$PKGNAME"
	fi
}

run_pkg_command() {
	local FUNCTION="$1"
	local LOGFILE="$PKGLOGDIR/${PKGNAME}-${FUNCTION}.log"
	local SRC="$PKGSRCDIR/$SRCDIR"

	echo "$PKGNAME - $FUNCTION"

	pushd "$PKGBUILDDIR" > /dev/null
	$FUNCTION "$SRC" &>> "$LOGFILE" < /dev/null
	popd > /dev/null

	gzip -f "$LOGFILE"
}
