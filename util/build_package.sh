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

	for f in $SUBPKG; do
		rm -f "$REPODIR/${f}.pkg"
	done

	rm -rf "$SYSROOT" "$PKGBUILDDIR" "$PKGDEPLOYDIR"
	mkdir -p "$SYSROOT" "$PKGBUILDDIR" "$PKGDEPLOYDIR"

	if [ ! -z "$DEPENDS" ]; then
		pkg install -omD $DEPENDS
	fi

	run_pkg_command "download"
	run_pkg_command "build"
	run_pkg_command "deploy"
	deploy_dev_cleanup
	strip_files ${PKGDEPLOYDIR}/{bin,lib}

	for f in $SUBPKG; do
		pkg pack -d "$PKGDEPLOYDIR/${f}.desc" \
			 -l "$PKGDEPLOYDIR/${f}.files"
	done

	rm -rf "$SYSROOT" "$PKGBUILDDIR" "$PKGDEPLOYDIR"
}
