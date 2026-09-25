#!/bin/bash
# PostToolUse guardrail: RecipeFinder bans the Combine framework (CLAUDE.md — use
# async/await instead). Warn-only, never mutates files. Reads the hook JSON from
# stdin, extracts the edited file path, and flags any reintroduced `import Combine`.
set -euo pipefail

input=$(cat)
file=$(printf '%s' "$input" | /usr/bin/python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    print(""); sys.exit(0)
ti = d.get("tool_input", {}) or {}
print(ti.get("file_path") or ti.get("path") or "")
')

[ -z "$file" ] && exit 0
case "$file" in
    *.swift) ;;
    *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

if grep -Eq '^[[:space:]]*import[[:space:]]+Combine\b' "$file"; then
    echo "Guardrail: '$file' contains 'import Combine'. RecipeFinder bans Combine (CLAUDE.md) — use Swift async/await instead." >&2
    exit 2
fi
exit 0
