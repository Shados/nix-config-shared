function nxrb
  set -l action
  set -l build_attr
  set -l local_opts
  # Nix 2.0 build porcelain on nixos-rebuild, mostly.
  if test (count $argv) -lt 1
    echo "Please supply a `nixos-rebuild` action/subcommand to perform"
    return 1
  else
    set action $argv[1]
  end
  switch $action
    case "switch"
      set build_attr "system"
      set local_opts $local_opts "keep-going"
    case "boot"
      set build_attr "system"
      set local_opts $local_opts "keep-going"
    case "test"
      set build_attr "system"
      set local_opts $local_opts "keep-going"
    case "build"
      set build_attr "system"
      set local_opts $local_opts "keep-going"
    case "dry-build"
      set build_attr "system"
      set local_opts $local_opts "keep-going"
    case "dry-activate"
      set build_attr "system"
      set local_opts $local_opts "keep-going"
    case "build-vm"
      set build_attr "vm"
      set local_opts $local_opts "keep-going"
    case "build-vm-with-bootloader"
      set build_attr "vmWithBootLoader"
      set local_opts $local_opts "keep-going"
    case '*'
      echo "Please supply a *valid* `nixos-rebuild` action/subcommand to perform"
      return 1
  end

  set -l final_opts
  for o in $local_opts
    set final_opts $final_opts "--option" "$o" "true"
  end
  set final_opts $final_opts $NXRB_OPTS
  nix $final_opts build --no-link "(with import <nixpkgs/nixos> { }; $build_attr)"
  if test $status -eq 0
    sudo nixos-rebuild $argv
  end
end
