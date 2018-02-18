run_pkg_command() {
	local FUNCTION="$1"
	local DEPLOYDIR="$PKGDEPLOYDIR/$PKGNAME"
	local DEVDEPLOYDIR="$PKGDEVDEPLOYDIR/$PKGNAME"
	local LOGFILE="$PKGLOGDIR/${PKGNAME}-${FUNCTION}.log"
	local SRC="$PKGSRCDIR/$SRCDIR"

	echo "$PKGNAME - $FUNCTION"

	mkdir -p "$PKGBUILDDIR" "$DEPLOYDIR" "$DEVDEPLOYDIR"

	pushd "$PKGBUILDDIR" > /dev/null
	$FUNCTION "$SRC" "$DEPLOYDIR" "$DEVDEPLOYDIR" &>> "$LOGFILE" < /dev/null
	popd > /dev/null

	(rmdir "$DEPLOYDIR" || true) 2> /dev/null ;
	(rmdir "$DEVDEPLOYDIR" || true) 2> /dev/null ;
}
