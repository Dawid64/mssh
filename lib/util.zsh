msh::util::ensure_dirs() {
  [[ -d "$MSH_CONFIG_DIR" ]] || mkdir -p "$MSH_CONFIG_DIR"
  [[ -f "$MSH_CONFIG_FILE" ]] || : > "$MSH_CONFIG_FILE"
  [[ -d "$MSH_RUNS_DIR" ]] || mkdir -p "$MSH_RUNS_DIR"
}
msh::util::usage() {
  cat <<'EOF'
msh [-n] [-t topic] [-f file] [--config-url URL] [--config-topic TOPIC] -- <command ...>
Examples:
  msh python run.py
  msh -f test.out python run.py
  msh -n python run.py
  msh -n -t topic_name -f my.out python -m src.main arg1 arg2 --flag
  msh --config-url https://ntfy.sh
  msh --config-topic my_default_topic
  msh doctor
EOF
}
msh::util::build_cmd_string() { printf "%q " "$@"; }
msh::util::mkparent() { local p; p="$(dirname -- "$1")"; [[ -d "$p" ]] || mkdir -p -- "$p"; }
msh::util::new_run_dir() {
  local ts rnd id dir
  ts="$(date +%s)"
  rnd="$RANDOM$RANDOM"
  id="${ts}-${rnd}-$$"
  dir="$MSH_RUNS_DIR/$id"
  mkdir -p "$dir"
  print -r -- "$dir"
}
