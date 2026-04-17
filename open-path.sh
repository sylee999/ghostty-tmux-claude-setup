#!/bin/bash
# Alt+Click handler: extract file path (with optional :line[:col]) from mouse_line
# at mouse_x, open in VS Code. OSC 8 에 의존하지 않음.
#
# Usage (tmux binding):
#   bind -n M-MouseDown1Pane run-shell -b "~/.config/tmux/open-path.sh '#{mouse_line}' '#{mouse_x}' '#{pane_current_path}'"

line_text="$1"
click_x="$2"
pane_path="$3"

[ -z "$line_text" ] && exit 0
[ -z "$click_x" ] && exit 0

# 공백 구분 토큰 중 click_x 위치에 있는 것을 찾음
target=""
for tok in $line_text; do
  prefix="${line_text%%"$tok"*}"
  start=${#prefix}
  end=$((start + ${#tok}))
  if [ "$click_x" -ge "$start" ] && [ "$click_x" -lt "$end" ]; then
    target="$tok"
    break
  fi
  line_text="${line_text#*"$tok"}"
done

[ -z "$target" ] && exit 0

# 둘러싼 괄호/따옴표/쉼표/마침표 제거
target="${target#[\(\[\<\{\`\"\']}"
target="${target%[\)\]\>\}\`\"\',.;]}"

# path:line:col 또는 path:line 파싱
file_line=""
if [[ "$target" =~ ^(.+):([0-9]+)(:[0-9]+)?$ ]]; then
  path="${BASH_REMATCH[1]}"
  file_line="${BASH_REMATCH[2]}"
else
  path="$target"
fi

# 상대경로는 pane cwd 기준 해석
if [[ "$path" != /* ]]; then
  path="$pane_path/$path"
fi

[ ! -e "$path" ] && exit 0

# VS Code CLI — PATH 우선, 없으면 macOS 번들 바이너리, 최후엔 open
VSCODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"

if [ -n "$file_line" ]; then
  code -g "$path:$file_line" 2>/dev/null \
    || "$VSCODE_BIN" -g "$path:$file_line" 2>/dev/null \
    || open "$path"
else
  code "$path" 2>/dev/null \
    || "$VSCODE_BIN" "$path" 2>/dev/null \
    || open "$path"
fi
