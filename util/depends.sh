dependencies_recursive() {
	local NAME="$1"
	local PKGDIR="$2"

	unset -f build deploy prepare
	unset -v VERSION TARBALL URL SRCDIR SHA256SUM DEPENDS
	source "$SCRIPTDIR/$PKGDIR/$NAME/build"

	local depends="$DEPENDS"

	if [ ! -z "$depends" ]; then
		for DEP in $depends; do
			echo "$NAME $DEP"
		done

		for DEP in $depends; do
			dependencies_recursive "$DEP" "$PKGDIR"
		done
	fi
}

dependencies() {
	local NAME="$1"
	local PKGDIR="$2"

	dependencies_recursive "$NAME" "$PKGDIR" | tsort | tac
}
