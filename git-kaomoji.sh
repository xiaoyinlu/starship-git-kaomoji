#!/bin/sh
# Git state for Starship kaomoji. Faces live in kaomoji-frames.sh.
# Usage: git-kaomoji.sh [health|pointer|state]
# Optional env: STARSHIP_GIT_STATE (skip git detection when set)

mode="${1:-pointer}"
animate=${STARSHIP_KAOMOJI_ANIM:-0}
frame_file="${STARSHIP_KAOMOJI_FRAME_FILE:-$HOME/.cache/starship-kaomoji-frame}"
frame=0
if [ "$animate" = 1 ] && [ -n "${STARSHIP_KAOMOJI_FRAME+set}" ]; then
	frame="${STARSHIP_KAOMOJI_FRAME:-0}"
elif [ -f "$frame_file" ]; then
	read -r frame <"$frame_file" 2>/dev/null || frame=0
fi

_kaomoji_home="${STARSHIP_KAOMOJI_HOME:-}"
if [ -z "$_kaomoji_home" ]; then
	_kaomoji_home=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
fi
_frames="$_kaomoji_home/kaomoji-frames.sh"
if [ ! -f "$_frames" ]; then
	printf 'kaomoji-frames.sh not found: %s\n' "$_frames" >&2
	exit 1
fi
# shellcheck source=kaomoji-frames.sh
. "$_frames"

detect_git_state() {
	if ! git rev-parse --git-dir >/dev/null 2>&1; then
		printf '%s' nogit
		return
	fi

	git_dir=$(git rev-parse --git-dir 2>/dev/null)

	if [ -d "$git_dir/rebase-merge" ] || [ -d "$git_dir/rebase-apply" ]; then
		printf '%s' rebase
		return
	fi

	if [ -f "$git_dir/MERGE_HEAD" ]; then
		printf '%s' merge
		return
	fi

	if [ -f "$git_dir/CHERRY_PICK_HEAD" ]; then
		printf '%s' cherry
		return
	fi

	if [ -f "$git_dir/REVERT_HEAD" ]; then
		printf '%s' revert
		return
	fi

	if [ -f "$git_dir/BISECT_LOG" ]; then
		printf '%s' bisect
		return
	fi

	porcelain=$(git status --porcelain 2>/dev/null)
	if [ -n "$porcelain" ]; then
		if printf '%s\n' "$porcelain" | grep -qE '^UU|^AA|^DD|^.U|^U.'; then
			printf '%s' conflict
			return
		fi

		has_dirty=0
		has_staged=0
		has_untracked=0
		while IFS= read -r line; do
			[ -z "$line" ] && continue
			prefix=$(printf '%.2s' "$line")
			if [ "$prefix" = "??" ]; then
				has_untracked=1
				continue
			fi
			x=$(printf '%.1s' "$line")
			rest=${line#?}
			y=$(printf '%.1s' "$rest")
			[ "$y" != ' ' ] && [ "$y" != '?' ] && has_dirty=1
			[ "$x" != ' ' ] && has_staged=1
		done <<EOF
$porcelain
EOF

		if [ "$has_dirty" -eq 1 ]; then
			printf '%s' dirty
		elif [ "$has_staged" -eq 1 ]; then
			printf '%s' staged
		elif [ "$has_untracked" -eq 1 ]; then
			printf '%s' untracked
		else
			printf '%s' untracked
		fi
		return
	fi

	if upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null); then
		ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
		behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo 0)
		if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
			printf '%s' diverged
		elif [ "$ahead" -gt 0 ]; then
			printf '%s' ahead
		elif [ "$behind" -gt 0 ]; then
			printf '%s' behind
		else
			printf '%s' clean
		fi
		return
	fi

	printf '%s' clean
}

get_git_state() {
	if [ -n "${STARSHIP_GIT_STATE:-}" ]; then
		printf '%s' "$STARSHIP_GIT_STATE"
	else
		detect_git_state
	fi
}

case "$mode" in
state)
	detect_git_state
	;;
health)
	health_for_state "$(get_git_state)"
	;;
pointer)
	pointer_for_state "$(get_git_state)"
	;;
esac
