msh::notify::send() {
  local title="$1" body="$2" url="$3" topic="$4"
  [[ -n "$url" && -n "$topic" ]] || return 0
  command -v curl >/dev/null 2>&1 || return 0
  curl -fsSL -H "Title: $title" -H "Content-Type: text/plain; charset=utf-8" \
    --data-binary "$body" "${url%/}/$topic" >/dev/null 2>&1 || true
}
