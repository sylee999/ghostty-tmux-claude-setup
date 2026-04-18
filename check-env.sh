#!/bin/bash
# 환경 검증 스크립트 — install.sh 실행 전 전제 조건 확인.
# 실패 시 원인과 대응 방법 출력. 자동 수정은 하지 않음.

set -u

fail=0
warn=0

section() { printf "\n== %s ==\n" "$1"; }
ok()      { printf "  [OK] %s\n" "$1"; }
err()     { printf "  [ERR] %s\n" "$1"; fail=$((fail+1)); }
note()    { printf "  [!] %s\n" "$1"; warn=$((warn+1)); }

section "OS"
if [ "$(uname)" = "Darwin" ]; then
  ok "macOS detected"
else
  err "이 스크립트는 macOS 전용 (pbcopy / Ghostty 경로 가정)"
fi

section "shell"
if [ -n "${ZSH_VERSION:-}" ] || echo "${SHELL:-}" | grep -q zsh; then
  ok "zsh"
else
  note "현재 shell 이 zsh 가 아닐 수 있음. install.sh 는 ~/.zshrc 에 환경변수 append"
fi

section "tmux"
if ! command -v tmux >/dev/null 2>&1; then
  err "tmux 미설치. 'brew install tmux' 실행"
else
  ver=$(tmux -V 2>&1 | awk '{print $2}')
  ok "tmux $ver"
  # 3.4 이상 권장 (mouse_hyperlink, ghostty hyperlinks feature)
  major=$(echo "$ver" | cut -d. -f1)
  minor=$(echo "$ver" | cut -d. -f2 | tr -d 'a-z')
  if [ "$major" -lt 3 ] || { [ "$major" -eq 3 ] && [ "$minor" -lt 4 ]; }; then
    err "tmux 3.4 이상 필요 (현재 $ver). 'brew upgrade tmux'"
  fi
fi

section "Ghostty"
if ! command -v ghostty >/dev/null 2>&1; then
  note "ghostty CLI 미발견. 앱만 설치되어 있으면 이 설정도 동작"
fi
if [ "${TERM:-}" != "tmux-256color" ] && [ "${TERM:-}" != "xterm-ghostty" ]; then
  note "현재 TERM=${TERM:-unset} — Ghostty 밖에서 실행 중일 수 있음"
fi

section "clipboard (pbcopy)"
if [ ! -x /usr/bin/pbcopy ]; then
  err "/usr/bin/pbcopy 없음. macOS 기본 경로 확인"
else
  ok "/usr/bin/pbcopy"
fi

section "Claude Code env vars"
if [ "${CLAUDE_CODE_NO_FLICKER:-}" = "1" ] && [ "${CLAUDE_CODE_DISABLE_MOUSE:-}" = "1" ]; then
  ok "CLAUDE_CODE_NO_FLICKER / CLAUDE_CODE_DISABLE_MOUSE 설정됨"
else
  note "환경변수 미설정 — install.sh 가 ~/.zshrc 에 append. 설치 후 새 shell 필요"
fi

section "target files"
for f in "$HOME/.tmux.conf" "$HOME/.zshrc" "$HOME/.claude/keybindings.json"; do
  if [ -e "$f" ]; then
    note "$f 이미 존재 — install.sh 는 append/merge 방식으로 처리"
  fi
done

printf "\n"
if [ "$fail" -gt 0 ]; then
  printf "실패 %d건 — 해결 후 재실행\n" "$fail"
  exit 1
fi
if [ "$warn" -gt 0 ]; then
  printf "경고 %d건 — 확인 후 install.sh 진행 가능\n" "$warn"
fi
printf "환경 OK\n"
