run_pkg_command_common() {
	local FUNCTION="$1"
	local DEPLOYDIR="$PKGDEPLOYDIR/$2"
	local OUT="$PKGBUILDDIR/$3"
	local CHECKFILE="$PKGLOGDIR/.${4}-${FUNCTION}"

	echo "$PKGNAME - $FUNCTION"

	if [ -e "$CHECKFILE" ]; then
		return
	fi

	local LOGFILE="$PKGLOGDIR/${5}-${FUNCTION}.log"
	local SRC="$PKGSRCDIR/$SRCDIR"

	mkdir -p "$DEPLOYDIR" "$OUT" "${DEPLOYDIR}-dev"

	pushd "$OUT" > /dev/null
	$FUNCTION "$SRC" "$OUT" "$DEPLOYDIR" "${DEPLOYDIR}-dev" &>> "$LOGFILE" < /dev/null
	popd > /dev/null

	(rmdir "$DEPLOYDIR" || true) 2> /dev/null ;
	(rmdir "$OUT" || true) 2> /dev/null ;
	(rmdir "${DEPLOYDIR}-dev" || true) 2> /dev/null ;

	touch "$CHECKFILE"
}

run_pkg_command() {
	run_pkg_command_common "$1" "$PKGNAME" "$PKGNAME" "$PKGNAME" "$PKGNAME"
}

run_tcpkg_command() {
	run_pkg_command_common "$1" "toolchain" "tc-$PKGNAME" "tc-$PKGNAME" "tc-$PKGNAME"
}
