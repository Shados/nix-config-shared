#!/usr/bin/env moon
-- TODO replace uv asserts with context-tagging variant?
json = require 'rapidjson'
inspect = require 'inspect'
uv = require 'luv'

local copy_file, copy_dir, copy_tree, mkdir_p, path_parent, populate_dir, populate_file, populate_symlink, walk_tree

main = (cli_args) ->
  files_json_path = cli_args[1]
  output_root = cli_args[2]
  files_json = json.load(files_json_path)
  directories = {path,attrs for path,attrs in pairs files_json when attrs.type == "directory"}
  symlinks = {path,attrs for path,attrs in pairs files_json when attrs.type == "symlink"}
  files = {path,attrs for path,attrs in pairs files_json when attrs.type == "file"}

  for path, attrs in pairs directories
    populate_dir output_root, path, attrs
  for path, attrs in pairs symlinks
    populate_symlink output_root, path, attrs
  for path, attrs in pairs files
    populate_file output_root, path, attrs

  os.exit 0

populate_dir = (output_root, path, attrs) ->
  -- NOTE: Paths always start with /, as they are absolute, but should only end
  -- in / for the root path, in which case we strip it
  output_path = if path == "/" then output_root else "#{output_root}#{path}"

  if attrs.source != json.null
    copy_tree attrs.source, output_path, attrs.mode
  else
    print "Creating directory #{output_path} with mode #{attrs.mode}..."
    mkdir_p output_path, attrs.mode

copy_tree = (source_root, dest_root, mode) ->
  
  copy_dir source_root, dest_root, mode

  walk_tree source_root, (dir_entry) ->
    subpath = dir_entry.path
    switch dir_entry.type
      when "directory"
        copy_dir "#{source_root}/#{subpath}", "#{dest_root}/#{subpath}", "0755", 0, 0
      when "file"
        copy_file "#{source_root}/#{subpath}", "#{dest_root}/#{subpath}", "0644", 0, 0
      -- TODO
      when "symlink"
        -- TODO should I maybe handle symlinks specially, e.g. mangle them?
        assert false, "Copying symlinks within a copied directory is not yet implemented"

  return

copy_dir = (s, d, mode) ->
  print "Copying directory #{s} to #{d} with mode #{mode}..."
  mkdir_p d, mode

copy_file = (s, d, mode) ->
  print "Copying file #{s} to #{d} with mode #{mode}..."
  assert uv.fs_copyfile s, d, nil
  assert uv.fs_chmod d, (tonumber mode, 8), nil

walk_tree = (root, cb) ->
  dir_stack = {root}
  done = false
  while not done
    path = table.remove dir_stack
    subpath = path\sub (#root + 2) -- 2 to cover the trailing /
    -- NOTE: We *have* to give this a limit or it defaults to 1. So we do some
    -- jankiness to loop uv.fs_readdir to handle the fact that we might not get
    -- all entries in one call
    dir = assert uv.fs_opendir path, nil, 1000
    while true
      entries = uv.fs_readdir dir, nil
      break unless entries
      for entry in *entries
        entry_path = if #subpath > 0 then "#{subpath}/#{entry.name}" else entry.name
        entry = { path: entry_path, type: entry.type }
        cb entry
        if entry.type == "directory"
          table.insert dir_stack, "#{root}/#{entry.path}"
    assert dir\closedir nil

    done = #dir_stack == 0

  return

populate_symlink = (output_root, path, attrs) ->
  output_path = if path == "/" then output_root else "#{output_root}#{path}"
  -- TODO should I maybe handle symlinks specially, e.g. mangle them?
  assert false, "Copying symlinks is not yet implemented"
  return

populate_file = (output_root, path, attrs) ->
  output_path = if path == "/" then output_root else "#{output_root}#{path}"
  -- Ensure parent directory exists first
  parent = path_parent output_path
  assert mkdir_p parent, "755"
  copy_file attrs.source, output_path, attrs.mode
  return

mkdir_p = (path, mode) ->
  if not uv.fs_access path, "RX", nil
    parent = path_parent path
    -- Ensure parent exists
    assert mkdir_p parent, mode
    assert uv.fs_mkdir path, (tonumber mode, 8), nil
  else
    true

path_parent = (path) ->
  len = #path
  return "." if len == 0

  local last_slash
  for i = len, 1, -1
    char = path\sub i, i
    if char == "/"
      last_slash = i
      break
  -- If we haven't found a slash, it's a two-component implicitly relative
  -- path, so the parent is just "."
  return "." unless last_slash

  last_slash = last_slash - 1 if last_slash != 1 else 1
  str = path\sub 1, last_slash
  if (path\sub 1, 1) == "/"
    -- Handle absolute paths
    return str
  elseif (path\sub 1, 2) == "./"
    -- Handle explicitly relative paths
    return str
  else
    -- Handle implicitly relative paths
    return "./" .. str

main(arg)
