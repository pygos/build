include_pkg() {
	PKGNAME="$1"		# globally visible package name

	unset -f build deploy download prepare check_update package
	unset -v VERSION TARBALL URL SRCDIR SHA256SUM DEPENDS SUBPKG
	source "$SCRIPTDIR/util/emptypkg.sh"
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

build_package() {
	found="yes"

	for f in $SUBPKG; do
		if [ ! -f "$REPODIR/${f}.pkg" ]; then
			found="no"
			break
		fi
	done

	if [ "x$found" == "xyes" ]; then
		return
	fi

	rm -rf "$SYSROOT" "$PKGBUILDDIR" "$PKGDEPLOYDIR"
	mkdir -p "$SYSROOT" "$PKGBUILDDIR" "$PKGDEPLOYDIR"

	run_pkg_command "set_scene"
	run_pkg_command "download"
	run_pkg_command "build"
	run_pkg_command "deploy"
	run_pkg_command "package"

	rm -rf "$SYSROOT" "$PKGBUILDDIR" "$PKGDEPLOYDIR"
}
