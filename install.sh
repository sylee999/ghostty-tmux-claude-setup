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

# 3. ~/.zshrc 에 Claude Code 환경변수 append
say "~/.zshrc 환경변수 업데이트"
ZSHRC="$HOME/.zshrc"
touch "$ZSHRC"
if grep -q "$MARKER_BEGIN" "$ZSHRC"; then
  echo "  이미 설치됨 (마커 존재). 재설치하려면 해당 블록 수동 삭제 후 재실행"
else
  {
    printf "\n%s\n" "$MARKER_BEGIN"
    cat <<'ENV_EOF'
# Claude Code: fullscreen rendering + 마우스 캡처 해제 (tmux 와 협업 개선)
# docs: https://code.claude.com/docs/en/fullscreen
export CLAUDE_CODE_NO_FLICKER=1
export CLAUDE_CODE_DISABLE_MOUSE=1
ENV_EOF
    printf "%s\n" "$MARKER_END"
  } >> "$ZSHRC"
  echo "  append 완료"
fi

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

# 5. 완료 안내
say "완료"
cat <<'EOF'

다음 단계:
  1. tmux 세션 재시작 (terminal-features 는 클라이언트 접속 시점에 평가됨):
       tmux detach && tmux attach
     또는 다른 클라이언트에서:
       tmux kill-server && tmux

  2. 새 shell 시작해서 환경변수 반영 + Claude Code 재시작:
       exec zsh
       claude

  3. 검증:
       tmux display-message -p '#{client_termfeatures}'
       # 결과에 'extkeys', 'hyperlinks' 포함
       env | grep CLAUDE_CODE_
       # CLAUDE_CODE_NO_FLICKER=1, CLAUDE_CODE_DISABLE_MOUSE=1 확인

  4. Claude Code 안에서 테스트:
     - Shift+Enter 로 줄바꿈
     - 아무 단어에 더블클릭 → 하이라이트 + 클립보드 복사 (스크롤 안 함)
     - URL 에 Shift+Cmd+Click → 브라우저 열림
     - 드래그로 텍스트 선택 → 손 떼면 자동 복사

제거:
  ~/.tmux.conf 와 ~/.zshrc 에서 '>>> ghostty-tmux-claude-setup BEGIN' ~ 'END' 사이 블록 각각 삭제.
EOF
