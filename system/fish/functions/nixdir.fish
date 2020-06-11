function nixdir
  function BAD_ARGS
    echo "Invalid arguments: nixdir takes either the name of a Nix store binary in path as a single argument, or passed via stdin on a single line"
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
  set -l split_path (whichnix $prog_name | string split -m 4 '/')
  # 1..4 to capture the empty string prior to the first / in the path
  string join '/' $split_path[1..4]
end

