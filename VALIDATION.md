# 검증 가이드 (2번째 기기용)

이 문서는 **다른 기기에서 이 레포가 실제로 동작하는지** 검증하기 위한 체크리스트다.
세션·메모리에 의존하지 않도록 이 파일만 보고 진행 가능해야 함.

## 전제 기기

- macOS
- zsh (install.sh 가 `~/.zshrc` 에 환경변수 append)
- tmux ≥ 3.4 (`brew install tmux` / `brew upgrade tmux`)
- Ghostty 설치 + 기본 실행 환경
- Claude Code **v2.1.89 이상** (fullscreen rendering 지원)

## 1. 설치

```bash
cd ~/Works/Projects  # 또는 원하는 위치
git clone https://github.com/sylee999/ghostty-tmux-claude-setup
cd ghostty-tmux-claude-setup
./check-env.sh          # 전제 검증 — 실패 0건 필요, 경고는 허용
./install.sh            # append/merge 설치 (tmux.conf + .zshrc + keybindings.json)
```

설치 후 tmux + shell + Claude Code 모두 재시작:

```bash
tmux kill-server && tmux     # 또는: tmux detach && tmux attach
exec zsh                      # 환경변수 반영
# Claude Code 도 종료 후 새 세션으로 재시작
```

## 2. 검증 체크리스트

각 항목 순서대로 수행. 하나라도 실패 시 아래 "실패 리포트" 섹션 참조.

### 2.1 tmux terminal-features 반영

```bash
tmux display-message -p '#{client_termfeatures}'
```

**기대**: 결과에 `extkeys`, `hyperlinks` **둘 다 포함**.

---

### 2.2 환경변수 반영

```bash
env | grep CLAUDE_CODE_
```

**기대**: `CLAUDE_CODE_NO_FLICKER=1`, `CLAUDE_CODE_DISABLE_MOUSE=1` 둘 다 출력.

---

### 2.3 Shift+Enter 줄바꿈

tmux 안의 Claude Code 에서 아무 문자 입력 후 **Shift+Enter**.

**기대**: 프롬프트가 전송되지 않고 새 줄로 넘어감 (멀티라인 입력 상태).

---

### 2.4 더블클릭 단어 복사 (스크롤 없음)

Claude Code 출력에서 아무 단어 위에 **더블클릭**.

**기대**:
- 주황색 하이라이트로 단어 선택
- 시스템 클립보드에 복사 (다른 앱에서 Cmd+V 로 확인)
- 팬이 맨 아래로 스크롤하지 **않음**
- 선택 유지 상태로 남음

이 항목이 실패 = `CLAUDE_CODE_DISABLE_MOUSE=1` 가 적용 안 됐을 가능성. Claude Code 재시작 확인.

---

### 2.5 Shift+Cmd+Click 으로 URL 오픈

Claude Code 에서 아무 HTTP URL 생성 (예: `echo "https://example.com"`). URL 에 **Shift+Cmd+Click**.

**기대**: 시스템 기본 브라우저가 URL 오픈 (Shift 가 tmux 마우스 캡처 우회).

---

### 2.6 드래그 선택 + 복사

Claude Code 출력 영역에서 마우스 드래그 선택 후 손 떼기.

**기대**:
- 주황색 하이라이트
- 손 떼는 순간 시스템 클립보드로 복사
- 선택 유지

---

### 2.7 Esc 로 copy-mode 종료

위 선택 유지 상태에서 **Esc**.

**기대**: 선택 사라지고 즉시 Claude Code 프롬프트 영역으로 커서 복귀.

---

### 2.8 (알려진 한계) `파일:라인` 링크 클릭

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
