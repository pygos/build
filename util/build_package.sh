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

	rm -rf "$TCDIR/$TARGET" "$PKGBUILDDIR" "$PKGDEPLOYDIR"
	mkdir -p "$TCDIR/$TARGET" "$PKGBUILDDIR" "$PKGDEPLOYDIR"

	if [ ! -z "$DEPENDS" ]; then
		pkg install -omD -r "$TCDIR/$TARGET" -R "$REPODIR" $DEPENDS
	fi

	run_pkg_command "build"
	run_pkg_command "deploy"
	deploy_dev_cleanup
	strip_files ${PKGDEPLOYDIR}/{bin,lib}

	for f in $SUBPKG; do
		pkg pack -r "$REPODIR" -d "$PKGDEPLOYDIR/${f}.desc" \
			 -l "$PKGDEPLOYDIR/${f}.files"
	done

	rm -rf "$TCDIR/$TARGET" "$PKGBUILDDIR" "$PKGDEPLOYDIR"
}
