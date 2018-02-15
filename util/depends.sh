include_pkg() {
	PKGNAME="$1"		# globally visible package name

	unset -f build deploy prepare
	unset -v VERSION TARBALL URL SRCDIR SHA256SUM DEPENDS
	source "$SCRIPTDIR/pkg/$PKGNAME/build"
}

dependencies() {
	local depends="$DEPENDS"

	if [ ! -z "$depends" ]; then
		for DEP in $depends; do
			echo "$PKGNAME $DEP"
		done

		for DEP in $depends; do
			include_pkg "$DEP"
			dependencies
		done
	fi
}
