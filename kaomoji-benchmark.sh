#!/bin/sh
# Benchmark kaomoji prompt overhead. Usage: kaomoji-benchmark.sh [repo_dir] [iterations]

set -e

STARSHIP_BIN=$(command -v starship)
LIB_DIR="${STARSHIP_KAOMOJI_HOME:-$(CDPATH= cd -- "$(dirname "$0")" && pwd)}"
GIT_KAOMOJI="$LIB_DIR/git-kaomoji.sh"
REPO_DIR="${1:-$HOME/.config}"
ITER="${2:-20}"

cd "$REPO_DIR"

echo "=== Starship prompt (line 1) x${ITER} ==="
/usr/bin/time -p sh -c "
i=0
while [ \$i -lt $ITER ]; do
  $STARSHIP_BIN prompt --terminal-width=120 --status=0 --jobs=0 >/dev/null
  i=\$((i + 1))
done
" 2>&1

echo ""
echo "=== git-kaomoji state x${ITER} ==="
/usr/bin/time -p sh -c "
i=0
while [ \$i -lt $ITER ]; do
  $GIT_KAOMOJI state >/dev/null
  i=\$((i + 1))
done
" 2>&1

echo ""
echo "=== Animation tick (zsh in-process) x${ITER} ==="
/usr/bin/time -p zsh -f -c "
source $LIB_DIR/kaomoji-faces.zsh
_STAR_GIT_STATE=clean
export STARSHIP_KAOMOJI_ANIM=1
i=0
while (( i < $ITER )); do
  STARSHIP_KAOMOJI_FRAME=\$i _star_kaomoji_pointer_for clean >/dev/null
  (( i++ ))
done
" 2>&1

echo ""
echo "=== Full precmd (starship + git state) x${ITER} ==="
/usr/bin/time -p zsh -f -c "
source $LIB_DIR/kaomoji-prompt.zsh
i=0
while (( i < $ITER )); do
  _STAR_KAOMOJI_LINE1=\"\$(command starship prompt --terminal-width=120 --status=0 --jobs=0)\"
  _STAR_GIT_STATE=\"\$($GIT_KAOMOJI state)\"
  (( i++ ))
done
" 2>&1

echo ""
echo "Idle animation cost: ~1 redraw/s at STARSHIP_KAOMOJI_INTERVAL=1.0"
echo "Run: echo \$STARSHIP_KAOMOJI_INTERVAL  (current interval)"
