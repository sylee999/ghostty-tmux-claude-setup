# 동료 공유 위키 작성 계획

## 목적

네이버 사내 동료들이 Ghostty + tmux + Claude Code 조합에서 동일한 마찰을
겪을 때, "혼자 힘든 게 아니다" 를 확인시키고 빠른 해결 경로를 제공한다.

**검증 선행 조건**: VALIDATION.md 의 2.1–2.7 모두 통과한 후에만 게시.
미검증 상태 공유는 "내 기기에선 됩니다" 사태 유발.

## 게시 위치

**Naver Confluence (wiki.navercorp.com)**

- Space: 개인 스페이스 또는 팀 스페이스 (팀 정책 따라)
- 경로 제안: `개발 환경 / 터미널 셋업 / Ghostty + tmux + Claude Code 마찰 해소`
- Claude Code 에서 `naver-confluence` 스킬로 작성 가능

## 타겟 독자와 읽기 시간

- 동일 문제 겪는 동료 (실질 타겟)
- 막연히 "tmux 설정 공유해줘" 요청한 동료 (부수적)
- 읽기 시간 3분 이내

## 문서 구조 (권장 순서)

### 1. TL;DR (3줄)

```
Ghostty + tmux + Claude Code 조합은 기본값으로 Shift+Enter, 파일 링크 클릭,
마우스 복사가 깨진다. 공식 문서 설정 + 우회 스크립트로 대부분 해결 가능.
완전 해결 아님 (OSC 8 클릭은 Alt+Click 우회로 갈음).
```

### 2. 증상 → 원인 → 해결 표

README.md 의 동일 표를 그대로 재사용. 5개 행.

### 3. "해결하지 못한 것" (맨 앞으로 뽑지 말 것)

중요: **한계 섹션은 반드시 포함**. 숨기면 동료가 OSC 8 을 파고들어 시간 낭비.

- OSC 8 Cmd+Click 근본 해결 X — Alt+Click 스크립트 우회
- TUI 깜빡임 미해결 — `/tui fullscreen` 시도 가능하나 근본 아님

### 4. 적용 방법

```
git clone https://github.com/sylee999/ghostty-tmux-claude-setup
cd ghostty-tmux-claude-setup
./check-env.sh
./install.sh
tmux detach && tmux attach
```

레포 README 로 링크. 위키에서 설치 방법을 중복 유지보수하지 말 것.

### 5. 참고 이슈 링크

- Claude Code 공식: https://code.claude.com/docs/en/terminal-config
- GitHub issues: #17168 · #23438 · #27047 · #37283

### 6. 담당 / 갱신 주기

```
작성자: {이름}
검증 기기·환경: {macOS 버전, tmux 버전, Ghostty 버전} 2026-04-17
유지보수: best effort, 보장 없음
갱신 트리거: Claude Code/tmux/Ghostty 메이저 업데이트 시 직접 재검증
```

## 절대 하지 말 것

- 오늘 대화 로그 그대로 붙여넣기 (틀린 시도 80%)
- "완벽 가이드" 포장 — 한계를 먼저 쓸 것
- 증상별 스크린샷 없이 "이렇게 됩니다" 서술만
- 문서 길이 1000단어 초과 (동료가 안 읽음)

## 공유 후 피드백 수집

- Confluence 페이지 댓글
- 안 되면 GitHub Issue 로 유도 (레포 README 참조)
- 3명 이상 동료가 성공 리포트 주면 "검증됨" 섹션 추가
