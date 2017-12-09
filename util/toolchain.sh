save_toolchain() {
	if [ ! -e "${TCDIR}/${TARGET}.tar.gz" ]; then
		pushd "$TCDIR/$TARGET" > /dev/null
		tar czf "${TCDIR}/${TARGET}.tar.gz" include lib
		popd > /dev/null
	fi
}

restore_toolchain() {
	pushd "$TCDIR/$TARGET" > /dev/null
	rm -r include lib
	tar zxf "${TCDIR}/${TARGET}.tar.gz"
	popd > /dev/null
}

install_build_deps() {
	local pkg="$1"

	if [ ! -e "$SCRIPTDIR/pkg/$pkg/depends" ]; then
		return
	fi

	dependencies "$SCRIPTDIR/pkg/$pkg/depends" \
			"$BUILDROOT/$CFG/deppkg" "pkg"

	while read deppkg; do
		local devdir="$PKGDEPLOYDIR/${deppkg}-dev"

		if [ -d "$devdir/include" ]; then
			cp -R "$devdir/include" "$TCDIR/$TARGET"
		fi
		if [ -d "$devdir/lib" ]; then
			cp -R "$devdir/lib" "$TCDIR/$TARGET"
		fi
	done < "$BUILDROOT/$CFG/deppkg"
}
