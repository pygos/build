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
	local RAW="$1"
	local PKGLIST="$2"
	local PKGDIR="$3"
	local TEMP=$(mktemp)

	truncate -s 0 "$PKGLIST"

	# handle toplevel packages _with_ depenendencies
	while read pkgname; do
		dependencies_recursive "$pkgname" "$PKGDIR" >> "$TEMP"
	done < "$RAW"

	# handle toplevel packages without dependencies
	while read pkgname; do
		if [ ! -e "$SCRIPTDIR/$PKGDIR/$pkgname/depends" ]; then
			grep -q "$pkgname" "$TEMP" &> /dev/null || \
				echo "$pkgname" >> "$PKGLIST"
		fi
	done < "$RAW"

	# generate topologically sorted list of packages
	sort -u "$TEMP" | tsort | tac >> "$PKGLIST"
	rm "$TEMP"
}
