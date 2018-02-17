run_pkg_command() {
	local FUNCTION="$1"
	local DEPLOYDIR="$PKGDEPLOYDIR/$PKGNAME"
	local DEVDEPLOYDIR="$PKGDEVDEPLOYDIR/$PKGNAME"
	local CHECKFILE="$PKGLOGDIR/.${PKGNAME}-${FUNCTION}"

	echo "$PKGNAME - $FUNCTION"

	if [ -e "$CHECKFILE" ]; then
		return
	fi

	local LOGFILE="$PKGLOGDIR/${PKGNAME}-${FUNCTION}.log"
	local SRC="$PKGSRCDIR/$SRCDIR"

	mkdir -p "$PKGBUILDDIR" "$DEPLOYDIR" "$DEVDEPLOYDIR"

	pushd "$PKGBUILDDIR" > /dev/null
	$FUNCTION "$SRC" "$DEPLOYDIR" "$DEVDEPLOYDIR" &>> "$LOGFILE" < /dev/null
	popd > /dev/null

	(rmdir "$DEPLOYDIR" || true) 2> /dev/null ;
	(rmdir "$DEVDEPLOYDIR" || true) 2> /dev/null ;

	touch "$CHECKFILE"
}
