{ :api, :cmd, :fn, :g, :env, :o, :opt, :bo, :wo, :empty_dict, :is_callable } = vim
{ :stdpath } = fn
{ :dir_exists, :set } = nvim
map = api.nvim_set_keymap

-- Basic configuration {{{
-- Resize splits when the window is resized
vim.api.nvim_create_autocmd {"VimResized"}, { group: "vimrc", pattern: { "*" }, command: "exe \"normal! \\<c-w>=\"" }

-- TODO move all these option-sets into a loop over an array? bit nicer
-- to configure
-- Search
-- Ignore case when searching
o.ignorecase = true
-- ^ unless a capital letter is typed
o.smartcase = true

-- Hybrid relative line numbers
o.number = true
o.relativenumber = true

-- I have mode information as part of my status line, so don't need this
o.showmode = false

-- Indentation
-- Use 2-space autoindentation
o.shiftwidth = 2
o.softtabstop = 2
-- Together with ^, number of spaces a <Tab> counts for
o.tabstop = 2
-- Change <Tab> into spaces automatically in insert mode and with autoindent
o.expandtab = true
-- NOTE: Can insert a real <Tab> with CTRL-V<Tab> while in insert mode

-- wrap lines visually, at convenient places
o.linebreak = true

-- Display <Tab>s and trailing spaces visually
o.list = true
opt.listchars = { trail: "·", tab: "»·" }
-- Because file-based folds are awesome
o.foldmethod = "marker"
-- Keep 6 lines minimum above/below cursor when possible; gives context
o.scrolloff = 6
-- Similar, but for vertical space & columns
o.sidescrolloff = 10
-- Previous two only apply when `wrap` is off, something I occasionally need to do
-- Disable mouse cursor movement
o.mouse = "c"
-- Always keep the gutter open, constant expanding/contracting gets annoying fast
o.signcolumn = "yes"

-- Exclude temporary directories and remote/detachable mount points from shada
opt.shada\append { "r/tmp", "r/run", "r/mnt", "r/home/shados/technotheca/mnt" }
-- }}}

