# Idle kaomoji animation (line 2 only): SIGUSR1 → zle -a reset-prompt.
# Sourced by init.zsh / kaomoji-prompt.zsh — do not load standalone.

typeset -g STARSHIP_KAOMOJI_FRAME=0
typeset -g STARSHIP_KAOMOJI_INTERVAL=${STARSHIP_KAOMOJI_INTERVAL:-1}
typeset -g STARSHIP_KAOMOJI_FRAME_FILE="${STARSHIP_KAOMOJI_FRAME_FILE:-${XDG_CACHE_HOME:-$HOME/.cache}/starship-kaomoji-frame}"
typeset -g _STAR_KAOMOJI_PID=
export STARSHIP_KAOMOJI_ANIM=1
export STARSHIP_KAOMOJI_FRAME_FILE

_star_kaomoji_write_frame() {
	print -nr -- "$STARSHIP_KAOMOJI_FRAME" >"$STARSHIP_KAOMOJI_FRAME_FILE"
	export STARSHIP_KAOMOJI_FRAME
}

_star_kaomoji_zle_refresh() {
	zle reset-prompt
}

_star_kaomoji_start_timer() {
	[[ -o interactive ]] || return
	if [[ -n "$_STAR_KAOMOJI_PID" ]] && kill -0 "$_STAR_KAOMOJI_PID" 2>/dev/null; then
		return
	fi

	local -F interval=${STARSHIP_KAOMOJI_INTERVAL:-1}
	(( interval < 0.1 )) && interval=0.1
	local parent=$$

	{
		while true; do
			sleep "$interval" || break
			kill -USR1 "$parent" 2>/dev/null || break
		done
	} &!

	_STAR_KAOMOJI_PID=$!
}

_star_kaomoji_stop_timer() {
	if [[ -n "$_STAR_KAOMOJI_PID" ]]; then
		kill -TERM "$_STAR_KAOMOJI_PID" 2>/dev/null
		_STAR_KAOMOJI_PID=
	fi
}

TRAPUSR1() {
	(( STARSHIP_KAOMOJI_FRAME++ ))
	_star_kaomoji_write_frame
	zle -a _star_kaomoji_zle_refresh 2>/dev/null
}

zle -N _star_kaomoji_zle_refresh
