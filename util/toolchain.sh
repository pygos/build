save_toolchain() {
	if [ ! -e "${TCDIR}/${TARGET}.tar.gz" ]; then
		pushd "$TCDIR/$TARGET" > /dev/null
		tar czf "${TCDIR}/${TARGET}.tar.gz" include lib
		popd > /dev/null
	fi
}

restore_toolchain() {
	pushd "$TCDIR/$TARGET" > /dev/null
	rm -rf include lib
	if [ -e "${TCDIR}/${TARGET}.tar.gz" ]; then
		tar zxf "${TCDIR}/${TARGET}.tar.gz"
	fi
	popd > /dev/null
}

install_build_deps() {
	if [ -z "$DEPENDS" ]; then
		return
	fi

	for deppkg in $DEPENDS; do
		local devdir="$PKGDEVDEPLOYDIR/$deppkg"

		if [ -d "$devdir/include" ]; then
			cp -R "$devdir/include" "$TCDIR/$TARGET"
		fi
		if [ -d "$PKGDEPLOYDIR/$deppkg/lib" ]; then
			cp -R "$PKGDEPLOYDIR/$deppkg/lib" "$TCDIR/$TARGET"
		fi
		if [ -d "$devdir/lib" ]; then
			cp -R "$devdir/lib" "$TCDIR/$TARGET"
		fi
	done
}
