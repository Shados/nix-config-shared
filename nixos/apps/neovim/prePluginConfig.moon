-- Pull some vim stuff into local scope for easier access
{ :api, :cmd, :fn, :g, :env, :o, :opt, :bo, :wo, :empty_dict } = vim
{ :stdpath } = fn
map = api.nvim_set_keymap

-- Helpers
dir_exists = (dir) -> (fn.isdirectory dir) != 0

-- Helper function that acts more like vimscript's ':set'
set = do
  options_metadata = api.nvim_get_all_options_info!
  is_global = (info) -> info.scope == "global"
  is_buffer = (info) -> info.scope == "buf"
  is_window = (info) -> info.scope == "win"

  (name, value) ->
    info = assert options_metadata[name], "Did not find option named: #{name}"
    if info.global_local or (is_global info)
      api.nvim_set_option name, value
    elseif is_buffer info
      api.nvim_buf_set_option 0, name, value
      unless info.global_local
        api.nvim_set_option name, value
    elseif is_window info
      api.nvim_win_set_option 0, name, value
      unless info.global_local
        api.nvim_set_option name, value
    return

-- Convenience wrapper for group-scoped autocmd creation
augroup = (name, scoped_fn, group_opts={}) ->
  group = vim.api.nvim_create_augroup name, group_opts

  autocmd = (event, opts) ->
    opts.group = group
    vim.api.nvim_create_autocmd event, opts

  scoped_fn(autocmd)
  return group


-- Takes a path and 'squishes' it to fit a maximum character-width, replacing
-- the middle section with an interposed "squish indicator"
contract_path = (path, max, interpose="~...~", trail="~..") ->
  return path if #path <= max

  section_length = math.floor ((max - #interpose)/2)

  -- Check the length of the last path component, as we'd like to preserve it
  -- while still retaining leading context if possible, but will fallback to a
  -- more aggressive approach otherwise
  last_name_start, _, last_name = path\find "(/[^/]+)$"
  if #last_name <= section_length
    -- The last path element is short enough to preserve in full
    head = path\sub 1, section_length
    tail = path\sub -section_length
    res = head .. interpose .. tail
    assert #res <= max
    return res
  else
    -- Preference preserving more of the last path element, but try to still
    -- keep at least enough of the head to know the type of path (absolute,
    -- relative, home-relative) and the first letter of its first child
    -- element. In the worst case, we just return as much of the last path
    -- element as we can.
    half_interpose = math.ceil (#interpose/2)
    min_head_length = 3
    if max >= (min_head_length + #interpose + #last_name)
      -- We have enough space to preserve the last path element in full
      max_75pct = math.floor(((max*3/4) - half_interpose))
      tail_length = math.max(#last_name, max_75pct)
      head_length = max - tail_length - #interpose

      head = path\sub 1, head_length
      -- If the last path element isn't short enough, we need to strip some of it
      -- as well, preserving the leading portions of it
      tail = path\sub -tail_length
      return head .. interpose .. tail
    else
      -- We need to shrink the last path element, preserving the earlier
      -- characters of it
      head_length = 3
      tail_length = max - head_length - #interpose
      if tail_length - #trail >= 5
        -- We can keep the minimum head and still preserve at least 5
        -- characters of the last path element
        head = path\sub 1, head_length
        tail = if #last_name <= tail_length
          path\sub -tail_length
        else
          (path\sub last_name_start, last_name_start + tail_length - #trail - 1) .. trail
        return head .. interpose .. tail
      else
        -- We can't afford to keep even the minimum head around
        tail_length = math.min max, (#last_name - 1)
        tail = if #last_name - 1 <= tail_length
          path\sub -tail_length
        else
          (path\sub last_name_start +1, last_name_start + tail_length - #trail - 1) .. trail
        return tail\sub 1, max


export nvim
nvim = { :augroup, :dir_exists, :set, :contract_path }

-- Early-load settings
tc = (str) -> vim.api.nvim_replace_termcodes str, true, true, true
g["mapleader"] = tc "<Space>"

-- Define my autocmd group for later use
vim.api.nvim_create_augroup "vimrc", { clear: true }

-- Theming stuff
-- The xterm and screen ones are actually both for Mosh
acceptable_terms = {
  ["rxvt-unicode"]: true
  ["rxvt-unicode-256color"]: true
  xterm: true
  ["xterm-256color"]: true
  screen: true
  ["screen-256color"]: true
}
env_tmux = os.getenv("TMUX")
env_term = os.getenv("TERM")
if (env_tmux and #env_tmux > 0) or (env_term and acceptable_terms[env_term])
  set "termguicolors", true
