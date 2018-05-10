file_path_override() {
	if [ -e "$SCRIPTDIR/product/$PRODUCT/$BOARD/$1" ]; then
		echo "$SCRIPTDIR/product/$PRODUCT/$BOARD/$1"
		return
	fi
	if [ -e "$SCRIPTDIR/product/$PRODUCT/$1" ]; then
		echo "$SCRIPTDIR/product/$PRODUCT/$1"
		return
	fi
	if [ -e "$SCRIPTDIR/board/$BOARD/$1" ]; then
		echo "$SCRIPTDIR/board/$BOARD/$1"
		return
	fi
}

cat_file_override() {
	local path=$(file_path_override "$1")

	if [ ! -z "$path" ]; then
		cat "$path"
	fi
}

cat_file_merge() {
	if [ -e "$SCRIPTDIR/product/$PRODUCT/$BOARD/$1" ]; then
		cat "$SCRIPTDIR/product/$PRODUCT/$BOARD/$1"
	fi
	if [ -e "$SCRIPTDIR/product/$PRODUCT/$1" ]; then
		cat "$SCRIPTDIR/product/$PRODUCT/$1"
	fi
	if [ -e "$SCRIPTDIR/board/$BOARD/$1" ]; then
		cat "$SCRIPTDIR/board/$BOARD/$1"
	fi
}

include_override() {
	local path=$(file_path_override "$1")

	if [ ! -z "$path" ]; then
		source "$path"
	fi
}

include_merge() {
	if [ -e "$SCRIPTDIR/board/$BOARD/$1" ]; then
		source "$SCRIPTDIR/board/$BOARD/$1"
	fi
	if [ -e "$SCRIPTDIR/product/$PRODUCT/$1" ]; then
		source "$SCRIPTDIR/product/$PRODUCT/$1"
	fi
	if [ -e "$SCRIPTDIR/product/$PRODUCT/$BOARD/$1" ]; then
		source "$SCRIPTDIR/product/$PRODUCT/$BOARD/$1"
	fi
}
