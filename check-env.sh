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

section "Claude Code"
if ! command -v claude >/dev/null 2>&1; then
  err "claude CLI 미발견 (PATH 에 없거나 미설치)"
else
  cc_ver=$(claude --version 2>&1 | awk '{print $1}')
  ok "claude $cc_ver"
  # v2.1.110 이상 요구 (/tui 슬래시 커맨드 지원)
  cc_major=$(echo "$cc_ver" | cut -d. -f1)
  cc_minor=$(echo "$cc_ver" | cut -d. -f2)
  cc_patch=$(echo "$cc_ver" | cut -d. -f3 | tr -d 'a-zA-Z-')
  [ -z "$cc_patch" ] && cc_patch=0
  if [ "$cc_major" -lt 2 ] || { [ "$cc_major" -eq 2 ] && [ "$cc_minor" -lt 1 ]; } || { [ "$cc_major" -eq 2 ] && [ "$cc_minor" -eq 1 ] && [ "$cc_patch" -lt 110 ]; }; then
    err "Claude Code v2.1.110 이상 필요 (/tui 슬래시 커맨드). 현재 $cc_ver"
  fi
fi

section "Codex CLI (optional)"
if ! command -v codex >/dev/null 2>&1; then
  note "codex CLI 미발견 — Codex optional keymap 설치는 건너뜀"
else
  codex_ver=$(codex --version 2>&1 | tail -n 1)
  ok "$codex_ver"
fi

section "과거 env 잔재 (비권장)"
if [ -f "$HOME/.zshrc" ] && grep -qE 'CLAUDE_CODE_DISABLE_MOUSE|CLAUDE_CODE_NO_FLICKER' "$HOME/.zshrc"; then
  note "~/.zshrc 에 CLAUDE_CODE_DISABLE_MOUSE / NO_FLICKER 발견 — 제거 권장"
  note "  DISABLE_MOUSE=1 은 휠 스크롤을 상실시킴. /tui fullscreen + tmux override 로 대체됨"
fi

section "target files"
for f in "$HOME/.tmux.conf" "$HOME/.claude/keybindings.json" "$HOME/.codex/config.toml"; do
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
