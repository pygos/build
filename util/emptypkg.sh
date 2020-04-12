apply_patches() {
	local PATCH

	for PATCH in $SCRIPTDIR/pkg/$PKGNAME/*.patch; do
		if [ -f $PATCH ]; then
			patch -p1 < $PATCH
		fi
	done
}

pkg_scan_dir() {
	find -H "$1" -type d -printf "dir \"%p\" 0%m 0 0\\n" | tail -n +2
	find -H "$1" -type l -printf "slink \"%p\" 0%m 0 0 %l\\n"
	find -H "$1" -type f -printf "file \"%p\" 0%m 0 0\\n"
}

prepare() {
	apply_patches
}

build() {
	return
}

deploy() {
	return
}

check_update() {
	return
}
