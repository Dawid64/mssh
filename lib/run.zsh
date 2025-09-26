msh::run::start_command() {
  local out_file="$1" status_file="$2"; shift 2
  nohup "$MSH_ROOT/bin/msh-supervisor.zsh" --out "$out_file" --status "$status_file" -- "$@" \
    >/dev/null 2>&1 &
  echo $!
}
msh::run::start_monitor() {
  local status_file="$1" out_file="$2" url="$3" topic="$4" cmd_str="$5" sup_pid="$6"
  nohup "$MSH_ROOT/bin/msh-monitor.zsh" \
    --status "$status_file" --out "$out_file" --pid "$sup_pid" \
    --url "$url" --topic "$topic" --cmd "$cmd_str" \
    >/dev/null 2>&1 &
  echo $!
}
