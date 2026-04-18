# 검증 가이드 (2번째 기기용)

이 문서는 **다른 기기에서 이 레포가 실제로 동작하는지** 검증하기 위한 체크리스트다.
세션·메모리에 의존하지 않도록 이 파일만 보고 진행 가능해야 함.

## 전제 기기

- macOS
- tmux ≥ 3.4 (`brew install tmux` / `brew upgrade tmux`)
- Ghostty 설치 + 기본 실행 환경
- Claude Code 로그인 완료

## 1. 설치

```bash
cd ~/Works/Projects  # 또는 원하는 위치
git clone https://github.com/sylee999/ghostty-tmux-claude-setup
cd ghostty-tmux-claude-setup
./check-env.sh          # 전제 검증 — 실패 0건 필요, 경고는 허용
./install.sh            # append/merge 설치
```

설치 후 **tmux 서버 재접속** (terminal-features 는 접속 시점에 평가됨):

```bash
tmux detach && tmux attach
# 또는 다른 클라이언트에서:
tmux kill-server && tmux
```

## 2. 검증 체크리스트

각 항목 순서대로 수행. 하나라도 실패 시 아래 "실패 리포트" 섹션 참조.

### 2.1 tmux terminal-features 반영

```bash
tmux display-message -p '#{client_termfeatures}'
```

**기대**: 결과에 `extkeys`, `hyperlinks` **둘 다 포함**.

---

### 2.2 Shift+Enter 줄바꿈

tmux 안의 Claude Code 에서 아무 문자 입력 후 **Shift+Enter**.

**기대**: 프롬프트가 전송되지 않고 새 줄로 넘어감 (멀티라인 입력 상태).

---

### 2.3 Shift+Cmd+Click 으로 URL 오픈

Claude Code 에서 아무 HTTP URL 이 포함된 출력 생성 (예: `echo "https://example.com"`). 해당 URL 위에 **Shift+Cmd+Click**.

**기대**: 시스템 기본 브라우저가 URL 을 엶. (Shift 가 tmux 마우스 캡처를 우회해 Ghostty 까지 이벤트가 전달됨)

---

### 2.4 (제거됨) Alt+Click 파일 열기

이전 버전의 VS Code 연동 기능은 2026-04-18 제거되었습니다. Shift+Cmd+Click 으로 OSC 8 `file://` 링크 오픈은 시스템 기본 핸들러로 이동하며 VS Code 로 직접 열리지 않습니다.

---

### 2.5 드래그 선택 + 복사

Claude Code 출력 영역에서 마우스로 텍스트 드래그 선택 후 손 떼기.

**기대**:
- 선택 영역이 주황색 배경으로 하이라이트됨
- 손 떼는 순간 시스템 클립보드로 복사됨 (다른 앱에 붙여넣기 검증)
- 선택 상태가 유지됨 (즉시 사라지지 않음)

---

### 2.6 더블클릭 단어 복사

Claude Code 출력의 단어 위에서 **더블클릭**.

**기대**: 단어 하이라이트 + 시스템 클립보드 복사. 선택 유지.

---

### 2.7 Esc 로 copy-mode 종료

위 선택 유지 상태에서 **Esc** 한 번.

**기대**: 선택 사라지고 즉시 Claude Code 프롬프트 영역으로 커서 복귀 (재클릭 불필요).

---

## 3. 실패 리포트

한 항목이라도 실패하면:

1. 실패 항목 번호 + 증상 + `check-env.sh` 출력 전체 기록
2. 이 레포에 Issue 생성 (templateless):
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

그 후 README 의 `YOUR_HANDLE` 을 `sylee999` 로 고정 (현재는 템플릿 상태가
아니라 실제 URL 이므로 확인만).

## 5. 통과 후 다음 단계 (동료 공유)

- 내부 위키 (Confluence) 에 증상-원인-해결 표 + 레포 URL 링크 게시
- 한계 섹션 먼저 제시 (OSC 8 미해결 등)
- 담당자·갱신 주기 명시

---

**마지막 검증 기록**: (다음 기기에서 채우기)

```
Date:
Host:
tmux version:
All checks passed: Y/N
Notes:
```
