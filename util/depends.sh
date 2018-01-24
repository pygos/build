dependencies_recursive() {
	local NAME="$1"
	local PKGDIR="$2"

	if [ -e "$SCRIPTDIR/$PKGDIR/$NAME/depends" ]; then
		while read DEP; do
			echo "$NAME $DEP"
		done < "$SCRIPTDIR/$PKGDIR/$NAME/depends"

		while read DEP; do
			dependencies_recursive "$DEP" "$PKGDIR"
		done < "$SCRIPTDIR/$PKGDIR/$NAME/depends"
	fi
}

dependencies() {
	local NAME="$1"
	local PKGDIR="$2"

	dependencies_recursive "$NAME" "$PKGDIR" | tsort | tac
}
