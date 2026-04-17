# ghostty-tmux-claude-setup

Ghostty + tmux + Claude Code 조합의 마찰을 최소화하는 macOS 전용 설정 묶음.

## 배경

세 레이어(Ghostty, tmux, Claude Code)가 각자 마우스·키보드·링크 프로토콜을
해석하기 때문에 기본 조합은 여러 문제가 발생한다. 이 레포는 한 사용자가 겪은
증상·원인·해결을 재현 가능한 스크립트 형태로 묶은 것이다.

**한계**: Claude Code / tmux / Ghostty 업데이트로 동작이 바뀔 수 있다.
최종 검증: 2026-04-17 (tmux 3.6a, Ghostty 현행, Claude Code 현행).

## 해결하는 문제

| 증상 | 원인 | 해결 |
|------|------|------|
| Shift+Enter 가 줄바꿈이 아닌 전송 | tmux 가 extended keys 전달 안 함 | `extended-keys on` + `extkeys` terminal-feature |
| Claude Code 파일 경로 Cmd+Click 안 됨 | tmux 가 OSC 8 + mouse 이벤트 처리 충돌 | Alt+Click → `mouse_line` 파싱 → VS Code `-g` 로 직접 열기 |
| 드래그 선택·복사 안 됨 (Claude Code 안에서) | Claude Code 가 마우스 이벤트를 잡아 tmux 기본 binding 의 `mouse_any_flag` 분기로 copy-mode 진입 실패 | `pane_in_mode` 만 체크하도록 MouseDrag/Double/Triple 바인딩 override |
| 더블클릭 후 선택이 즉시 사라짐 + 클립보드에도 안 들어감 | 기본값이 `copy-pipe-and-cancel` (시스템 클립보드 연동 없음) | `copy-pipe-no-clear "/usr/bin/pbcopy"` 로 교체 |
| Esc 누르면 copy-mode 에서 안 나감 | vi-mode 기본 Esc = `clear-selection` (종료 아님) | Esc → `cancel` 로 override |
| 알림 / 프로그레스바가 Ghostty 까지 안 옴 | tmux 가 OSC 이스케이프 차단 | `allow-passthrough on` |

## 해결하지 못한 것 (솔직하게)

- **OSC 8 하이퍼링크는 tmux 안에서 실제로 Cmd+Click 되지 않는다.** Ghostty의
  링크 modifier 는 하드코딩이고 tmux 와 Claude Code 의 상호작용으로 클릭이
  전달되지 않음. 위 표의 Alt+Click 해결은 OSC 8 자체를 고친 게 아니라
  `mouse_line` 텍스트에서 경로를 직접 추출해 우회한 것이다.
- **TUI 깜빡임** (Claude Code 가 프레임마다 전체 리드로우) 은 미해결.
  Claude Code `/tui fullscreen` 시도 가능하나 근본 해결은 아님.
- **Shift+Click 으로 링크 열기** (Ghostty 공식 워크어라운드) 는 `mouse on`
  상태에서 효과가 제한적.

## 전제

- macOS (pbcopy, VS Code 경로 가정)
- tmux 3.4 이상
- Ghostty (TERM=xterm-ghostty)
- VS Code + **`code` CLI가 PATH에 설치되어 있어야 함** (미설치 시 Alt+Click이 한 번에 반응하지 않음)
  - 방법 A: VS Code → Cmd+Shift+P → "Shell Command: Install code command in PATH"
  - 방법 B: `ln -sf "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" /opt/homebrew/bin/code`
- Claude Code

전제 불충족 시 `check-env.sh` 가 구체적 원인을 알려준다.

## 설치

```bash
git clone https://github.com/YOUR_HANDLE/ghostty-tmux-claude-setup
cd ghostty-tmux-claude-setup
./check-env.sh          # 사전 검증 (자동 수정 없음)
./install.sh            # append/merge 방식 설치
```

설치 후:

```bash
tmux detach && tmux attach
tmux display-message -p '#{client_termfeatures}'
# 결과에 extkeys, hyperlinks 포함 확인
```

Claude Code 재시작 → Shift+Enter / Alt+Click / 드래그 복사 테스트.

## 제거

`~/.tmux.conf` 에서 아래 마커 사이 블록을 삭제하고 tmux 재시작.

```
# >>> ghostty-tmux-claude-setup BEGIN
...
# <<< ghostty-tmux-claude-setup END
```

## 파일

- `tmux-snippet.conf` — tmux 설정 (필수/우리 추가 구분 주석 있음)
- `open-path.sh` — Alt+Click 핸들러 (`~/.config/tmux/`에 복사됨)
- `keybindings.json` — Claude Code Shift+Enter 바인딩
- `check-env.sh` — 전제 검증
- `install.sh` — append 기반 설치

## 참고

- Claude Code 공식 가이드: https://code.claude.com/docs/en/terminal-config
- 관련 Claude Code 이슈:
  [#17168 Shift+Enter](https://github.com/anthropics/claude-code/issues/17168) ·
  [#23438 OSC 8](https://github.com/anthropics/claude-code/issues/23438) ·
  [#27047 tmux hyperlinks](https://github.com/anthropics/claude-code/issues/27047) ·
  [#37283 TUI flicker](https://github.com/anthropics/claude-code/issues/37283)

## 라이선스·유지보수

MIT. 유지보수 보장 없음 (best effort). 상위 도구들이 바뀌면 동작하지 않을 수 있음.
이슈 환영하되 응답 보장 없음.
