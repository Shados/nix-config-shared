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
SQUISH_PATH_INTERPOSE = "~...~"
squish_path = (path, max, interpose=SQUISH_PATH_INTERPOSE) ->
  return path if #path <= max

  section_length = math.floor ((max - #interpose)/2)
  head = path\sub 1, section_length
  tail = path\sub -section_length
  return head .. interpose .. tail


export nvim
nvim = { :augroup, :dir_exists, :set, :squish_path }

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
