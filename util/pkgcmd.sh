run_pkg_command_common() {
	local NAME="$1"
	local FUNCTION="$2"
	local PKGDIR="$3"
	local DEPLOYDIR="$4"
	local CHECKFILE="$PKGLOGDIR/.${NAME}-${FUNCTION}"

	echo "$NAME - $FUNCTION"

	if [ -e "$CHECKFILE" ]; then
		return
	fi

	unset -f build deploy prepare
	unset -v VERSION TARBALL URL SRCDIR SHA256SUM
	source "$SCRIPTDIR/$PKGDIR/$NAME/build"

	local LOGFILE="$PKGLOGDIR/${NAME}-${FUNCTION}.log"
	local OUT="$PKGBUILDDIR/$NAME"
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
	local DEPLOYDIR="$PKGDEPLOYDIR/$1"

	run_pkg_command_common "$1" "$2" "pkg" "$DEPLOYDIR"
}

run_tcpkg_command() {
	local DEPLOYDIR="$PKGDEPLOYDIR/toolchain"

	run_pkg_command_common "$1" "$2" "tcpkg" "$DEPLOYDIR"
}
