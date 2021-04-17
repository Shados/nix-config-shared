{ :api, :cmd, :fn, :g, :env, :o, :bo, :wo, :empty_dict, :is_callable } = vim
{ :stdpath } = fn
{ :dir_exists, :set } = nvim
map = api.nvim_set_keymap

-- Basic configuration {{{
-- Resize splits when the window is resized
cmd 'autocmd vimrc VimResized * exe "normal! \\<c-w>="'

-- TODO move all these option-sets into a loop over an array? bit nicer
-- to configure
-- Search
-- Incremental searching
set "incsearch", true
-- Highlight matches by default
set "hlsearch", true
-- Ignore case when searching
set "ignorecase", true
-- ^ unless a capital letter is typed
set "smartcase", true

-- Hybrid relative line numbers
set "number", true
set "relativenumber", true

-- Indentation
-- Copy indent to new line
set "autoindent", true
-- Use 2-space autoindentation
set "shiftwidth", 2
set "softtabstop", 2
-- Together with ^, number of spaces a <Tab> counts for
set "tabstop", 2
-- Change <Tab> into spaces automatically in insert mode and with autoindent
set "expandtab", true
-- NOTE: Can insert a real <Tab> with CTRL-V<Tab> while in insert mode

-- Allow backspace in insert mode
set "backspace", "indent,eol,start"
set "history", 1000
-- Buffers are not unloaded when 'abandoned' by editing a new file, only when actively quit
set "hidden", true

-- Wrap lines...
set "wrap", true
-- ...visually, at convenient places
set "linebreak", true

-- Display <Tab>s and trailing spaces visually
set "list", true
set "listchars", "trail:·,tab:»·"
-- Because file-based folds are awesome
set "foldmethod", "marker"
-- Keep 6 lines minimum above/below cursor when possible; gives context
set "scrolloff", 6
-- Similar, but for vertical space & columns
set "sidescrolloff", 10
-- Minimum number of columns to scroll horiznotall when moving cursor off screen
set "sidescroll", 1
-- Previous two only apply when `wrap` is off, something I occasionally need to do
-- Disable mouse cursor movement
set "mouse", "c"
-- Support modelines in files
set "modeline", true
-- Always keep the gutter open, constant expanding/contracting gets annoying fast
set "signcolumn", "yes"

-- Set netrwhist home location to prevent .netrwhist being made in
-- .config/nvim/ -- it is data not config
g["netrw_home"] = (stdpath "data")
-- }}}

-- Advanced configuration {{{
-- Use ripgrep for search backend
-- vimgrep == needed for compatibility with ack.vim
-- no-heading == grouping by file isn't needed for this use-case
-- smart-case == case-insensitive search if all-lowercase pattern,
--               case-sensitive otherwise
g["ackprg"] = "#{rg_bin} --vimgrep --smart-case --no-heading --max-filesize=4M"
set "grepprg", "#{rg_bin} --vimgrep --smart-case --no-heading --max-filesize=4M"
set "grepformat", "%f:%l:%c:%m,%f:%l:%m"

-- When jumping from quickfix window to a location, use existing
-- matching open buffer if present
set "switchbuf", "useopen"

-- TODO: Delete old undofile automatically when vim starts
-- TODO: Delete old backup files automatically when vim starts
-- Both are under ~/.local/share/nvim/{undo,backup} in neovim by default
-- Keep undo history across sessions by storing it in a file
undodir = "#{env["HOME"]}/.local/share/nvim/undo/"
set "undodir", undodir
unless dir_exists undodir
  fn.mkdir undodir, "p"

backupdir = "#{env["HOME"]}/.local/share/nvim/backup/"
set "backupdir", backupdir
unless dir_exists backupdir
  -- TODO this doesn't work for backupdir, figure out why
  fn.mkdir backupdir, "p"
set "undofile", true
set "backup", true
-- This one creates temporary backup files, as opposed to the permanent
-- ones from 'backup', so disable it
set "writebackup", false
-- Otherwise, it may decide to do all writes by first moving the written
-- file to a temporary name, then writing out the modified files to the
-- original name, then moving the temporary file to the backupdir. This
-- approach generates way more filesystem events than necessary, and is
-- likely to trigger race conditions in e.g. compiler 'watch' modes that
-- use inotify.
set "backupcopy", "yes"

-- TODO: Make incremental search open all folds with matches while
-- searching, close the newly-opened ones when done (except the one the
-- selected match is in)

-- TODO: Configure makers for automake

-- File-patterns to ignore for wildcard matching on tab completion
set "wildignore", "*.o,*.obj,*~,*.png,*.jpg,*.gif,*.mp3,*.ogg,*.bin"

-- Have nvim jump to the last position when reopening a file
cmd 'autocmd vimrc BufReadPost * if line("\'\\"") > 1 && line("\'\\"") <= line("$") | exe "normal! g\'\\"" | endif'
-- Exclude gitcommit type to avoid doing this in commit message editor
-- sessions
cmd 'autocmd vimrc FileType gitcommit normal! gg0'

-- Default to opened folds in gitcommit filetype (having them closed by
-- default doesn't make sense in this context; only really comes up when
-- using e.g. `git commit -v` to get the commit changes displayed)
cmd 'autocmd vimrc FileType gitcommit normal zR'

-- Track window- and buffer-local options in sessions
-- FIXME replace once we have Lua equivalent to set+=
sessionoptions = o["sessionoptions"]
set "sessionoptions", "#{sessionoptions},localoptions"

-- TODO when working on code inside a per-project virtualenv or nix.shell,
-- automatically detect and use the python from the project env
-- }}}

