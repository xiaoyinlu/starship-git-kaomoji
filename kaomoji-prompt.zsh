# Two-line Starship prompt: line 1 in precmd, line 2 in PROMPT (kaomoji from git-kaomoji.sh).

autoload -Uz add-zsh-hook

: "${STARSHIP_KAOMOJI_HOME:=${${(%):-%x}:A:h}}"
export STARSHIP_KAOMOJI_HOME

[[ -f "$STARSHIP_KAOMOJI_HOME/kaomoji-animate.zsh" ]] \
	|| { print -u2 "starship-git-kaomoji: missing kaomoji-animate.zsh"; return 1 }
source "$STARSHIP_KAOMOJI_HOME/kaomoji-animate.zsh"

[[ -f "$STARSHIP_KAOMOJI_HOME/kaomoji-faces.zsh" ]] \
	|| { print -u2 "starship-git-kaomoji: missing kaomoji-faces.zsh"; return 1 }
source "$STARSHIP_KAOMOJI_HOME/kaomoji-faces.zsh"

typeset -g _STAR_KAOMOJI_LINE1=''
typeset -g _STAR_GIT_STATE='clean'
typeset -g _STAR_CMD_RAN=1
typeset -g _STAR_LAST_PWD=$PWD
typeset -g _STAR_KAOMOJI_ASYNC="${XDG_CACHE_HOME:-$HOME/.cache}/starship-kaomoji-async"
typeset -g _STAR_PRECMD_ID=0
typeset -g _STAR_ASYNC_READY=0
typeset -g _STAR_KAOMOJI_SCRIPT="$STARSHIP_KAOMOJI_HOME/git-kaomoji.sh"
typeset -g STARSHIP_KAOMOJI_CORNER_BOT=${STARSHIP_KAOMOJI_CORNER_BOT:-╰─}

typeset -g PROMPT_INDENT=0
unsetopt PROMPT_SP 2>/dev/null
setopt NO_NOTIFY 2>/dev/null
setopt PROMPT_CR 2>/dev/null

_star_starship_cmd() {
	command starship prompt \
		--terminal-width="$COLUMNS" \
		--keymap="${KEYMAP:-}" \
		--status="${STARSHIP_CMD_STATUS:-}" \
		--pipestatus="${STARSHIP_PIPE_STATUS[*]:-}" \
		--cmd-duration="${STARSHIP_DURATION:-}" \
		--jobs="${STARSHIP_JOBS_COUNT:-0}"
}

_star_git_pointer() {
	_star_kaomoji_pointer_for "$_STAR_GIT_STATE"
}

_star_prompt_line2() {
	print -rn -- "${STARSHIP_KAOMOJI_CORNER_BOT}$(_star_git_pointer) "
}

_star_kaomoji_async_refresh() {
	local id=$1
	local gitf="$_STAR_KAOMOJI_ASYNC.git" shipf="$_STAR_KAOMOJI_ASYNC.ship" idf="$_STAR_KAOMOJI_ASYNC.id"
	{
		local s
		s=$("$_STAR_KAOMOJI_SCRIPT" state 2>/dev/null)
		[[ -z "$s" ]] && s='nogit'
		print -nr -- "$s" >"$gitf"
		print -nr -- "$id" >"$idf"
		STARSHIP_GIT_STATE="$s" _star_starship_cmd >"$shipf"
		kill -USR2 $$ 2>/dev/null
	} &!
}

_star_kaomoji_apply_async() {
	local gitf="$_STAR_KAOMOJI_ASYNC.git" shipf="$_STAR_KAOMOJI_ASYNC.ship" idf="$_STAR_KAOMOJI_ASYNC.id"
	[[ -f "$gitf" && -f "$shipf" && -f "$idf" ]] || return 0
	local async_id
	read -r async_id <"$idf"
	[[ "$async_id" == "$_STAR_PRECMD_ID" ]] || return 0
	read -r _STAR_GIT_STATE <"$gitf"
	_STAR_KAOMOJI_LINE1="${$(<"$shipf")//[$'\r']/}"
	rm -f "$gitf" "$shipf" "$idf"
	_STAR_ASYNC_READY=0
	print -rn -- $'\e[1A\r\e[2K'
	print -rn -P -- "${_STAR_KAOMOJI_LINE1}"$'\n'
	zle reset-prompt
}

TRAPUSR2() {
	_STAR_ASYNC_READY=1
	zle -a _star_kaomoji_apply_async 2>/dev/null
}

_star_kaomoji_zle_line_init() {
	(( _STAR_ASYNC_READY )) || return
	zle -a _star_kaomoji_apply_async 2>/dev/null
}

_star_kaomoji_cancel_async() {
	_STAR_ASYNC_READY=0
	rm -f "$_STAR_KAOMOJI_ASYNC.git" "$_STAR_KAOMOJI_ASYNC.ship" "$_STAR_KAOMOJI_ASYNC.id"
}

_star_kaomoji_sync_refresh() {
	_STAR_GIT_STATE="$("$_STAR_KAOMOJI_SCRIPT" state 2>/dev/null)"
	[[ -z "$_STAR_GIT_STATE" ]] && _STAR_GIT_STATE='nogit'
	export STARSHIP_GIT_STATE="$_STAR_GIT_STATE"
	_STAR_KAOMOJI_LINE1="${$(_star_starship_cmd)//[$'\r']/}"
	unset STARSHIP_GIT_STATE
}

_star_kaomoji_draw_line1() {
	if [[ -n ${PROMPT_EOL_MARK:-} ]]; then
		print
		unset PROMPT_EOL_MARK
	fi
	print -rn -P -- "${_STAR_KAOMOJI_LINE1}"$'\n'
}

_star_kaomoji_precmd() {
	(( _STAR_PRECMD_ID++ ))
	PROMPT='$(_star_prompt_line2)'
	RPROMPT=''

	if (( ! _STAR_CMD_RAN )) && [[ -n "$_STAR_KAOMOJI_LINE1" ]] && [[ "$PWD" == "$_STAR_LAST_PWD" ]]; then
		_star_kaomoji_draw_line1
		_star_kaomoji_start_timer
		return
	fi

	local -i need_refresh=$_STAR_CMD_RAN
	[[ "$PWD" != "$_STAR_LAST_PWD" ]] && need_refresh=1

	_STAR_CMD_RAN=0
	_STAR_LAST_PWD=$PWD

	if [[ -n "$_STAR_KAOMOJI_LINE1" ]] && (( need_refresh )); then
		_star_kaomoji_draw_line1
		_star_kaomoji_async_refresh "$_STAR_PRECMD_ID"
		_star_kaomoji_start_timer
		return
	fi

	_star_kaomoji_sync_refresh
	_star_kaomoji_draw_line1
	_star_kaomoji_start_timer
}

_star_kaomoji_preexec() {
	_STAR_CMD_RAN=1
	_star_kaomoji_cancel_async
	_star_kaomoji_stop_timer
}

_star_kaomoji_chpwd() {
	_STAR_CMD_RAN=1
}

_star_kaomoji_exit() {
	_star_kaomoji_stop_timer
}

setopt PROMPT_SUBST
PROMPT='$(_star_prompt_line2)'

zle -N _star_kaomoji_apply_async

add-zle-hook-widget zle-line-init _star_kaomoji_zle_line_init

add-zsh-hook precmd _star_kaomoji_precmd
add-zsh-hook preexec _star_kaomoji_preexec
add-zsh-hook chpwd _star_kaomoji_chpwd
add-zsh-hook zshexit _star_kaomoji_exit
