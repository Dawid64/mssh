emulate -L zsh
setopt typeset_silent
MSH_ROOT="${MSH_ROOT:-$HOME/.zsh/mssh}"
source "$MSH_ROOT/lib/util.zsh"
source "$MSH_ROOT/lib/config.zsh"
source "$MSH_ROOT/lib/notify.zsh"
source "$MSH_ROOT/lib/run.zsh"

msh() {
  emulate -L zsh
  setopt typeset_silent
  msh::config::init

  if [[ "$1" == "doctor" ]]; then
    msh::config::load
    print "curl: $(command -v curl >/dev/null && echo ok || echo missing)"
    print "ntfy url: ${MSH_NTFY_URL:-<unset>}"
    print "default topic: ${MSH_DEFAULT_TOPIC:-<unset>}"
    if [[ -n "$MSH_NTFY_URL" && -n "$MSH_DEFAULT_TOPIC" ]]; then
      msh::notify::send "msh doctor" "test notification $(date '+%F %T')" "$MSH_NTFY_URL" "$MSH_DEFAULT_TOPIC"
      print "sent a test notification to ${MSH_DEFAULT_TOPIC}"
    fi
    return 0
  fi

  local conf_changed=false
  local -a rest=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help) msh::util::usage; return 0 ;;
      --config-url)    [[ $# -ge 2 ]] || { print -u2 "Missing value for --config-url"; return 1; }
                       msh::config::save_kv ntfy_url "$2"; conf_changed=true; shift 2; continue ;;
      --config-topic)  [[ $# -ge 2 ]] || { print -u2 "Missing value for --config-topic"; return 1; }
                       msh::config::save_kv topic "$2"; conf_changed=true; shift 2; continue ;;
      --) shift; break ;;
      --*) print -u2 "Unknown option: $1"; return 1 ;;
      *) break ;;
    esac
  done
  rest=("$@"); set -- "${rest[@]}"

  local OUT_FILE="$PWD/output.out"
  local NOTIFY=0
  local TOPIC_OVERRIDE=""
  local OPTIND=1 opt
  while getopts ":f:nt:h" opt; do
    case "$opt" in
      f) OUT_FILE="$OPTARG" ;;
      n) NOTIFY=1 ;;
      t) TOPIC_OVERRIDE="$OPTARG" ;;
      h) msh::util::usage; return 0 ;;
      \?) print -u2 "Unknown flag: -$OPTARG"; msh::util::usage; return 1 ;;
      :)  print -u2 "Flag -$OPTARG requires an argument"; return 1 ;;
    esac
  done
  shift $((OPTIND-1))

  if [[ $# -eq 0 ]]; then
    if [[ "$conf_changed" = true ]]; then
      echo "Configuration saved to $MSH_CONFIG_FILE"
      return 0
    fi
    msh::util::usage; return 1
  fi

  msh::util::mkparent "$OUT_FILE"
  msh::config::load
  local URL="${MSH_NTFY_URL:-}"
  local TOPIC="${TOPIC_OVERRIDE:-${MSH_DEFAULT_TOPIC:-}}"
  if [[ "$NOTIFY" = "1" && ( -z "$URL" || -z "$TOPIC" ) ]]; then
    print -u2 "warning: -n requested but ntfy url/topic not set (use --config-url / --config-topic or -t)"
  fi

  local RUN_DIR; RUN_DIR="$(msh::util::new_run_dir)"
  local STATUS_FILE="$RUN_DIR/status"
  local CMD_STR="$(msh::util::build_cmd_string "$@")"

  local SUP_PID; SUP_PID="$(msh::run::start_command "$OUT_FILE" "$STATUS_FILE" "$@")" || { print -u2 "failed to start"; return 1; }

  print -r -- "$CMD_STR"   > "$RUN_DIR/cmd"
  print -r -- "$SUP_PID"   > "$RUN_DIR/pid"
  print -r -- "$OUT_FILE"  > "$RUN_DIR/out"
  print -r -- "$STATUS_FILE" > "$RUN_DIR/status_path"

  if [[ "$NOTIFY" = "1" && -n "$URL" && -n "$TOPIC" ]]; then
    msh::run::start_monitor "$STATUS_FILE" "$OUT_FILE" "$URL" "$TOPIC" "$CMD_STR" "$SUP_PID" >/dev/null
  fi

  print "Started [pid $SUP_PID]"
  print "Output: $OUT_FILE"
  print "Run dir: $RUN_DIR"
}
