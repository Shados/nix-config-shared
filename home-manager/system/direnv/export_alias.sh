#!/usr/bin/env bash
# TODO maybe set argv0 on the aliased command?
export_alias() {
  local name=$1
  shift
  local alias_dir=$PWD/.direnv/aliases
  local target="$alias_dir/$name"
  mkdir -p "$alias_dir"
  PATH_add "$alias_dir"
  echo "#!/usr/bin/env bash" >"$target"
  echo "set -e" >>"$target"
  printf "%s " "$@" >>"$target"
  printf '"$@"\n' >>"$target"
  chmod +x "$target"
}
