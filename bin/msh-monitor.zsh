#!/usr/bin/env zsh
emulate -L zsh
setopt typeset_silent
STATUS=""; OUT=""; PID=""; URL=""; TOPIC=""; CMD=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --status) STATUS="$2"; shift 2 ;;
    --out)    OUT="$2"; shift 2 ;;
    --pid)    PID="$2"; shift 2 ;;
    --url)    URL="$2"; shift 2 ;;
    --topic)  TOPIC="$2"; shift 2 ;;
    --cmd)    CMD="$2"; shift 2 ;;
    --) shift; break ;;
    *) break ;;
  esac
done
while :; do
  if [[ -s "$STATUS" ]]; then break; fi
  if [[ -n "$PID" ]] && ! kill -0 "$PID" 2>/dev/null; then break; fi
  sleep 1
done
ec="255"
[[ -s "$STATUS" ]] && ec="$(<"$STATUS")"
if [[ -n "$URL" && -n "$TOPIC" ]] && command -v curl >/dev/null 2>&1; then
  if [[ "$ec" = "0" ]]; then
    body=$(printf "%s\n\n%s\n\nOutput: %s" "$(date '+%Y-%m-%d %H:%M:%S')" "$CMD" "$OUT")
    curl -fsSL -H "Title: Job finished running" -H "Content-Type: text/plain; charset=utf-8" \
      --data-binary "$body" "${URL%/}/$TOPIC" >/dev/null 2>&1 || true
  else
    tail_txt="$( (tail -n 50 "$OUT" 2>/dev/null) || echo "No output captured" )"
    curl -fsSL -H "Title: Job failed" -H "Content-Type: text/plain; charset=utf-8" \
      --data-binary "$tail_txt" "${URL%/}/$TOPIC" >/dev/null 2>&1 || true
  fi
fi
exit 0
