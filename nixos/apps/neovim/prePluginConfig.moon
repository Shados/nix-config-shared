-- Pull some vim stuff into local scope for easier access
{ :api, :cmd, :fn, :g, :env, :o, :bo, :wo, :empty_dict } = vim
{ :stdpath } = fn
map = api.nvim_set_keymap

-- Helpers
-- FIXME Replace by dependence on a library of my own making, or 0.5
-- compatibility shim
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


export nvim
nvim = { :dir_exists, :set }

-- Early-load settings
-- FIXME Once there's a nice way to create expr-quote values from Lua
space = api.nvim_eval '"\\<Space>"'
g["mapleader"] = space

-- Define my autocmd group for later use
-- FIXME Once there's a way to use augroup directly from Lua or the API
cmd "augroup vimrc | autocmd! | augroup END"

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
