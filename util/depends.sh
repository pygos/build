include_pkg() {
	PKGDIR="$1"		# globally visible package directory
	PKGNAME="$2"		# globally visible package name

	unset -f build deploy prepare
	unset -v VERSION TARBALL URL SRCDIR SHA256SUM DEPENDS
	source "$SCRIPTDIR/$PKGDIR/$PKGNAME/build"
}

dependencies() {
	local depends="$DEPENDS"

	if [ ! -z "$depends" ]; then
		for DEP in $depends; do
			echo "$PKGNAME $DEP"
		done

		for DEP in $depends; do
			include_pkg "$PKGDIR" "$DEP"
			dependencies
		done
	fi
}