-- Advanced configuration {{{
-- Use ripgrep for search backend
-- vimgrep == needed for compatibility with ack.vim
-- no-heading == grouping by file isn't needed for this use-case
-- smart-case == case-insensitive search if all-lowercase pattern,
--               case-sensitive otherwise
g.ackprg = "#{rg_bin} --vimgrep --smart-case --no-heading --max-filesize=4M"
o.grepprg = "#{rg_bin} --vimgrep --smart-case --no-heading --max-filesize=4M"
opt.grepformat = { "%f:%l:%c:%m", "%f:%l:%m" }

-- When jumping from quickfix window to a location, use existing
-- matching open buffer if present
o.switchbuf = "useopen"

-- TODO: Delete old undofile automatically when vim starts
-- TODO: Delete old backup files automatically when vim starts
o.undofile = true
o.backupdir = "#{stdpath "data"}/backup"
o.backup = true
-- This one creates temporary backup files, as opposed to the permament
-- ones from 'backup', so disable it
o.writebackup = false
-- Otherwise, it may decide to do all writes by first moving the written
-- file to a temporary name, then writing out the modified files to the
-- original name, then moving the temporary file to the backupdir. This
-- approach generates way more filesystem events than necessary, and is
-- likely to trigger race conditions in e.g. compiler 'watch' modes that
-- use inotify.
o.backupcopy = "yes"

-- TODO: Make incremental search open all folds with matches while
-- searching, close the newly-opened ones when done (except the one the
-- selected match is in)

-- TODO: Configure makers for automake

-- File-patterns to ignore for wildcard matching on tab completion
opt.wildignore = { "*.o", "*.obj", "*~", "*.png", "*.jpg", "*.gif", "*.mp3", "*.ogg", "*.bin" }

-- Have nvim jump to the last position when reopening a file
vim.api.nvim_create_autocmd {"BufReadPost"}, {
  group: "vimrc",
  pattern: { "*" },
  command: 'if line("\'\\"") > 1 && line("\'\\"") <= line("$") | exe "normal! g\'\\"" | endif'
}
-- Exclude gitcommit type to avoid doing this in commit message editor
-- sessions
vim.api.nvim_create_autocmd {"FileType"}, { group: "vimrc", pattern: { "gitcommit" }, command: "normal! gg0" }

-- Default to opened folds in gitcommit filetype (having them closed by
-- default doesn't make sense in this context; only really comes up when
-- using e.g. `git commit -v` to get the commit changes displayed)
vim.api.nvim_create_autocmd {"FileType"}, { group: "vimrc", pattern: { "gitcommit" }, command: "normal zR" }

-- Track window- and buffer-local options in sessions
opt.sessionoptions\append { "localoptions" }

-- Enable spell-checking for some filetypes
-- Neovim's spell-checking is syntax-aware, meaning it doesn't attempt to
-- spell-check "code" parts of a file, but it *does* attempt to spell-check
-- string contents, which I often find unhelpful/distracting
o.spelllang = "en_au"
vim.api.nvim_create_autocmd {"FileType"}, {
  group: "vimrc",
  pattern: { "markdown", "text", "tex" },
  command: "setlocal spell"
}

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
export setup_status_line, status_line, status_widget_functions, is_active_statusline, prefix_fixer

status_widget_functions = {}
is_active_statusline = (statusline_winid) ->
  statusline_winid == fn.win_getid!

setup_status_line = (widget_groups, base_highlights, highlights) ->
  -- TODO rethink this interface to allow same level of flexibility, but
  -- cleanly separate content and presentation?
  for i, widgets in ipairs widget_groups
    widgets = [{:widget, callable: is_callable widget} for widget in *widgets]
    widget_groups[i] = widgets
  highlights = [{:highlight, callable_highlight: is_callable highlight} for highlight in *highlights]
  assert #widget_groups == #highlights, "Number of widget groups does not match number of highlights, #{#widget_groups} vs #{#highlights}"
  highlight_cache = {}

  highlight_name = (idx) -> "StatusLineWidgetGroup#{idx}"
  generate_highlight = (name, highlight) ->
    base = "hi #{name} guifg=#{highlight.fg} guibg=#{highlight.bg}"
    if highlight.style
      base .. " gui=#{highlight.style}"
    else
      base

  cmd (generate_highlight "StatusLine", base_highlights[1])
  cmd (generate_highlight "StatusLineNC", base_highlights[2])

  widget_group_strs = {}

  -- Hacky workaround for vim/vim#3898
  prefix_fixer = (fn_idx, statusline_winid) ->
    widget_str = status_widget_functions[fn_idx](statusline_winid)
    if (widget_str\sub 1, 1) == " "
      " " .. widget_str
    else
      widget_str

  for group_idx, widget_group in ipairs widget_groups
    widget_group_strs[group_idx] = {}
    for {:widget, :callable} in *widget_group
      -- Create widget output
      output = if callable
        fn_idx = #status_widget_functions + 1
        status_widget_functions[fn_idx] = widget
        "%%{luaeval('prefix_fixer(#{fn_idx}, %i)')}"
      else
        widget
      table.insert widget_group_strs[group_idx], {:callable, widget_str: output}

  status_line = ->
    statusline_winid = fn.win_getid!
    output_line = ""
    for idx, widget_strs in ipairs widget_group_strs
      -- Determine if highlight group needs to recreated from the highlight data
      {:highlight, :callable_highlight} = highlights[idx]
      highlight = if callable_highlight
        highlight statusline_winid
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
        hi_name = highlight_name idx
        cmd (generate_highlight hi_name, highlight)

      widget_group_str = ""
      for {:callable, :widget_str} in *widget_strs
        if callable
          widget_group_str ..= string.format widget_str, statusline_winid
        else
          widget_group_str ..= widget_str
      -- Append highlight information & widget output to the output status line
      output_line ..= string.format "%%#%s#%s", (highlight_name idx), widget_group_str

    output_line

  o.statusline = [[%!luaeval("status_line()")]]
  return

sl = {}
do
  sl.mode_mapping =
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

  sl.get_mode_str = ->
    -- TODO: mode | PASTE?
    -- paste indicator separately?
    { :mode } = api.nvim_get_mode!
    if mode_str = sl.mode_mapping[mode]
      mode_str
    else
      mode

  sl.file_name = ->
    name = fn.expand '%:t'
    ext = fn.expand '%:e'
    if nvim_web_devicons
      icon = nvim_web_devicons.get_icon name, ext, { default: true }
      string.format "%s %s", icon, name
    else
      name

  sl.file_osinfo = ->
    os = string.lower bo.fileformat
    icon = switch os
      when "unix"
        icon = ''
      when "mac"
        icon = ''
      else
        icon = ''
    "#{icon} #{os}"

  sl.file_percentage = ->
    (fn.round ((fn.line '.') / (fn.line '$') * 100)) .. '%%'

  sl.file_encoding = ->
    if bo.fenc != ''
      bo.fenc
    else
      o.enc

  sl.file_type = ->
    ft = bo.filetype
    if ft != ""
      ft
    else
      "none"

  sl.paste_mode = ->
    if o.paste
      "[PASTE]"
    else
      ""

  active_only = (widget_group) ->
    for idx, widget in ipairs widget_group
      wrapped_widget = if is_callable widget
        (statusline_winid) ->
          active = is_active_statusline statusline_winid
          if active
            widget statusline_winid
          else
            ""
      else
        (statusline_winid) ->
          active = is_active_statusline statusline_winid
          if active
            widget
          else
            ""
      widget_group[idx] = wrapped_widget
    widget_group

  widgets = {
    (active_only { ' ', sl.get_mode_str, ' ' }),
    { ' ', sl.file_name, ' ' }, -- Filename
    { sl.paste_mode, '%r', '%m' }, -- Paste-mode, read-only & dirty buffer warnings
    { '%=' }, -- Left/right breaker
    (active_only { ' ', sl.file_osinfo, ' | ', sl.file_encoding, ' | ', sl.file_type, ' ' }),
    { ' ', sl.file_percentage, ' %l:%c ' }, -- Line & column information
  }

  setup_status_line widgets, statusline_base_highlights, statusline_highlights
-- }}}
