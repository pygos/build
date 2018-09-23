file_path_override() {
	local layer

	tac "$LAYERCONF" | while read layer; do
		if [ -e "$SCRIPTDIR/layer/$layer/$1" ]; then
			echo "$SCRIPTDIR/layer/$layer/$1"
			return
		fi
	done
}

cat_file_override() {
	local path=$(file_path_override "$1")

	if [ ! -z "$path" ]; then
		cat "$path"
	fi
}

cat_file_merge() {
	local layer

	while read layer; do
		if [ -e "$SCRIPTDIR/layer/$layer/$1" ]; then
			cat "$SCRIPTDIR/layer/$layer/$1"
		fi
	done < "$LAYERCONF"
}

include_override() {
	local path=$(file_path_override "$1")

	if [ ! -z "$path" ]; then
		source "$path"
	fi
}

include_merge() {
	local layer

	while read layer; do
		if [ -e "$SCRIPTDIR/layer/$layer/$1" ]; then
			source "$SCRIPTDIR/layer/$layer/$1"
		fi
	done < "$LAYERCONF"
}
