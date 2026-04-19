# 검증 가이드 (2번째 기기용)

이 문서는 **다른 기기에서 이 레포가 실제로 동작하는지** 검증하기 위한 체크리스트다.
세션·메모리에 의존하지 않도록 이 파일만 보고 진행 가능해야 함.

## 전제 기기

- macOS
- tmux ≥ 3.4 (`brew install tmux` / `brew upgrade tmux`)
- Ghostty 설치 + 기본 실행 환경
- Claude Code **v2.1.110 이상** (`/tui fullscreen` 슬래시 커맨드 지원)

## 1. 설치

```bash
cd ~/Works/Projects  # 또는 원하는 위치
git clone https://github.com/sylee999/ghostty-tmux-claude-setup
cd ghostty-tmux-claude-setup
./check-env.sh          # 전제 검증 — 실패 0건 필요, 경고는 허용
./install.sh            # append/merge 설치 (tmux.conf + keybindings.json)
```

설치 후 tmux 재시작 + Claude Code 에서 fullscreen 영속 저장:

```bash
tmux kill-server && tmux   # 또는: tmux detach && tmux attach

claude                     # 새 Claude Code 세션
/tui fullscreen            # ~/.claude/settings.json 에 "tui": "fullscreen" 기록
```

## 2. 검증 체크리스트

각 항목 순서대로 수행. 하나라도 실패 시 아래 "실패 리포트" 섹션 참조.

### 2.1 tmux terminal-features 반영

```bash
tmux display-message -p '#{client_termfeatures}'
```

**기대**: 결과에 `extkeys`, `hyperlinks` **둘 다 포함**.

---

### 2.2 Fullscreen 렌더러 영속 확인

```bash
python3 -c "import json; print(json.load(open('$HOME/.claude/settings.json')).get('tui'))"
```

**기대**: 출력이 `fullscreen`. 다른 값이면 Claude Code 안에서 `/tui fullscreen` 재실행.

---

### 2.3 Shift+Enter 줄바꿈

tmux 안의 Claude Code 에서 아무 문자 입력 후 **Shift+Enter**.

**기대**: 프롬프트가 전송되지 않고 새 줄로 넘어감 (멀티라인 입력 상태).

---

### 2.4 마우스 휠 스크롤

Claude Code 안에서 긴 출력을 생성한 뒤 **마우스 휠** 로 위/아래 스크롤.

**기대**: 출력 영역이 스크롤됨. 프롬프트 라인은 하단 고정(fullscreen 특성).

이 항목 실패 = `~/.zshrc` 에 `CLAUDE_CODE_DISABLE_MOUSE=1` 가 남아 있을 가능성.
제거 후 `exec zsh` → Claude Code 재시작.

---

### 2.5 더블클릭 단어 복사

Claude Code 출력의 단어 위에서 **더블클릭**.

**기대**:
- 주황색 하이라이트로 단어 선택
- 시스템 클립보드에 복사 (다른 앱에서 Cmd+V 로 확인)
- 선택 유지 상태로 남음

---

### 2.6 드래그 선택 + 복사

Claude Code 출력 영역에서 마우스로 텍스트 드래그 선택 후 손 떼기.

**기대**:
- 주황색 하이라이트
- 손 떼는 순간 시스템 클립보드로 복사
- 선택 유지

---

### 2.7 Esc 로 copy-mode 종료

위 선택 유지 상태에서 **Esc**.

**기대**: 선택 사라지고 즉시 Claude Code 프롬프트 영역으로 커서 복귀 (재클릭 불필요).

---

### 2.8 Shift+Cmd+Click 으로 URL 오픈

Claude Code 에서 아무 HTTP URL 생성 (예: `echo "https://example.com"`). URL 에 **Shift+Cmd+Click**.

**기대**: 시스템 기본 브라우저가 URL 을 엶 (Shift 가 tmux 마우스 캡처 우회 → Ghostty 가 링크 해석).

---

### 2.9 (알려진 한계) `파일:라인` 링크 클릭

Claude Code 출력에 `docs/foo.md:285` 같은 형태가 있을 때 Shift+Cmd+Click.

**기대**: **라인 점프 안 됨** (Ghostty 공식 한계,
[discussion #11378](https://github.com/ghostty-org/ghostty/discussions/11378)).
라인 번호 없는 경로(`docs/foo.md`) 는 시스템 기본 앱으로 오픈됨.

검증 의미: 이 항목이 "실패" 하는 것이 정상. 만약 라인 점프까지 된다면 Ghostty 가 업데이트된 것.

---

## 3. 실패 리포트

한 항목이라도 실패하면:

1. 실패 항목 번호 + 증상 + `check-env.sh` 출력 전체 기록
2. 이 레포에 Issue 생성:
   ```bash
   gh issue create --repo sylee999/ghostty-tmux-claude-setup \
     --title "validation fail: 2.X on $(hostname)" \
     --body "..."
   ```
3. Issue 링크 공유

## 4. 모두 통과 후 (public 전환)

```bash
gh repo edit sylee999/ghostty-tmux-claude-setup \
  --visibility public \
  --accept-visibility-change-consequences
```

## 5. 통과 후 다음 단계 (동료 공유)

- 내부 위키 (Confluence) 에 증상-원인-해결 표 + 레포 URL 링크 게시
- 한계 섹션 먼저 제시 (`파일:라인` 이동 불가 등)
- 담당자·갱신 주기 명시

---

**마지막 검증 기록**: (다음 기기에서 채우기)

```
Date:
Host:
tmux version:
Claude Code version:
All checks passed: Y/N
Notes:
```
