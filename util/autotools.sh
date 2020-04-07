run_configure() {
	local srcdir="$1"
	shift

	local cflags="-O2 -Os"
	local ldflags=""

	if [ "x$TC_HARDENING" = "xyes" ]; then
		cflags="$cflags -fstack-protector-all"
		ldflags="$ldflags -z noexecstack -z relro -z now"
	fi

	ac_cv_func_malloc_0_nonnull=yes \
	ac_cv_func_realloc_0_nonnull=yes \
	hw_cv_func_vsnprintf_c99=yes \
	hw_cv_func_snprintf_c99=yes \
	CFLAGS="$cflags" LDFLAGS="$ldflags" \
	$srcdir/configure --prefix="" --build="$HOSTTUPLE" --host="$TARGET" \
		--bindir="/bin" --sbindir="/bin" --sysconfdir="/etc" \
		--libexecdir="/lib/libexec" --datarootdir="/share" \
		--datadir="/share" --sharedstatedir="/share" \
		--with-bashcompletiondir="/share/bash-completion/completions" \
		--includedir="/include" \
		--libdir="/lib" \
		--enable-shared --disable-static $@
}
