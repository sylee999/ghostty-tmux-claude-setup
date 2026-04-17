#!/usr/bin/env python3
"""
Alt+Click handler: mouse_line + mouse_x → 해당 컬럼의 토큰 추출 → VS Code 로 열기.
CJK(Korean 등) 2-column width 고려, 절대 컬럼 위치 추적.

Usage (tmux binding):
  bind -n M-MouseDown1Pane run-shell -b "~/.config/tmux/open-path.sh '#{mouse_line}' '#{mouse_x}' '#{pane_current_path}'"
"""
import os
import re
import subprocess
import sys
from unicodedata import east_asian_width

VSCODE_BIN = "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"


def col_width(ch):
    """터미널 표시 컬럼 너비 (CJK는 2, 나머지는 1)."""
    return 2 if east_asian_width(ch) in ("W", "F") else 1


def find_token(line, click_x):
    """line 의 click_x 컬럼에 있는 공백 구분 토큰 반환. 없으면 None."""
    col = 0
    tok = ""
    tok_start = None
    for ch in line:
        w = col_width(ch)
        if ch == " " or ch == "\t":
            if tok and tok_start is not None and tok_start <= click_x < col:
                return tok
            tok = ""
            tok_start = None
        else:
            if not tok:
                tok_start = col
            tok += ch
        col += w
    if tok and tok_start is not None and tok_start <= click_x < col:
        return tok
    return None


def strip_punct(s):
    """양끝 구두점 제거."""
    return s.strip("()[]<>{}`'\".,;:")


def try_run(cmd):
    try:
        r = subprocess.run(cmd, capture_output=True, timeout=5)
        return r.returncode == 0
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


def main():
    if len(sys.argv) < 4:
        return
    line_text, click_x_raw, pane_path = sys.argv[1], sys.argv[2], sys.argv[3]
    if not line_text or not click_x_raw:
        return
    try:
        click_x = int(click_x_raw)
    except ValueError:
        return

    target = find_token(line_text, click_x)
    if not target:
        return
    target = strip_punct(target)
    if not target:
        return

    # path:line:col 또는 path:line 파싱
    m = re.match(r"^(.+):(\d+)(:\d+)?$", target)
    if m:
        path, file_line = m.group(1), m.group(2)
    else:
        path, file_line = target, None

    # 상대경로 → pane cwd 기준
    if not os.path.isabs(path):
        path = os.path.join(pane_path, path)

    if not os.path.exists(path):
        return

    if file_line:
        arg = f"{path}:{file_line}"
        if try_run(["code", "-g", arg]): return
        if try_run([VSCODE_BIN, "-g", arg]): return
        try_run(["open", path])
    else:
        if try_run(["code", path]): return
        if try_run([VSCODE_BIN, path]): return
        try_run(["open", path])


if __name__ == "__main__":
    main()
