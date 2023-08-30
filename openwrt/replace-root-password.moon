#!/usr/bin/env moon

local *

main = (cli_args) ->
  password_hash = cli_args[1]

  -- Read shadow file, locate root's line, and generate a copy with its
  -- password modified
  shadow = io.open "/etc/shadow", "r"
  updated_lines = {}
  found_root = false
  for line in shadow\lines!
    if (line\sub 1, 4) == "root"
      found_root = true
      line = line\gsub "^([^:]+):[^:]*:", "%1:#{password_hash}:", 1

    updated_lines[#updated_lines + 1] = line
  shadow\close!

  -- Write out updated shadow file
  shadow = io.open "/etc/shadow", "w"
  for line in *updated_lines
    shadow\write line
    shadow\write "\n"

  if found_root
    print("Updated root user's hashed password")
    os.exit 0
  else
    print("Wasn't able to find the root user entry to modify!")
    os.exit 1


main(arg)
