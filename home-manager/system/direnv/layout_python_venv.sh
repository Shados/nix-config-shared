#!/usr/bin/env bash

# Usage: layout python <python_exe>
#
# Creates and loads a virtual environment under
# "$direnv_layout_dir/python-$python_version".
# This forces the installation of any egg into the project's sub-folder.
# For python older then 3.3 this requires virtualenv to be installed.
#
# It's possible to specify the python executable if you want to use different
# versions of python.
#
layout_python_venv() {
  local old_env
  old_env=$(direnv_layout_dir)/virtualenv
  local python=${1:-python}
  [[ $# -gt 0 ]] && shift
  if [[ $# -gt 0 ]]; then
    VIRTUAL_ENV=$1
    shift
  fi
  if [[ -z "$VIRTUAL_ENV" ]] || [[ ! -d "$VIRTUAL_ENV" ]]; then
    if [[ -d $old_env && $python == python ]]; then
      VIRTUAL_ENV=$old_env
    else
      if [[ -z "$VIRTUAL_ENV" ]]; then
        VIRTUAL_ENV=$(direnv_layout_dir)/python-$python_version
      fi
      unset PYTHONHOME
      local python_version ve
      # shellcheck disable=SC2046
      read -r python_version ve <<<$($python -c "import pkgutil as u, platform as p;ve='venv' if u.find_loader('venv') else ('virtualenv' if u.find_loader('virtualenv') else '');print(p.python_version()+' '+ve)")
      if [[ -z $python_version ]]; then
        log_error "Could not find python's version"
        return 1
      fi

      case $ve in
      "venv")
        if [[ ! -d $VIRTUAL_ENV ]]; then
          $python -m venv "$@" "$VIRTUAL_ENV"
        fi
        ;;
      "virtualenv")
        if [[ ! -d $VIRTUAL_ENV ]]; then
          $python -m virtualenv "$@" "$VIRTUAL_ENV"
        fi
        ;;
      *)
        log_error "Error: neither venv nor virtualenv are available."
        return 1
        ;;
      esac
    fi
  fi
  export VIRTUAL_ENV
  PATH_add "$VIRTUAL_ENV/bin"
}

# vim: set ft=sh:
