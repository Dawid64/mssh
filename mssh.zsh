=== mssh: Mega SSH alias manager v0.3 ===

export MSSH_DB="${MSSH_DB:-$HOME/.zsh/mssh/hosts}"

_mssh_init() {
  local dir; dir="$(dirname "$MSSH_DB")"
  [[ -d "$dir" ]] || mkdir -p "$dir"
  [[ -f "$MSSH_DB" ]] || : > "$MSSH_DB"
}

_mssh_usage() {
  cat <<'EOF'
Usage:
  mssh <alias>                        SSH to alias (ssh DEST)
  mssh --list | -l                    List aliases
  mssh --add  | -a DST ALIAS          Add/Update: alias -> DST
  mssh --add  | -a DST --wake WAKEHELPER MAC ALIAS
                                       Add/Update with WOL helper
  mssh --wake <alias>                 Wake (if configured) then SSH
  mssh --remove | -r <alias>          Remove alias
  mssh --help | -h                    Help

Examples:
  mssh --add me@my-pc my-pc
  mssh --add me@my-pc --wake root@10.10.1.50 AA:BB:CC:DD:EE:FF my-pc
  mssh my-pc
  mssh --wake my-pc
  mssh --list
EOF
}

_mssh_list() {
  _mssh_init
  if [[ ! -s "$MSSH_DB" ]]; then
    echo "mssh: no entries"
    return 0
  fi
  awk -F'\t' 'BEGIN{printf "%-16s %-28s %-24s %s\n","ALIAS","DESTINATION","WAKEHELPER","MAC"}
              {printf "%-16s %-28s %-24s %s\n",$1,$2,$3,$4}' "$MSSH_DB"
}

_mssh_get() {
  local key="$1"
  awk -F'\t' -v k="$key" '$1==k{print $2"\t"$3"\t"$4; exit}' "$MSSH_DB"
}

_mssh_put() {
  local key="$1" dest="$2" wakehelper="$3" mac="$4"
  local tmp; tmp="$(mktemp "${MSSH_DB}.XXXX")" || return 1
  awk -F'\t' -v OFS='\t' -v k="$key" -v v="$dest" -v w="$wakehelper" -v m="$mac" '
    BEGIN{updated=0}
    { if($1==k){$2=v;$3=w;$4=m;updated=1} ; print }
    END{ if(!updated) print k,v,w,m }
  ' "$MSSH_DB" > "$tmp" && mv "$tmp" "$MSSH_DB"
}

_mssh_add() {
  _mssh_init
  if [[ $# -lt 2 ]]; then
    echo "Usage: mssh --add DST ALIAS  |  mssh --add DST --wake WAKEHELPER MAC ALIAS" >&2
    return 1
  fi

  local dest="$1"; shift
  local wakehelper="" mac="" key=""

  if [[ "$1" == "--wake" ]]; then
    shift
    [[ $# -ge 3 ]] || { echo "mssh: missing args after --wake"; return 1; }
    wakehelper="$1"; mac="$2"; key="$3"
  else
    key="$1"
  fi

  if [[ -z "$dest" || -z "$key" ]]; then
    echo "mssh: bad arguments. See: mssh --help" >&2
    return 1
  fi

  _mssh_put "$key" "$dest" "$wakehelper" "$mac"
  echo "mssh: alias '$key' → $dest${wakehelper:+ (wake: $wakehelper $mac)}"
}

_mssh_remove() {
  _mssh_init
  local key="$1"
  [[ -n "$key" ]] || { echo "Usage: mssh --remove <alias>"; return 1; }
  if ! awk -F'\t' -v k="$key" '$1==k{found=1} END{exit !found}' "$MSSH_DB"; then
    echo "mssh: alias '$key' not found" >&2
    return 2
  fi
  local tmp; tmp="$(mktemp "${MSSH_DB}.XXXX")" || return 1
  awk -F'\t' -v k="$key" '$1!=k' "$MSSH_DB" > "$tmp" && mv "$tmp" "$MSSH_DB"
  echo "mssh: alias '$key' removed"
}

_mssh_connect() {
  _mssh_init
  local key="$1"
  local line dest wakehelper mac
  line="$(_mssh_get "$key")" || true
  IFS=$'\t' read -r dest wakehelper mac <<<"$line"
  if [[ -z "$dest" ]]; then
    echo "mssh: alias '$key' not found. Use: mssh --add DST $key" >&2
    return 3
  fi
  ssh "$dest"
}

_mssh_wake() {
  _mssh_init
  local key="$1"
  local line dest wakehelper mac host
  line="$(_mssh_get "$key")" || true
  IFS=$'\t' read -r dest wakehelper mac <<<"$line"
  if [[ -z "$dest" ]]; then
    echo "mssh: alias '$key' not found" >&2; return 3
  fi
  if [[ -z "$wakehelper" || -z "$mac" ]]; then
    echo "mssh: alias '$key' has no wake info. Re-add with --wake ..." >&2; return 4
  fi

  echo "Waking $key (MAC $mac) via $wakehelper ..."
  ssh -o BatchMode=yes "$wakehelper" "etherwake -b -i br-lan $mac" || {
    echo "mssh: wake command failed on $wakehelper" >&2; return 5; }

  host="${dest#*@}"; host="${host%%:*}"

  echo "Waiting for $host to become reachable..."
  local tries=60
  while (( tries-- > 0 )); do
    if ssh -o BatchMode=yes -o ConnectTimeout=2 "$dest" true 2>/dev/null; then
      echo "Host is up."
      break
    fi
    ping -c1 -W1 "$host" >/dev/null 2>&1 && echo "(ping ok, ssh not yet)"
    sleep 2
  done
  (( tries <= 0 )) && { echo "mssh: host did not come up in time"; return 6; }

  ssh "$dest"
}

mssh() {
  if [[ $# -eq 0 ]]; then _mssh_usage; return 1; fi
  case "$1" in
    --list|-l)    shift; _mssh_list ;;
    --add|-a)     shift; _mssh_add "$@" ;;
    --wake)       shift; _mssh_wake "$1" ;;
    --remove|-r)  shift; _mssh_remove "$1" ;;
    --help|-h)    _mssh_usage ;;
    -*)           echo "mssh: unknown option: $1" >&2; _mssh_usage; return 2 ;;
    *)            _mssh_connect "$1" ;;
  esac
}
