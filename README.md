# ghostty-tmux-claude-setup

Ghostty + tmux + Claude Code 조합의 마찰을 최소화하는 macOS 전용 설정 묶음.

## 배경

세 레이어(Ghostty, tmux, Claude Code)가 각자 마우스·키보드·링크 프로토콜을
해석하기 때문에 기본 조합은 여러 문제가 발생한다. 이 레포는 한 사용자가 겪은
증상·원인·해결을 재현 가능한 스크립트 형태로 묶은 것이다.

**한계**: Claude Code / tmux / Ghostty 업데이트로 동작이 바뀔 수 있다.
최종 검증: 2026-04-18 (tmux 3.6a, Ghostty 1.3.1, Claude Code v2.1.89+).

## 핵심 결정: Claude Code 측에서 마우스 캡처 포기

2026-04-18 업데이트로 접근 방식이 **단순화**되었다. 과거에는 tmux 가
Claude Code 의 마우스 캡처를 우회하도록 복잡한 바인딩을 작성했으나, Claude Code
v2.1.89+ 에서 공식적으로 제공하는 환경변수 두 개로 훨씬 깨끗하게 해결된다
(docs: [fullscreen rendering](https://code.claude.com/docs/en/fullscreen)):

```bash
export CLAUDE_CODE_NO_FLICKER=1       # TUI 깜빡임 해결, 메모리 평평 유지
export CLAUDE_CODE_DISABLE_MOUSE=1    # 마우스 이벤트를 tmux 가 처리
```

**트레이드오프** (공식 문서 기준):
- ✅ tmux 기본 마우스 처리가 Claude Code 팬에서도 작동 (더블클릭 단어 선택, copy-on-select)
- ✅ TUI 깜빡임 제거, 긴 대화에서도 메모리 증가 없음
- ❌ Claude Code 내부에서: click-to-expand tool output, URL click 상실
- ❌ Claude Code 내부 마우스 휠 스크롤 상실 (PgUp/PgDn/Ctrl+Home/Ctrl+End 사용)

## 해결하는 문제

| 증상 | 원인 | 해결 |
|------|------|------|
| Shift+Enter 가 줄바꿈이 아닌 전송 | tmux 가 extended keys 전달 안 함 | `extended-keys on` + `extkeys` terminal-feature |
| URL 링크 클릭 무반응 | `mouse on` 상태에서 tmux 가 마우스 이벤트를 가로챔 | **Shift+Cmd+Click** (Shift 가 tmux 캡처 우회 → Ghostty 가 링크 오픈) |
| Claude Code 안에서 더블클릭/드래그 복사 실패 | Claude Code 가 마우스 이벤트 점유 → tmux 의 copy-mode 진입 방해 | **`CLAUDE_CODE_DISABLE_MOUSE=1`** 로 Claude Code 캡처 해제 |
| 더블클릭 시 팬이 맨 아래로 스크롤 | 첫 MouseDown1 이 Claude Code 로 전달되어 입력창 포커스 이동 | 위와 동일 (캡처 해제로 해결) |
| TUI 깜빡임 / 메모리 증가 | 렌더링 경로가 인라인 리드로우 | **`CLAUDE_CODE_NO_FLICKER=1`** (fullscreen rendering) |
| 더블클릭 후 선택이 즉시 사라짐 + 클립보드에도 안 들어감 | 기본값이 `copy-pipe-and-cancel` + pbcopy 미연동 | `copy-pipe-no-clear "/usr/bin/pbcopy"` |
| Esc 누르면 copy-mode 에서 안 나감 | vi-mode 기본 Esc = `clear-selection` | Esc → `cancel` 로 override |
| 알림 / 프로그레스바가 Ghostty 까지 안 옴 | tmux 가 OSC 이스케이프 차단 | `allow-passthrough on` |

## 해결하지 못한 것 (솔직하게)

- **`파일:라인` 형태 클릭 시 라인 점프 (`docs/foo.md:285`)** — **Ghostty 공식 한계**
  ([discussion #11378](https://github.com/ghostty-org/ghostty/discussions/11378)).
  Ghostty 의 path detection regex 가 `:line` suffix 를 인식하지 않음. 라인 번호
  없는 경로는 클릭 시 시스템 기본 핸들러로 정상 오픈. 업스트림에 `link-opener`
  config 옵션이 제안됐으나 아직 머지 안 됨. Claude Code 의 파일 편집 도구를
  직접 사용하거나 경로를 복사해 터미널에서 `$EDITOR -g path:line` 수동 실행.

## 전제

- macOS (pbcopy 경로 가정)
- tmux 3.4 이상
- Ghostty (TERM=xterm-ghostty)
- Claude Code v2.1.89 이상 (fullscreen 지원)
- zsh (install.sh 가 `~/.zshrc` 에 환경변수 append)

전제 불충족 시 `check-env.sh` 가 구체적 원인을 알려준다.

## 설치

```bash
git clone https://github.com/sylee999/ghostty-tmux-claude-setup
cd ghostty-tmux-claude-setup
./check-env.sh          # 사전 검증 (자동 수정 없음)
./install.sh            # append/merge 방식 설치
```

설치 후:

```bash
tmux detach && tmux attach
tmux display-message -p '#{client_termfeatures}'
# 결과에 extkeys, hyperlinks 포함 확인

# 새 shell 에서 Claude Code 재시작 (환경변수 반영)
exec zsh
claude
```

Claude Code 안에서 테스트: 더블클릭 단어 복사 / Shift+Cmd+Click URL 오픈 / Shift+Enter 줄바꿈.

## 제거

두 군데에서 블록 삭제 후 tmux 재시작 + shell 재시작.

1. `~/.tmux.conf` 에서 다음 마커 사이 블록 삭제:
   ```
   # >>> ghostty-tmux-claude-setup BEGIN
   ...
   # <<< ghostty-tmux-claude-setup END
   ```
2. `~/.zshrc` 에서 `CLAUDE_CODE_NO_FLICKER` / `CLAUDE_CODE_DISABLE_MOUSE` 블록 삭제.

## 파일

- `tmux-snippet.conf` — tmux 설정 (필수/우리 추가 구분 주석 있음)
- `keybindings.json` — Claude Code Shift+Enter 바인딩
- `check-env.sh` — 전제 검증
- `install.sh` — append 기반 설치

## 참고

- Claude Code fullscreen rendering: https://code.claude.com/docs/en/fullscreen
- Claude Code 공식 터미널 설정: https://code.claude.com/docs/en/terminal-config
- 관련 Claude Code 이슈:
  [#17168 Shift+Enter](https://github.com/anthropics/claude-code/issues/17168) ·
  [#23438 OSC 8](https://github.com/anthropics/claude-code/issues/23438) ·
  [#27047 tmux hyperlinks](https://github.com/anthropics/claude-code/issues/27047) ·
  [#37283 TUI flicker](https://github.com/anthropics/claude-code/issues/37283)
- Ghostty 이슈: [#11378 clickable file:line paths](https://github.com/ghostty-org/ghostty/discussions/11378)

## 라이선스·유지보수

MIT. 유지보수 보장 없음 (best effort). 상위 도구들이 바뀌면 동작하지 않을 수 있음.
이슈 환영하되 응답 보장 없음.
