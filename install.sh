#!/bin/bash
# install.sh — 안전한 append/merge 방식 설치.
# 기존 파일을 덮어쓰지 않음. 이미 스니펫이 적용되었는지 마커로 확인.

set -eu

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
MARKER_BEGIN="# >>> ghostty-tmux-claude-setup BEGIN"
MARKER_END="# <<< ghostty-tmux-claude-setup END"

say() { printf "==> %s\n" "$1"; }

# 1. check-env.sh 실행
say "환경 검증"
bash "$REPO_DIR/check-env.sh" || { echo "환경 검증 실패 — 중단"; exit 1; }

# 2. tmux.conf에 스니펫 append (마커 기반 idempotent)
say "~/.tmux.conf 업데이트"
TMUX_CONF="$HOME/.tmux.conf"
touch "$TMUX_CONF"
if grep -q "$MARKER_BEGIN" "$TMUX_CONF"; then
  echo "  이미 설치됨 (마커 존재). 재설치하려면 해당 블록 수동 삭제 후 재실행"
else
  {
    printf "\n%s\n" "$MARKER_BEGIN"
    cat "$REPO_DIR/tmux-snippet.conf"
    printf "%s\n" "$MARKER_END"
  } >> "$TMUX_CONF"
  echo "  append 완료"
fi

# 3. open-path.sh 설치
say "~/.config/tmux/open-path.sh 설치"
mkdir -p "$HOME/.config/tmux"
cp "$REPO_DIR/open-path.sh" "$HOME/.config/tmux/open-path.sh"
chmod +x "$HOME/.config/tmux/open-path.sh"
echo "  복사 완료"

# 4. Claude Code keybindings.json merge
say "~/.claude/keybindings.json 업데이트"
mkdir -p "$HOME/.claude"
KB="$HOME/.claude/keybindings.json"
if [ -e "$KB" ]; then
  if grep -q '"shift+enter"' "$KB"; then
    echo "  이미 shift+enter 바인딩 존재 — 변경 없음"
  else
    echo "  기존 파일 있음 — 수동 머지 필요. 아래를 Chat context bindings에 추가:"
    echo '    "shift+enter": "chat:newline"'
    echo "  참고: $REPO_DIR/keybindings.json"
  fi
else
  cp "$REPO_DIR/keybindings.json" "$KB"
  echo "  신규 생성 완료"
fi

# 5. tmux 설정 재로드 안내
say "완료"
cat <<'EOF'

다음 단계:
  1. tmux 세션 재시작 (terminal-features 는 클라이언트 접속 시점에 평가됨):
       tmux detach && tmux attach
     또는 다른 클라이언트에서:
       tmux kill-server && tmux

  2. 검증:
       tmux display-message -p '#{client_termfeatures}'
     결과에 'extkeys', 'hyperlinks' 포함되어야 함.

  3. Claude Code 재시작 후 테스트:
     - Shift+Enter 로 줄바꿈
     - 파일 경로에 Alt+Click → VS Code 열림
     - 드래그 / 더블클릭으로 시스템 클립보드 복사

제거:
  ~/.tmux.conf 에서 '>>> ghostty-tmux-claude-setup BEGIN' ~ 'END' 사이 블록 삭제.
EOF
