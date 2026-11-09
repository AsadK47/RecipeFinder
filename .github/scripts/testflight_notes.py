#!/usr/bin/env python3
"""Turn commit subjects into tester-friendly "What to Test" lines: user-facing feat/fix commits only.

Reads subjects on stdin (one per line, newest first), writes the notes to stdout.
"""
import re
import sys

PATTERN = re.compile(r"^(feat|fix)(\([^)]*\))?!?:\s*(.+)$")


def notes(subjects: list) -> str:
    lines = []
    for subject in subjects:
        match = PATTERN.match(subject.strip())
        if match:
            text = match.group(3).strip()
            kind = "New" if match.group(1) == "feat" else "Fixed"
            lines.append(f"• {kind}: {text[:1].upper()}{text[1:]}")
    return "\n".join(lines) if lines else "Behind-the-scenes improvements — nothing new to test."


if __name__ == "__main__":
    print(notes(sys.stdin.read().splitlines()))
