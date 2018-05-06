get_version_field() {
	local field=$(echo "$1" | cut -d. -f$2 | sed 's/^0*//')

	if [ -z $field ]; then
		field="0"
	fi

	case "$field" in
	[a-zA-Z]) printf '%d' "'$field'" ;;
	*) echo "$field" ;;
	esac
}

verson_find_greatest() {
	local version i v V
	local found="$1"

	while read version; do
		for i in 1 2 3 4; do
			v=$(get_version_field $version $i)
			V=$(get_version_field $found $i)
			[ $v -ge $V ] || break
			if [ $v -gt $V ]; then
			    found="$version"
			    break
			fi
		done
	done

	if [ "$found" != "$1" ]; then
		echo "$found"
	fi
}
