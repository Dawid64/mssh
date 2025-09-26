msh::config::init() {
  typeset -g MSH_CONFIG_DIR="${MSH_CONFIG_DIR:-$HOME/.zsh/msh}"
  typeset -g MSH_RUNS_DIR="$MSH_CONFIG_DIR/runs"
  typeset -g MSH_CONFIG_FILE="$MSH_CONFIG_DIR/config"
  msh::util::ensure_dirs
}
msh::config::load() {
  msh::util::ensure_dirs
  typeset -g MSH_NTFY_URL=""
  typeset -g MSH_DEFAULT_TOPIC=""
  local k v
  while IFS='=' read -r k v; do
    [[ -z "${k:-}" || "${k:0:1}" = "#" ]] && continue
    case "$k" in
      ntfy_url) MSH_NTFY_URL="$v" ;;
      topic)    MSH_DEFAULT_TOPIC="$v" ;;
    esac
  done < "$MSH_CONFIG_FILE"
}
msh::config::save_kv() {
  local key="$1" val="$2"
  msh::util::ensure_dirs
  if grep -qE "^${key}=" "$MSH_CONFIG_FILE"; then
    awk -v k="$key" -v v="$val" 'BEGIN{FS=OFS="="} $1==k{$2=v} {print}' \
      "$MSH_CONFIG_FILE" > "$MSH_CONFIG_FILE.tmp" && mv "$MSH_CONFIG_FILE.tmp" "$MSH_CONFIG_FILE"
  else
    printf "%s=%s\n" "$key" "$val" >> "$MSH_CONFIG_FILE"
  fi
}
