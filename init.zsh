# Entry point: source after `eval "$(starship init zsh)"`.

: "${STARSHIP_KAOMOJI_HOME:=${${(%):-%x}:A:h}}"
export STARSHIP_KAOMOJI_HOME

[[ -f "$STARSHIP_KAOMOJI_HOME/kaomoji-prompt.zsh" ]] \
	|| { print -u2 "starship-git-kaomoji: missing kaomoji-prompt.zsh in $STARSHIP_KAOMOJI_HOME"; return 1 }

source "$STARSHIP_KAOMOJI_HOME/kaomoji-prompt.zsh"
