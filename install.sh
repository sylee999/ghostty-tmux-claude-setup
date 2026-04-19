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

# 3. ~/.zshrc 의 과거 env 블록 정리 (있으면)
# v2.1.89 권장이던 CLAUDE_CODE_NO_FLICKER / CLAUDE_CODE_DISABLE_MOUSE 는
# v2.1.110+ `/tui fullscreen` + tmux override 방식으로 대체됨. DISABLE_MOUSE 는
# Claude Code 내부 휠 스크롤을 상실시키므로 더 이상 권장하지 않는다.
say "~/.zshrc 과거 env 블록 점검"
ZSHRC="$HOME/.zshrc"
if [ -f "$ZSHRC" ] && grep -q "CLAUDE_CODE_DISABLE_MOUSE\|CLAUDE_CODE_NO_FLICKER" "$ZSHRC"; then
  note_lines=$(grep -nE 'CLAUDE_CODE_DISABLE_MOUSE|CLAUDE_CODE_NO_FLICKER' "$ZSHRC" || true)
  echo "  [!] ~/.zshrc 에 과거 env 가 남아 있음:"
  printf '%s\n' "$note_lines" | sed 's/^/      /'
  echo "  제거 권장: 해당 라인을 주석 처리하거나 삭제 후 'exec zsh'."
  echo "  (자동 제거하지 않음 — 다른 설정과 섞여 있을 수 있어 사용자가 직접 처리)"
else
  echo "  과거 env 없음 — OK"
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

  2. Claude Code 재시작 후 한 번만 실행해 fullscreen 렌더러 영속 저장:
       claude
       /tui fullscreen
     → ~/.claude/settings.json 에 "tui": "fullscreen" 으로 기록됨.
       (환경변수 방식 CLAUDE_CODE_NO_FLICKER 는 v2.1.110+ 에서 불필요)

  3. 검증:
       tmux display-message -p '#{client_termfeatures}'
       # 결과에 'extkeys', 'hyperlinks' 포함

  4. Claude Code 안에서 테스트:
     - Shift+Enter 로 줄바꿈
     - 마우스 휠 스크롤로 출력 탐색
     - 아무 단어에 더블클릭 → 하이라이트 + 클립보드 복사
     - 드래그로 텍스트 선택 → 손 떼면 자동 복사
     - URL 에 Shift+Cmd+Click → 브라우저 열림

제거:
  ~/.tmux.conf 에서 '>>> ghostty-tmux-claude-setup BEGIN' ~ 'END' 사이 블록 삭제.
  (이제 ~/.zshrc 는 건드리지 않는다)
EOF
