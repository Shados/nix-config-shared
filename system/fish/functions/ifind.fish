function ifind -d "Case-insensitive quick recursive find-by-name"
  if test (count $argv) -lt 1
    echo "Please supply a name to search for"
    return 1
  end

  set -l name $argv[1]
  find . -iname "*$name*"
end
