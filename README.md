# ghostty-tmux-claude-setup

Ghostty + tmux + Claude Code 조합의 마찰을 최소화하는 macOS 전용 설정 묶음.

## 배경

세 레이어(Ghostty, tmux, Claude Code)가 각자 마우스·키보드·링크 프로토콜을
해석하기 때문에 기본 조합은 여러 문제가 발생한다. 이 레포는 한 사용자가 겪은
증상·원인·해결을 재현 가능한 스크립트 형태로 묶은 것이다.

**한계**: Claude Code / tmux / Ghostty 업데이트로 동작이 바뀔 수 있다.
최종 검증: 2026-04-19 (tmux 3.6a, Ghostty 1.3.1, Claude Code 2.1.114).

## 핵심 결정: `/tui fullscreen` + tmux override

2026-04-19 재검증 결과, 과거에 잠깐 시도했던 환경변수 방식
(`CLAUDE_CODE_NO_FLICKER=1` / `CLAUDE_CODE_DISABLE_MOUSE=1`) 은 **더 이상
권장하지 않는다**. 이유:

- `CLAUDE_CODE_NO_FLICKER=1` 은 v2.1.89~2.1.109 과도기 플래그였음.
  v2.1.110 부터 공식 슬래시 커맨드
  [`/tui fullscreen`](https://code.claude.com/docs/en/fullscreen) 이 추가되어
  `~/.claude/settings.json` 에 `"tui": "fullscreen"` 으로 영속 저장되는 방식이
  공식 UX 가 되었다.
- `CLAUDE_CODE_DISABLE_MOUSE=1` 은 tmux 가 마우스를 가져가서 더블클릭 복사는
  얻지만 **Claude Code 내부 마우스 휠 스크롤이 완전히 상실**된다. 휠 스크롤
  사용자의 기본 스크롤 수단이므로 대가가 너무 크다.

본 레포는 이 문제를 **Claude Code 마우스 캡처 유지 + tmux 바인딩 override**
조합으로 해결한다. 환경변수는 건드리지 않는다.

- ✅ Claude Code 내부 마우스 휠 스크롤
- ✅ 더블클릭 단어 복사 / 트리플클릭 라인 복사 / 드래그 복사 (tmux override)
- ✅ TUI 깜빡임 제거, 긴 대화 메모리 평평 (`/tui fullscreen`)
- ✅ URL 오픈 — **Shift+Cmd+Click** (Shift 가 tmux 캡처 우회 → Ghostty 로 전달)
- ✅ Shift+Enter 줄바꿈 (extended keys)

## 해결하는 문제

| 증상 | 원인 | 해결 |
|------|------|------|
| Shift+Enter 가 줄바꿈이 아닌 전송 | tmux 가 extended keys 전달 안 함 | `extended-keys on` + `extkeys` terminal-feature |
| URL 링크 클릭 무반응 | `mouse on` 상태에서 tmux 가 마우스 이벤트를 가로챔 | **Shift+Cmd+Click** (Shift 가 tmux 캡처 우회 → Ghostty 가 링크 오픈) |
| TUI 앱(yazi · vim · htop · lazygit 등) 안에서 텍스트 드래그 선택 실패 | 내부 TUI 가 마우스 캡처 + 일부 앱은 redraw 로 선택 무효화 | **Shift+드래그** (Shift 가 tmux/TUI 캡처 우회 → Ghostty 네이티브 선택), 이후 **Cmd+C** |
| Claude Code 안에서 더블클릭/드래그 복사 실패 | Claude Code 가 마우스 캡처 중이라 tmux 기본 바인딩의 `mouse_any_flag` 분기로 copy-mode 진입 실패 | `pane_in_mode` 만 체크하도록 MouseDrag / Double / Triple 바인딩 override |
| 더블클릭 후 선택이 즉시 사라짐 + 클립보드에도 안 들어감 | 기본값이 `copy-pipe-and-cancel` + pbcopy 미연동 | `copy-pipe-no-clear "/usr/bin/pbcopy"` 로 교체 |
| Esc 누르면 copy-mode 에서 안 나감 | vi-mode 기본 Esc = `clear-selection` | Esc → `cancel` 로 override |
| 알림 / 프로그레스바가 Ghostty 까지 안 옴 | tmux 가 OSC 이스케이프 차단 | `allow-passthrough on` |
| TUI 깜빡임 / 긴 대화에서 메모리 증가 | 인라인 리드로우 렌더링 | `/tui fullscreen` (v2.1.110+) — settings.json `"tui": "fullscreen"` 으로 영속 |

## 해결하지 못한 것 (솔직하게)

- **`파일:라인` 형태 클릭 (`docs/foo.md:285`)** — 재확인 2026-04-19.
  - Ghostty URL matcher (Alacritty 파생 regex) 는 `:line` 을 **URL 본체로 포함**해
    클릭 시 전체 문자열을 `open` 에 넘긴다. macOS 는 `.md:29` 를 UTI 매칭 못해
    **조용히 실패** (다이얼로그 없음).
    라인 번호 **없는** 경로(`docs/foo.md`) 는 정상 오픈.
  - 완화된 요건 ("라인 점프는 포기, 파일만 열림") 조차 **현 시점 기본 설정 최소
    변경으로 불가**. matcher 경계를 `:` 앞에서 끊을 수단이 없음.
  - 우회 시도 실패 근거:
    - `~/bin/open` PATH shim: Ghostty 가 `/usr/bin/open` 대신 **NSWorkspace API 직접
      호출** ([PR #7843](https://github.com/ghostty-org/ghostty/pull/7843) 머지 이후)
      → PATH 무력화.
    - 사용자 정의 `link` config: 공식 reference 에 `"TODO: This can't currently be
      set!"` ([discussion #4379](https://github.com/ghostty-org/ghostty/discussions/4379)
      미머지, 2026-04).
    - `link-url-exclude` 같은 옵션 없음.
    - Claude Code OSC 8 출력: 본문 file:line 에는 아직 emit 안 함
      ([#13008](https://github.com/anthropics/claude-code/issues/13008), 2025-12 open,
      2026-04 미해결). Claude Code 훅에도 assistant 메시지 stdout 후처리 type 없음.
  - 해결 경로: Ghostty `link-opener` / user `link` config 공식 지원, **또는**
    Claude Code OSC 8 하이퍼링크 emit. 둘 중 하나가 풀려야 함.
  - 우회: `$EDITOR -g path:line` 수동 실행, Claude Code 파일 편집 도구 사용.
- **MouseDrag / DoubleClick / TripleClick override** 는 본 설정이 적용된
  tmux 안의 **모든 TUI 앱** (vim/htop 등) 에서 해당 마우스 동작을 tmux 쪽에서
  처리하게 만든다. 원치 않으면 `tmux-snippet.conf` 의 해당 세 줄만 제거.

## 전제

- macOS (pbcopy 경로 가정)
- tmux 3.4 이상
- Ghostty (TERM=xterm-ghostty)
- Claude Code **v2.1.110 이상** (`/tui fullscreen` 슬래시 커맨드 지원)

전제 불충족 시 `check-env.sh` 가 구체적 원인을 알려준다.

## 설치

```bash
git clone https://github.com/sylee999/ghostty-tmux-claude-setup
cd ghostty-tmux-claude-setup
./check-env.sh          # 사전 검증 (자동 수정 없음)
./install.sh            # append/merge 방식 설치 (tmux.conf + keybindings.json만)
```

설치 후:

```bash
tmux kill-server && tmux       # 또는: tmux detach && tmux attach
tmux display-message -p '#{client_termfeatures}'
# 결과에 extkeys, hyperlinks 포함 확인

claude
# 세션 안에서 한 번만 실행 (settings.json 에 영속 저장):
/tui fullscreen
```

Claude Code 안에서 테스트: Shift+Enter 줄바꿈 / 마우스 휠 스크롤 / 더블클릭 복사 /
Shift+Cmd+Click URL 오픈.

### 과거 env 사용자 주의

`~/.zshrc` 에 `CLAUDE_CODE_NO_FLICKER=1` 또는 `CLAUDE_CODE_DISABLE_MOUSE=1`
이 남아 있다면 **둘 다 제거** 권장. `check-env.sh` 가 감지하면 경고한다.

- `NO_FLICKER` 는 `/tui fullscreen` 과 중복 (v2.1.110+).
- `DISABLE_MOUSE` 는 본 레포의 tmux override 와 충돌하며 휠 스크롤을 상실시킨다.

## 제거

`~/.tmux.conf` 에서 아래 마커 사이 블록을 삭제하고 tmux 재시작.
(`~/.zshrc` 는 건드리지 않는다.)

```
# >>> ghostty-tmux-claude-setup BEGIN
...
# <<< ghostty-tmux-claude-setup END
```

`/tui fullscreen` 을 되돌리려면 `/tui default` 실행 (settings.json 자동 갱신).

## 파일

- `tmux-snippet.conf` — tmux 설정 (필수/우리 추가 구분 주석 있음)
- `keybindings.json` — Claude Code Shift+Enter 바인딩
- `check-env.sh` — 전제 검증 (Claude Code 버전·과거 env 잔재 체크 포함)
- `install.sh` — append 기반 설치

## 참고

- Claude Code fullscreen rendering: https://code.claude.com/docs/en/fullscreen
- Claude Code 공식 터미널 설정: https://code.claude.com/docs/en/terminal-config
- 관련 Claude Code 이슈:
  [#17168 Shift+Enter](https://github.com/anthropics/claude-code/issues/17168) ·
  [#23438 OSC 8](https://github.com/anthropics/claude-code/issues/23438) ·
  [#27047 tmux hyperlinks](https://github.com/anthropics/claude-code/issues/27047) ·
  [#37283 TUI flicker](https://github.com/anthropics/claude-code/issues/37283) ·
  [#13008 OSC 8 for file paths](https://github.com/anthropics/claude-code/issues/13008)
- Ghostty 이슈:
  [#11378 clickable file:line paths](https://github.com/ghostty-org/ghostty/discussions/11378) ·
  [#4379 user-configurable link](https://github.com/ghostty-org/ghostty/discussions/4379) ·
  [PR #7843 NSWorkspace API](https://github.com/ghostty-org/ghostty/pull/7843)

## 라이선스·유지보수

MIT. 유지보수 보장 없음 (best effort). 상위 도구들이 바뀌면 동작하지 않을 수 있음.
이슈 환영하되 응답 보장 없음.
