run_pkg_command() {
	local FUNCTION="$1"
	local DEPLOYDIR="$PKGDEPLOYDIR/$PKGNAME"
	local CHECKFILE="$PKGLOGDIR/.${PKGNAME}-${FUNCTION}"

	echo "$PKGNAME - $FUNCTION"

	if [ -e "$CHECKFILE" ]; then
		return
	fi

	local LOGFILE="$PKGLOGDIR/${PKGNAME}-${FUNCTION}.log"
	local SRC="$PKGSRCDIR/$SRCDIR"

	mkdir -p "$DEPLOYDIR" "$PKGBUILDDIR" "${DEPLOYDIR}-dev"

	pushd "$PKGBUILDDIR" > /dev/null
	$FUNCTION "$SRC" "$DEPLOYDIR" "${DEPLOYDIR}-dev" &>> "$LOGFILE" < /dev/null
	popd > /dev/null

	(rmdir "$DEPLOYDIR" || true) 2> /dev/null ;
	(rmdir "${DEPLOYDIR}-dev" || true) 2> /dev/null ;

	touch "$CHECKFILE"
}