-- Key binds/mappings {{{
-- Fuck hitting shift
map "", ";", ":", {}
-- Just in case we actually need ;, double-tap it
map "", ";;", ";", {noremap: true}
-- We leave the : mapping in place to avoid mishaps with typing
-- :Uppercasecommands

-- Easier window splits, C-w,v to vv, C-w,s to ss
map "n", "vv", "<C-w>v", {noremap: true, silent: true}
map "n", "ss", "<C-w>s", {noremap: true, silent: true}

-- Quicker split navigation with <leader>-h/l/j/k
map "n", "<leader>h", "<C-w>h", {noremap: true, silent: true}
map "n", "<leader>l", "<C-w>l", {noremap: true, silent: true}
map "n", "<leader>k", "<C-w>k", {noremap: true, silent: true}
map "n", "<leader>j", "<C-w>j", {noremap: true, silent: true}

-- Quicker split resizing with Ctrl-<Arrow Key>
map "n", "<C-Up>", "<C-w>+", {noremap: true}
map "n", "<C-Down>", "<C-w>-", {noremap: true}
map "n", "<C-Left>", "<C-w><", {noremap: true}
map "n", "<C-Right>", "<C-w>>", {noremap: true}

-- swap so that: 0 to go to first character, ^ to start of line, we want
-- the former more often
map "n", "0", "^", {noremap: true}
map "n", "^", "0", {noremap: true}

-- close quickfix window more easily
map "n", "<leader>qc", ":cclose<CR>", {silent: true}

-- Quickly turn off search highlights
map "n", "<leader>hs", ":nohls<CR>", {silent: true}

-- Backspace to swap to previous buffer
map "", "<BS>", "<C-^>", {noremap: true}
-- Shift-Backspace to delete line contents but leave the line itself
map "", "<S-BS>", "cc<ESC>", {noremap: true}

-- Open current file in external program
map "n", "<leader>o", ":exe ':silent !xdg-open % &'<CR>", {noremap: true}

-- Map C-j and C-k with the PUM visible to the arrows
map "i", "<C-j>", 'pumvisible() ? "\\<Down>" : "\\<C-j>"', {noremap: true, expr: true}
map "i", "<C-k>", 'pumvisible() ? "\\<Down>" : "\\<C-k>"', {noremap: true, expr: true}

-- For debugging syntax highlighters
syntax_debug_map = ':echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . \'> trans<\' . synIDattr(synID(line("."),col("."),0),"name") . "> lo<" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>'
map "", "<F10>", syntax_debug_map, {}
-- }}}

