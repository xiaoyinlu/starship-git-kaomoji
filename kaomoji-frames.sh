# Loads kaomoji.faces (POSIX sh, no Python).
# Sourced by git-kaomoji.sh (expects: mode, animate, frame).
# Override: STARSHIP_KAOMOJI_FRAMES=/path/to/kaomoji.faces

_faces_file="${STARSHIP_KAOMOJI_FRAMES:-${STARSHIP_KAOMOJI_HOME:-}/kaomoji.faces}"
_cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/starship-kaomoji"

_kaomoji_cache_path() {
	_faces_abs="$_faces_file"
	case "$_faces_abs" in
	/*) ;;
	*)
		_faces_abs=$(CDPATH= cd -- "$(dirname "$_faces_file")" 2>/dev/null && pwd)/$(basename "$_faces_file")
		;;
	esac
	_cache_id=$(printf '%s' "$_faces_abs" | cksum | awk '{print $1}')
	printf '%s/faces-%s.sh' "$_cache_root" "$_cache_id"
}

_kaomoji_shell_escape() {
	printf '%s' "$1" | sed "s/'/'\\\\''/g"
}

_kaomoji_compile_faces() {
	_section=''
	_cache_file=$(_kaomoji_cache_path)
	_tmp="${_cache_file}.$$"
	mkdir -p "$_cache_root" || return 1
	{
		printf '%s\n' '# Generated from kaomoji.faces — do not edit'
		while IFS= read -r _line || [ -n "$_line" ]; do
			case "$_line" in
			'' | \#*) continue ;;
			\[*\])
				_section=${_line#[}
				_section=${_section%]}
				case "$_section" in
				*[!a-zA-Z0-9_]* | '') _section='' ;;
				esac
				;;
			*=*)
				[ -z "$_section" ] && continue
				_key=${_line%%=*}
				_val=${_line#*=}
				case "$_key" in
				health | pointer | anim)
					_esc=$(_kaomoji_shell_escape "$_val")
					printf "KAOMOJI_%s_%s='%s'\n" "$_section" "$_key" "$_esc"
					;;
				esac
				;;
			esac
		done <"$_faces_file"
	} >"$_tmp" && mv "$_tmp" "$_cache_file"
}

_kaomoji_load_faces() {
	if [ ! -f "$_faces_file" ]; then
		printf 'kaomoji.faces not found: %s\n' "$_faces_file" >&2
		return 1
	fi
	_cache_file=$(_kaomoji_cache_path)
	if [ ! -f "$_cache_file" ] || [ "$_faces_file" -nt "$_cache_file" ]; then
		_kaomoji_compile_faces || return 1
	fi
	# shellcheck source=/dev/null
	. "$_cache_file"
}

_frames_anim_pick() {
	_state="$1"
	_idx="$2"
	eval "_list=\$KAOMOJI_${_state}_anim"
	if [ -z "$_list" ]; then
		eval "_list=\$KAOMOJI_${_state}_pointer"
		printf '%s' "$_list"
		return
	fi
	_old_ifs=$IFS
	IFS='|'
	set -f
	# shellcheck disable=SC2086
	set -- $_list
	set +f
	_count=$#
	IFS=$_old_ifs
	[ "$_count" -eq 0 ] && return
	_pick=$(( _idx % _count ))
	_i=0
	for _f in "$@"; do
		if [ "$_i" -eq "$_pick" ]; then
			printf '%s' "$_f"
			return
		fi
		_i=$(( _i + 1 ))
	done
}

_frames_lookup() {
	_state="$1"
	_field="$2"
	_index="${3:-0}"
	case "$_field" in
	anim) _frames_anim_pick "$_state" "$_index" ;;
	health | pointer)
		eval "_val=\$KAOMOJI_${_state}_${_field}"
		printf '%s' "$_val"
		;;
	esac
}

pick_anim() {
	_state="$1"
	_static="$2"
	if [ "$mode" != pointer ] || [ "$animate" != 1 ]; then
		printf '%s' "$_static"
		return
	fi
	_frames_lookup "$_state" anim "$frame"
}

health_for_state() {
	_frames_lookup "$1" health
}

pointer_for_state() {
	_static=$(_frames_lookup "$1" pointer)
	pick_anim "$1" "$_static"
}

_kaomoji_load_faces
