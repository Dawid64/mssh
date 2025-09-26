#!/usr/bin/env zsh
emulate -L zsh
setopt typeset_silent
OUT=""; STATUS=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --out) OUT="$2"; shift 2 ;;
    --status) STATUS="$2"; shift 2 ;;
    --) shift; break ;;
    *) break ;;
  esac
done
: > "$OUT"
: > "$STATUS"
"$@" >> "$OUT" 2>&1
ec=$?
print -r -- "$ec" > "$STATUS"
exit $ec
