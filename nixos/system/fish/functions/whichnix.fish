function whichnix
  function BAD_ARGS
    echo "Invalid arguments: whichnix takes either the name of a Nix store binary in path as a single argument, or passed via stdin on a single line"
  end

  # Declare variable(s) to hold argument(s)
  set -l prog_name

  # Handle argument(s)
  if test (count $argv) -eq 1
    set prog_name $argv[1]
  else if test (count $argv) -gt 1
    echo (BAD_ARGS)
    return 1
  else
    if isatty stdin
      echo (BAD_ARGS)
      return 1
    else
      read prog_name
    end
  end

  # Actual code
  realpath (which $prog_name)
end
