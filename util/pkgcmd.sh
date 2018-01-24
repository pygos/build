run_pkg_command_common() {
	local NAME="$1"
	local FUNCTION="$2"
	local PKGDIR="$3"
	local DEPLOYDIR="$PKGDEPLOYDIR/$4"
	local OUT="$PKGBUILDDIR/$5"
	local CHECKFILE="$PKGLOGDIR/.${6}-${FUNCTION}"

	echo "$NAME - $FUNCTION"

	if [ -e "$CHECKFILE" ]; then
		return
	fi

	unset -f build deploy prepare
	unset -v VERSION TARBALL URL SRCDIR SHA256SUM DEPENDS
	source "$SCRIPTDIR/$PKGDIR/$NAME/build"

	local LOGFILE="$PKGLOGDIR/${7}-${FUNCTION}.log"
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
	run_pkg_command_common "$1" "$2" "pkg" "$1" "$1" "$1" "$1"
}

run_tcpkg_command() {
	run_pkg_command_common "$1" "$2" "tcpkg" "toolchain" "tc-$1" "tc-$1" "tc-$1"
}