-- Status line setup {{{
export setup_status_line, status_line, is_active_statusline
is_active_statusline = -> g.statusline_winid == fn.win_getid!
setup_status_line = (widget_groups, highlights) ->
  -- TODO rethink this interface to allow same level of flexibility, but
  -- cleanly separate content and presentation?
  for i, widgets in ipairs widget_groups
    widgets = [{:widget, callable: is_callable widget} for widget in *widgets]
    widget_groups[i] = widgets
  highlights = [{:highlight, callable_highlight: is_callable highlight} for highlight in *highlights]
  assert #widget_groups == #highlights, "Number of widget groups does not match number of highlights, #{#widget_groups} vs #{#highlights}"
  highlight_cache = {}

  highlight_name = (idx) -> "StatusLineWidgetGroup#{idx}"
  generate_highlight = (idx, highlight) ->
    name = highlight_name idx
    base = "hi #{name} guifg=#{highlight.fg} guibg=#{highlight.bg}"
    if highlight.style
      base .. " gui=#{highlight.style}"
    else
      base

  status_line = ->
    output_line = ""
    for idx, widget_group in ipairs widget_groups
      -- for idx, {:widget, :callable} in ipairs widgets
      group_outputs = {}
      for {:widget, :callable} in *widget_group
        -- Create widget output
        output = if callable
          widget!
        else
          widget
        table.insert group_outputs, output

      -- Determine if highlight group needs to recreated from the highlight data
      {:highlight, :callable_highlight} = highlights[idx]
      highlight = if callable_highlight
        highlight group_outputs
      else
        highlight
      set_highlight = false
      if cached = highlight_cache[idx]
        for key, val in pairs highlight
          if cached[key] != val
            cached[key] = val
            set_highlight = true
      else
        highlight_cache[idx] = highlight
        set_highlight = true

      -- Write highlight group for highlight
      if set_highlight
        cmd (generate_highlight idx, highlight)

      -- Append highlight information & widget output to the output status line
      output_line ..= string.format "%%#%s#%s", (highlight_name idx), (table.concat group_outputs)

    output_line

  o.statusline = [[%!luaeval("status_line()")]]
  return

do
  mode_mapping =
    n: "NORMAL"
    niI: "NORMAL"
    niR: "NORMAL"
    niV: "NORMAL"
    no: "OP-PENDING"
    nov: "OP-PENDING"
    noV: "OP-PENDING"
    ['no']: "OP-PENDING"
    v: "VISUAL"
    V: "V-LINE"
    ['']: "V-BLOCK"
    s: "SELECT"
    S: "S-LINE"
    ['']: "S-BLOCK"
    i: "INSERT"
    ic: "INSERT"
    ix: "INSERT"
    R: "REPLACE"
    Rc: "REPLACE"
    Rv: "REPLACE"
    Rx: "REPLACE"
    c: "COMMAND"
    cv: "COMMAND"
    ce: "COMMAND"
    r: "ENTER"
    rm: "MORE"
    ['r?']: "CONFIRM"
    ['!']: "SHELL"
    t: "TERMINAL"

  get_mode_str = ->
    -- TODO: mode | PASTE?
    -- paste indicator separately?
    { :mode } = api.nvim_get_mode!
    if mode_str = mode_mapping[mode]
      mode_str
    else
      mode

  file_name = ->
    name = fn.expand '%:t'
    ext = fn.expand '%:e'
    icon = if nvim_web_devicons
      nvim_web_devicons.get_icon name, ext, { default: true }

    if icon
      string.format "%s %s", icon, name
    else
      name

  file_osinfo = ->
    os = string.lower bo.fileformat
    icon = switch os
      when "unix"
        icon = ''
      when "mac"
        icon = ''
      else
        icon = ''
    "#{icon} #{os}"

  file_percentage = ->
    (fn.round ((fn.line '.') / (fn.line '$') * 100)) .. '%%'

  file_encoding = ->
    if bo.fenc != ''
      bo.fenc
    else
      o.enc

  file_type = ->
    ft = bo.filetype
    if ft != ""
      ft
    else
      "none"

  paste_mode = ->
    if o.paste
      "[PASTE]"
    else
      ""

  active_only = (widget_group) ->
    for idx, widget in ipairs widget_group
      wrapped_widget = if is_callable widget
        () ->
          active = is_active_statusline!
          if active
            widget!
          else
            ""
      else
        () ->
          active = is_active_statusline!
          if active
            widget
          else
            ""
      widget_group[idx] = wrapped_widget
    widget_group

  widgets = {
    (active_only { ' ', get_mode_str, ' ' }),
    { ' ', file_name, ' ' }, -- Filename
    { paste_mode, '%r', '%m' }, -- Paste-mode, read-only & dirty buffer warnings
    { '%=' }, -- Left/right breaker
    (active_only { ' ', file_osinfo, ' | ', file_encoding, ' | ', file_type, ' ' }),
    { ' ', file_percentage, ' %l:%c ' }, -- Line & column information
  }

  setup_status_line widgets, statusline_highlights
-- }}}
