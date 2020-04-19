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
