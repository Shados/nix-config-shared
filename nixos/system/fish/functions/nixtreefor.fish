function nixtreefor
  function BAD_ARGS
    echo "Invalid arguments: nixtreefor takes one argument (a Nix-store binary name), with any following arguments being passed to the internal 'tree' invocation"
  end

  # Declare variable(s) to hold argument(s)
  set -l prog_name
  set -l extra_args

  # Handle argument(s)
  if test (count $argv) -gt 0
    set prog_name $argv[1]
    if test (count $argv) -gt 1
      set extra_args $argv[2..-1]
    end
  else
    BAD_ARGS
    return 1
  end

  # Actual code
  tree -lC $extra_args (nixdir $prog_name) | less -R
end
