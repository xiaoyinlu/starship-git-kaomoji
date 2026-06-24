# Load kaomoji.faces once into zsh (cached compile). Used by kaomoji-prompt.zsh.

_star_kaomoji_faces_file() {
	print -nr -- "${STARSHIP_KAOMOJI_FRAMES:-$STARSHIP_KAOMOJI_HOME/kaomoji.faces}"
}

_star_kaomoji_cache_file() {
	local faces=$(_star_kaomoji_faces_file)
	local id
	id=$(print -nr -- "$faces" | cksum | awk '{print $1}')
	print -nr -- "${XDG_CACHE_HOME:-$HOME/.cache}/starship-kaomoji/faces-${id}.sh"
}

_star_kaomoji_shell_escape() {
	print -nr -- "${1//\'/\'\\\'\'}"
}

_star_kaomoji_compile_faces() {
	local faces=$1 cache=$2
	local section='' line key val esc
	mkdir -p "${cache:h}" || return 1
	{
		print '# Generated from kaomoji.faces — do not edit'
		while IFS= read -r line || [[ -n $line ]]; do
			case $line in
			'' | \#*) continue ;;
			\[*\])
				section=${line#[}
				section=${section%]}
				[[ $section == [a-zA-Z0-9_]# ]] || section=''
				;;
			*=*)
				[[ -z $section ]] && continue
				key=${line%%=*}
				val=${line#*=}
				case $key in
				health | pointer | anim)
					esc=$(_star_kaomoji_shell_escape "$val")
					print -r -- "KAOMOJI_${section}_${key}='${esc}'"
					;;
				esac
				;;
			esac
		done <"$faces"
	} >"${cache}.tmp" && mv "${cache}.tmp" "$cache"
}

_star_kaomoji_ensure_faces_cache() {
	local faces=$(_star_kaomoji_faces_file) cache=$(_star_kaomoji_cache_file)
	[[ -f "$faces" ]] || {
		print -u2 "starship-git-kaomoji: kaomoji.faces not found: $faces"
		return 1
	}
	if [[ ! -f "$cache" || "$faces" -nt "$cache" ]]; then
		_star_kaomoji_compile_faces "$faces" "$cache" || return 1
	fi
	source "$cache"
}

_star_kaomoji_anim_pick() {
	local state=$1 idx=$2
	local anim_var="KAOMOJI_${state}_anim"
	local pointer_var="KAOMOJI_${state}_pointer"
	local list=${(P)anim_var}
	if [[ -z "$list" ]]; then
		print -nr -- ${(P)pointer_var}
		return
	fi
	local -a frames=("${(@s:|:)list}")
	(( ${#frames[@]} == 0 )) && return
	print -nr -- "${frames[$(( idx % ${#frames[@]} + 1 ))]}"
}

_star_kaomoji_pointer_for() {
	local state=$1
	if (( STARSHIP_KAOMOJI_ANIM )); then
		_star_kaomoji_anim_pick "$state" "$STARSHIP_KAOMOJI_FRAME"
	else
		local pointer_var="KAOMOJI_${state}_pointer"
		print -nr -- ${(P)pointer_var}
	fi
}

_star_kaomoji_ensure_faces_cache || return 1
