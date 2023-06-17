function pathcount
  if test (count $argv) -gt 1
    echo "$_ only takes one argument!"
    return 1
  end

  find $argv -type d | while read _dir
    set -l _files "$_dir"/*
    set -l _fcount (count $_files)
    printf "%5d files in directory %s\n" "$_fcount" "$_dir"
  end
  return 0
end
