run_configure() {
	local srcdir="$1"
	shift

	local cflags="-fstack-protector-all"
	local ldflags="-z noexecstack -z relro -z now"

	ac_cv_func_malloc_0_nonnull=yes \
	ac_cv_func_realloc_0_nonnull=yes \
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
