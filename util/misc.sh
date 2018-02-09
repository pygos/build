apply_patches() {
	local PATCH

	for PATCH in $SCRIPTDIR/$PKGDIR/$PKGNAME/*.patch; do
		patch -p1 < $PATCH
	done
}
