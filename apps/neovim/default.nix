{ config, lib, pkgs, ... }:
with lib;
let
  nvimCfg = config.sn.programs.neovim;
  plugCfg = nvimCfg.pluginRegistry;
in
{
  imports = [
    # Theme-related defaults
    ./gruvbox.nix
    ./oceanicnext.nix
  ];

  sn.programs.neovim = let
    rgPkg = pkgs.ripgrep;
    rg = "${rgPkg}/bin/rg";
  in {
    mergePlugins = mkDefault true;
    files = {
      "ftplugin/python.vim".source = ./nvim-files/ftplugin/python.vim;
      neosnippets.source = ./nvim-files/neosnippets;
    };
    sourcePins = nvimCfg.lib.fillPinsFromDir {
      priority = 1000;
      directoryPath = ./pins;
    };
    extraBinPackages = [
      rgPkg
    ];
    configLanguage = "moonscript";
    prePluginConfig = ''
      -- Early-load settings

      -- Helpers
      -- FIXME Replace by dependence on a library of my own making, or 0.5
      -- compatibility shim
      dir_exists = (dir) ->
        (vim.api.nvim_call_function 'isdirectory', {dir}) != 0
      empty_dict = ->
        { [vim.type_idx]: vim.types.dictionary }
      stdpath = (path_type) ->
        vim.api.nvim_call_function "stdpath", {path_type}
      env_home = os.getenv("HOME")

      -- FIXME Once there's a nice way to create expr-quote values from Lua
      space = vim.api.nvim_eval '"\\<Space>"'
      vim.api.nvim_set_var "mapleader", space

      -- Define my autocmd group for later use
      -- FIXME Once there's a way to use augroup directly from Lua or the API
      vim.api.nvim_command "augroup vimrc | autocmd! | augroup END"

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
        vim.api.nvim_set_option "termguicolors", true
    '';
    extraConfig = optionalString plugCfg.ale.enable ''
      vim.api.nvim_set_var "ale_linters", ale_linters
      vim.api.nvim_set_var "ale_fixers", ale_fixers
    '' + ''
      -- Basic configuration {{{
      -- Resize splits when the window is resized
      vim.api.nvim_command 'autocmd vimrc VimResized * exe "normal! \\<c-w>="'

      -- TODO move all these option-sets into a loop over an array? bit nicer
      -- to configure
      -- Search
      -- Incremental searching
      vim.api.nvim_set_option "incsearch", true
      -- Highlight matches by default
      vim.api.nvim_set_option "hlsearch", true
      -- Ignore case when searching
      vim.api.nvim_set_option "ignorecase", true
      -- ^ unless a capital letter is typed
      vim.api.nvim_set_option "smartcase", true

      -- Hybrid relative line numbers
      vim.api.nvim_win_set_option 0, "number", true
      vim.api.nvim_win_set_option 0, "relativenumber", true

      -- Indentation
      -- Copy indent to new line
      vim.api.nvim_buf_set_option 0, "autoindent", true
      -- Use 2-space autoindentation
      vim.api.nvim_buf_set_option 0, "shiftwidth", 2
      vim.api.nvim_buf_set_option 0, "softtabstop", 2
      -- Together with ^, number of spaces a <Tab> counts for
      vim.api.nvim_buf_set_option 0, "tabstop", 2
      -- Change <Tab> into spaces automatically in insert mode and with autoindent
      vim.api.nvim_buf_set_option 0, "expandtab", true
      -- NOTE: Can insert a real <Tab> with CTRL-V<Tab> while in insert mode

      -- Allow backspace in insert mode
      vim.api.nvim_set_option "backspace", "indent,eol,start"
      vim.api.nvim_set_option "history", 1000
      -- Buffers are not unloaded when 'abandoned' by editing a new file, only when actively quit
      vim.api.nvim_set_option "hidden", true

      -- Wrap lines...
      vim.api.nvim_win_set_option 0, "wrap", true
      -- ...visually, at convenient places
      vim.api.nvim_win_set_option 0, "linebreak", true

      -- Display <Tab>s and trailing spaces visually
      vim.api.nvim_win_set_option 0, "list", true
      vim.api.nvim_set_option "listchars", "trail:·,tab:»·"
      -- Because file-based folds are awesome
      vim.api.nvim_win_set_option 0, "foldmethod", "marker"
      -- Keep 6 lines minimum above/below cursor when possible; gives context
      vim.api.nvim_set_option "scrolloff", 6
      -- Similar, but for vertical space & columns
      vim.api.nvim_set_option "sidescrolloff", 10
      -- Minimum number of columns to scroll horiznotall when moving cursor off screen
      vim.api.nvim_set_option "sidescroll", 1
      -- Previous two only apply when `wrap` is off, something I occasionally need to do
      -- Disable mouse cursor movement
      vim.api.nvim_set_option "mouse", "c"
      -- Support modelines in files
      vim.api.nvim_buf_set_option 0, "modeline", true
      -- Always keep the gutter open, constant expanding/contracting gets annoying fast
      vim.api.nvim_win_set_option 0, "signcolumn", "yes"

      -- Set netrwhist home location to prevent .netrwhist being made in
      -- .config/nvim/ -- it is data not config
      vim.api.nvim_set_var "netrw_home", (stdpath "data")
      -- }}}

      -- Advanced configuration {{{
      -- Use ripgrep for search backend
      -- vimgrep == needed for compatibility with ack.vim
      -- no-heading == grouping by file isn't needed for this use-case
      -- smart-case == case-insensitive search if all-lowercase pattern,
      --               case-sensitive otherwise
      vim.api.nvim_set_var "ackprg", '${rg} --vimgrep --smart-case --no-heading --max-filesize=4M'
      vim.api.nvim_set_option "grepprg", "${rg} --vimgrep --smart-case --no-heading --max-filesize=4M"
      vim.api.nvim_set_option "grepformat", "%f:%l:%c:%m,%f:%l:%m"

      -- When jumping from quickfix window to a location, use existing
      -- matching open buffer if present
      vim.api.nvim_set_option "switchbuf", "useopen"

      -- TODO: Delete old undofile automatically when vim starts
      -- TODO: Delete old backup files automatically when vim starts
      -- Both are under ~/.local/share/nvim/{undo,backup} in neovim by default
      -- Keep undo history across sessions by storing it in a file
      undodir = "#{env_home}/.local/share/nvim/undo/"
      vim.api.nvim_set_option "undodir", undodir
      unless dir_exists undodir
        vim.api.nvim_call_function "mkdir", {undodir, "p"}

      backupdir = "#{env_home}/.local/share/nvim/backup/"
      vim.api.nvim_set_option "backupdir", backupdir
      unless dir_exists backupdir
        -- TODO this doesn't work for backupdir, figure out why
        vim.api.nvim_call_function "mkdir", {backupdir, "p"}
      vim.api.nvim_buf_set_option 0, "undofile", true
      vim.api.nvim_set_option "backup", true
      -- This one creates temporary backup files, as opposed to the permanent
      -- ones from 'backup', so disable it
      vim.api.nvim_set_option "writebackup", false
      -- Otherwise, it may decide to do all writes by first moving the written
      -- file to a temporary name, then writing out the modified files to the
      -- original name, then moving the temporary file to the backupdir. This
      -- approach generates way more filesystem events than necessary, and is
      -- likely to trigger race conditions in e.g. compiler 'watch' modes that
      -- use inotify.
      vim.api.nvim_set_option "backupcopy", "yes"

      -- TODO: Make incremental search open all folds with matches while
      -- searching, close the newly-opened ones when done (except the one the
      -- selected match is in)

      -- TODO: Configure makers for automake

      -- File-patterns to ignore for wildcard matching on tab completion
      vim.api.nvim_set_option "wildignore", "*.o,*.obj,*~,*.png,*.jpg,*.gif,*.mp3,*.ogg,*.bin"

      -- Have nvim jump to the last position when reopening a file
      vim.api.nvim_command 'autocmd vimrc BufReadPost * if line("\'\\"") > 1 && line("\'\\"") <= line("$") | exe "normal! g\'\\"" | endif'
      -- Exclude gitcommit type to avoid doing this in commit message editor
      -- sessions
      vim.api.nvim_command 'autocmd vimrc FileType gitcommit normal! gg0'

      -- Default to opened folds in gitcommit filetype (having them closed by
      -- default doesn't make sense in this context; only really comes up when
      -- using e.g. `git commit -v` to get the commit changes displayed)
      vim.api.nvim_command 'autocmd vimrc FileType gitcommit normal zR'

      -- Track window- and buffer-local options in sessions
      -- FIXME replace once we have Lua equivalent to set+=
      sessionoptions = vim.api.nvim_get_option "sessionoptions"
      vim.api.nvim_set_option "sessionoptions", "#{sessionoptions},localoptions"

      -- TODO when working on code inside a per-project virtualenv or nix.shell,
      -- automatically detect and use the python from the project env
      -- }}}

      -- Key binds/mappings {{{
      -- Fuck hitting shift
      vim.api.nvim_set_keymap "", ";", ":", {}
      -- Just in case we actually need ;, double-tap it
      vim.api.nvim_set_keymap "", ";;", ";", {noremap: true}
      -- We leave the : mapping in place to avoid mishaps with typing
      -- :Uppercasecommands

      -- Easier window splits, C-w,v to vv, C-w,s to ss
      vim.api.nvim_set_keymap "n", "vv", "<C-w>v", {noremap: true, silent: true}
      vim.api.nvim_set_keymap "n", "ss", "<C-w>s", {noremap: true, silent: true}

      -- Quicker split navigation with <leader>-h/l/j/k
      vim.api.nvim_set_keymap "n", "<leader>h", "<C-w>h", {noremap: true, silent: true}
      vim.api.nvim_set_keymap "n", "<leader>l", "<C-w>l", {noremap: true, silent: true}
      vim.api.nvim_set_keymap "n", "<leader>k", "<C-w>k", {noremap: true, silent: true}
      vim.api.nvim_set_keymap "n", "<leader>j", "<C-w>j", {noremap: true, silent: true}

      -- Quicker split resizing with Ctrl-<Arrow Key>
      vim.api.nvim_set_keymap "n", "<C-Up>", "<C-w>+", {noremap: true}
      vim.api.nvim_set_keymap "n", "<C-Down>", "<C-w>-", {noremap: true}
      vim.api.nvim_set_keymap "n", "<C-Left>", "<C-w><", {noremap: true}
      vim.api.nvim_set_keymap "n", "<C-Right>", "<C-w>>", {noremap: true}

      -- swap so that: 0 to go to first character, ^ to start of line, we want
      -- the former more often
      vim.api.nvim_set_keymap "n", "0", "^", {noremap: true}
      vim.api.nvim_set_keymap "n", "^", "0", {noremap: true}

      -- close quickfix window more easily
      vim.api.nvim_set_keymap "n", "<leader>qc", ":cclose<CR>", {silent: true}

      -- Quickly turn off search highlights
      vim.api.nvim_set_keymap "n", "<leader>qc", ":cclose<CR>", {silent: true}

      -- Backspace to swap to previous buffer
      vim.api.nvim_set_keymap "", "<BS>", "<C-^>", {noremap: true}
      -- Shift-Backspace to delete line contents but leave the line itself
      vim.api.nvim_set_keymap "", "<S-BS>", "cc<ESC>", {noremap: true}

      -- Open current file in external program
      vim.api.nvim_set_keymap "n", "<leader>o", ":exe ':silent !xdg-open % &'<CR>", {noremap: true}

      -- Map C-j and C-k with the PUM visible to the arrows
      vim.api.nvim_set_keymap "i", "<C-j>", 'pumvisible() ? "\\<Down>" : "\\<C-j>"', {noremap: true, expr: true}
      vim.api.nvim_set_keymap "i", "<C-k>", 'pumvisible() ? "\\<Down>" : "\\<C-k>"', {noremap: true, expr: true}

      -- For debugging syntax highlighters
      syntax_debug_map = ':echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . \'> trans<\' . synIDattr(synID(line("."),col("."),0),"name") . "> lo<" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>'
      vim.api.nvim_set_keymap "", "<F10>", syntax_debug_map, {}
      -- }}}
    '';
    pluginRegistry = {
      # Appearance & UI {{{
      oceanic-next.enable = true;
      gruvbox.enable = false;
      # Visually colorise CSS-compatible # colour code strings
      vim-css-color.enable = true;
      lightline-vim = {
        enable = true;
        extraConfig = ''
          -- lightline {{{
          vim.api.nvim_set_var "lightline", {
            active: {
              left: {
                {"mode", "paste"},
                {"fugitive", "filename"},
              },
              component_function: {
                fugitive: "LLFugitive"
                readonly: "LLReadonly"
                modified: "LLModified"
                filename: "LLFilename"
                mode: "LLMode"
              }
            }
          }
          -- FIXME Replace once we have a nice way to define vim-callable functions from Lua (0.5 has v:lua)
          vim.api.nvim_command [[
            function! LLMode()
              let fname = expand('%:t')
              return fname ==# '__Tagbar__' ? 'Tagbar' :
                    \ fname ==# 'ControlP' ? 'CtrlP' :
                    \ lightline#mode() ==# 'NORMAL' ? 'N' :
                    \ lightline#mode() ==# 'INSERT' ? 'I' :
                    \ lightline#mode() ==# 'VISUAL' ? 'V' :
                    \ lightline#mode() ==# 'V-LINE' ? 'V' :
                    \ lightline#mode() ==# 'V-BLOCK' ? 'V' :
                    \ lightline#mode() ==# 'REPLACE' ? 'R' : lightline#mode()
            endfunction
            function! LLModified()
              if &filetype ==# 'help'
                return '''
              elseif &modified
                return '+'
              elseif &modifiable
                return '''
              else
                return '''
              endif
            endfunction
            function! LLReadonly()
              if &filetype ==# 'help'
                return '''
              elseif &readonly
                return '!'
              else
                return '''
              endif
            endfunction
            function! LLFugitive()
              return exists('*fugitive#head') ? fugitive#head() : '''
            endfunction
            function! LLFilename()
              return (''' !=# LLReadonly() ? LLReadonly() . ' ' : ''') .
                    \ (''' !=# expand('%:t') ? expand('%:t') : '[No Name]') .
                    \ (''' !=# LLModified() ? ' ' . LLModified() : ''')
            endfunction
          ]]
          -- }}}
        '';
        after = [ "gruvbox" "oceanic-next" ];
      };
      vim-devicons = {
        # TODO add font dep and config?
        enable = true;
        # vim-devicons needs to be loaded after these plugins, if they
        # are being used, as per its installation guide
        after = [
          "nerdtree" "vim-airline" "ctrlp-vim" "powerline/powerline"
          "denite-nvim" "unite-vim" "lightline-vim" "vim-startify"
          "vimfiler" "vim-flagship"
        ];
      };

      # Incremental highlight on incsearch, including of partial regex matches
      incsearch-vim = {
        enable = true;
        extraConfig = ''
          -- Replace normal search with incsearch.vim
          vim.api.nvim_set_keymap "", "/", "<Plug>(incsearch-forward)", {}
          vim.api.nvim_set_keymap "", "?", "<Plug>(incsearch-backward)", {}
          vim.api.nvim_set_keymap "", "g/", "<Plug>(incsearch-stay)", {}
        '';
      };
      # Visual display of indent levels
      "Yggdroot/indentLine" = {
        enable = true;
        extraConfig = ''
          vim.api.nvim_set_var "indentLine_char", '▏'
        '';
      };
      # Displays function signatures from completions in the command line
      "Shougo/echodoc.vim" = {
        enable = false;
        extraConfig = ''
          -- So the current mode indicator in the command line does not overwrite the
          -- function signature display
          vim.api.nvim_set_option "showmode", false
        '';
      };
      # }}}

      # Language support and syntax highlighting {{{
      # Async linting
      ale = with pkgs; mkMerge [
        # ALE config {{{
        { enable = true;
          # TODO cleanup, should only have baseline config in here
          extraConfig = ''
            -- Move forward/backward between flagged warnings & errors
            vim.api.nvim_set_keymap "n", "<leader>]", "<Plug>(ale_next_wrap)", {silent: true}
            vim.api.nvim_set_keymap "n", "<leader>[", "<Plug>(ale_previous_wrap)", {silent: true}

            -- TODO: use devicons for error/warning signs?
            -- TODO: auto-open any lines in folds with linter errors in them, or at
            -- least do so on changing to their location-list position to them...

            -- Clear the warning buffer immediately on any change (to prevent
            -- highlights on the edited line from falling out of sync and throwing me
            -- off)
            vim.api.nvim_command 'autocmd vimrc TextChanged,TextChangedI * ALEResetBuffer'

            -- To still make it easy to know if there is *something* in the gutter *somewhere*
            vim.api.nvim_set_var "ale_change_sign_column_color", 1

            -- Enable completion where LSP servers are available
            vim.api.nvim_set_var "ale_completion_enabled", 1

            -- Per-language, non-LSP config after here
            register_ale_tool = (dict, lang, tool, linter_name) ->
              linter_name = tool unless linter_name
              -- Previously used the 'tool' argument to do executable()
              -- checks, but we're statically providing the executables with
              -- Nix now, so this is unnecessary -- now it is just
              -- documentation :)
              unless dict[lang]
                dict[lang] = {}
              table.insert dict[lang], linter_name
              return

            -- By default, all available tools for all supported languages will be run
            -- ...but explicit is better than implicit, especially given we
            -- generate the set of available tools using Nix :)
            ale_fixers = {}
            ale_linters = {}
          '';
        }
        { extraConfig = mkAfter ''
            -- Bash
            register_ale_tool(ale_linters, "sh", "shell")
            register_ale_tool(ale_linters, "sh", "shellcheck")
            register_ale_tool(ale_fixers, "sh", "shfmt")
            vim.api.nvim_command 'autocmd vimrc FileType sh let b:ale_fix_on_save = 1'
          '';
          binDeps = [
            bash
            shellcheck
            shfmt
          ];
        }
        { extraConfig = mkAfter ''
            -- JSON
            register_ale_tool(ale_fixers, "json", "prettier")
            vim.api.nvim_command 'autocmd vimrc FileType json let b:ale_fix_on_save = 1'
          '';
          binDeps = [
            pkgs.nodePackages.prettier
          ];
        }
        { extraConfig = mkAfter ''
            -- Nix
            register_ale_tool(ale_linters, "nix", "nix-instantiate", "nix")
          '';
        }
        { extraConfig = mkAfter ''
            -- VimL/vimscript
            register_ale_tool(ale_linters, "vim", "vint")
          '';
          binDeps = [
            vim-vint
          ];
        }
        { extraConfig = mkAfter ''
            -- YAML
            register_ale_tool(ale_linters, "yaml", "yamllint")
          '';
          binDeps = with python3Packages; [
            (yamllint.overridePythonAttrs(oa: {
              doCheck = false;
            }))
          ];
        }
        # }}}
      ];
      "ericpruitt/tmux.vim".enable = true;
      vim-markdown = {
        enable = true;
        extraConfig = ''
          -- Open all folds by default
          vim.api.nvim_command 'autocmd vimrc FileType markdown normal zR'
          -- Set indent/tab for markdown files to 4 spaces
          vim.api.nvim_command 'autocmd vimrc FileType markdown setlocal shiftwidth=4 softtabstop=4 tabstop=4'

          vim.api.nvim_set_var "vim_markdown_toc_autofit", 1

          -- Explicitly disable conceal usage
          vim.api.nvim_set_var "vim_markdown_conceal", 0
          vim.api.nvim_set_var "vim_markdown_conceal_code_blocks", 0
          vim.api.nvim_set_var "tex_conceal", ""

          -- Extensions
          vim.api.nvim_set_var "vim_markdown_strikethrough", 1
          vim.api.nvim_set_var "vim_markdown_frontmatter", 1
          ${optionalString plugCfg.vim-toml.enable ''vim.api.nvim_set_var "vim_markdown_toml_frontmatter", 1''}
          ${optionalString plugCfg.vim-json.enable ''vim.api.nvim_set_var "vim_markdown_json_frontmatter", 1''}
        '';
      };
      # Nix syntax highlighting, error checking/linting is handled by ALE
      vim-nix.enable = true;
      "Matt-Deacalion/vim-systemd-syntax".enable = true;
      # Notably, let's you fold on json dict/lists
      vim-json = {
        enable = true;
        extraConfig = ''
          -- vim-json
          -- Set foldmethod to syntax so we can fold json dicts and lists
          vim.api.nvim_command 'autocmd vimrc FileType json setlocal foldmethod=syntax'
          -- Then automatically unfold all so we don't start at 100% folded :)
          vim.api.nvim_command 'autocmd vimrc FileType json normal zR'
          -- Don't conceal quote marks, that's fucking horrific. Who the hell would
          -- choose to default to that behaviour? Do they only ever read json, never
          -- write it?! Hell, even then it's still problematic!
          vim.api.nvim_set_var "vim_json_syntax_conceal", 0
        '';
      };
      "gutenye/json5.vim".enable = true;
      vim-toml.enable = true;
      vim-fish = {
        enable = true;
        for = "fish";
      };
      "nginx.vim" = {
        enable = true;
        source = ./nvim-files/local/nginx;
      };
      # }}}

      # Text/code creation & refactoring {{{
      # Code snippets, the mighty slayer of boilerplate
      neosnippet-vim = {
        enable = true;
        extraConfig = ''
          -- Use actual tabstops in snippet files
          vim.api.nvim_command 'autocmd vimrc FileType neosnippet setlocal noexpandtab'

          -- Mappings
          vim.api.nvim_set_keymap "i", "<C-k>", "<Plug>(neosnippet_expand_or_jump)", {}
          vim.api.nvim_set_keymap "s", "<C-k>", "<Plug>(neosnippet_expand_or_jump)", {}
          vim.api.nvim_set_keymap "x", "<C-k>", "<Plug>(neosnippet_expand_target)", {}
        '';
      };
      neosnippet-snippets = {
        enable = true;
        dependencies = [ "neosnippet-vim" ];
      };
      # Automatic closing of control flow blocks for most languages, eg. `end`
      # inserted after `if` in Ruby
      "tpope/vim-endwise".enable = true;
      # Automatic context-sensitive closing of quotes, parenthesis, brackets, etc.
      # and related features
      "Raimondi/delimitMate".enable = true;
      # Flexible word-variant tooling; mostly useful to me for 'coercing' between
      # different variable-naming styles (e.g. snake_case to camelCase via `crc`)
      vim-abolish.enable = true;
      "Shados/precog.nvim" = {
        enable = true;
        dependencies = [ "Shados/facade.nvim" "Shados/earthshine" ];
        luaDeps = ps: with ps; [
          luafilesystem
        ];
        extraConfig = ''
          shortmess = vim.api.nvim_get_option "shortmess"
          vim.api.nvim_set_option "shortmess", "#{shortmess}c"
          -- Open preview/details window
          completeopt = vim.api.nvim_get_option "completeopt"
          vim.api.nvim_set_option "completeopt", "#{completeopt},preview"
        '';
      };
      # Completion sources
      # TODO
      # }}}

      # Project management {{{
      # Statusline with buffers and tabs listed very cleanly
      vim-buffet = {
        source = "bagrat/vim-buffet";
        enable = true;
        dependencies = [
          "lightline-vim"
        ];
        commit = "044f2954a5e49aea8625973de68dda8750f1c42d";
        extraConfig = ''
          -- TODO better way of doing this in Lua
          lightline = vim.api.nvim_eval "get(g:, 'lightline', {})"
          --  Disable lightline's tabline functionality, as it conflicts with this
          unless lightline.enable
            lightline.enable = {}
          lightline.enable.tabline = 0
          vim.api.nvim_set_var "lightline", lightline

          -- Prettify
          vim.api.nvim_set_var "workspace_powerline_separators", 1
          vim.api.nvim_set_var "workspace_tab_icon", ""
          vim.api.nvim_set_var "workspace_left_trunc_icon", ""
          vim.api.nvim_set_var "workspace_right_trunc_icon", ""
        '';
      };
      nerdtree = {
        enable = true;
        on_cmd = [ "NERDTreeToggle" "NERDTreeFind" ];
        extraConfig = ''
          -- Prettify NERDTree
          vim.api.nvim_set_var "NERDTreeMinimalUI", 1
          vim.api.nvim_set_var "NERDTreeDirArrows", 1

          -- Open project file explorer in pane
          vim.api.nvim_set_keymap "n", "<leader>p", ":NERDTreeToggle<CR>", {}
          -- Open the project tree and expose current file in the tree with Ctrl-\
          vim.api.nvim_set_keymap "n", "<C-\\>", ":NERDTreeFind<CR>", {noremap: true, silent: true}

          -- Disable the scrollbars
          -- FIXME once we have Lua equivalent to set-=
          vim.api.nvim_command 'set guioptions-=r'
          vim.api.nvim_command 'set guioptions-=L'
        '';
      };
      # Full path fuzzy file/buffer/mru/tag/.../arbitrary list search, bound to
      # <leader>f (for find?)
      denite-nvim = {
        enable = true;
        remote.python3 = true;
        extraConfig = ''
          -- Sane ignore for file tree matching, this ignores vcs files, binaries,
          -- temporary files, etc.
          vim.api.nvim_call_function "denite#custom#filter", { "matcher_ignore_globs", "ignore_globs",
            {'.git/', '.hg/', '.svn/', '.yardoc/', 'public/mages/',
            'public/system/', 'log/', 'tmp/', '__pycache__/', 'venv/',
            '*.min.*', '*.pyc', '*.exe', '*.so', '*.dat', '*.bin', '*.o'}
          }
          -- Use ripgrep for denite file search backend
          vim.api.nvim_call_function "denite#custom#var", { "file/rec", "command",
            {"${rg}", "--files", "--color", "never"}
          }
          vim.api.nvim_call_function "denite#custom#var", { "grep", {
            command: {"${rg}"}
            default_opts: {"--vimgrep", "--smart-case", "--no-heading", "--max-filesize=4M"}
            recursive_opts: {}
            pattern_opt: {"--regexp"}
            separator: {"--"}
            final_opts: {}
          }}
          -- Change the default sorter for the sources I care about
          vim.api.nvim_call_function "denite#custom#source", { "file/rec", "sorters", {"sorter_sublime"} }
          -- vim.api.nvim_call_function "denite#custom#source", { "file/mru", "sorters", {"sorter_sublime"} }
          vim.api.nvim_call_function "denite#custom#source", { "buffer", "sorters", {"sorter_sublime"} }

          -- Searches through current buffers and recursive file/dir tree
          vim.api.nvim_set_keymap "n", "<leader>f", ":<C-u>Denite buffer file/rec -split=floating -winrow=1<cr>", {noremap: true}
          vim.api.nvim_set_keymap "n", "<leader>b", ':<C-u>Denite buffer -quick-move="immediately" -split=floating -winrow=1<cr>', {noremap: true}

          -- Default to filtering the resultant buffer
          vim.api.nvim_call_function "denite#custom#option", { "_", {start_filter: 1} }

          -- Define default mappings for the denite buffers
          -- FIXME once we have a more native Lua way to do this
          vim.api.nvim_command [[
            function! g:DeniteBinds() abort
              nnoremap <silent><buffer><expr> <CR> denite#do_map('do_action')
              nnoremap <silent><buffer><expr> d denite#do_map('do_action', 'delete')
              nnoremap <silent><buffer><expr> p denite#do_map('do_action', 'preview')
              nnoremap <silent><buffer><expr> <Esc> denite#do_map('quit')
              nnoremap <silent><buffer><expr> i denite#do_map('open_filter_buffer')
              nnoremap <silent><buffer><expr> <Space> denite#do_map('toggle_select').'j'
            endfunction
            function! g:DeniteFilterBinds() abort
              inoremap <silent><buffer><expr> <CR> denite#do_map('do_action')
              inoremap <silent><buffer><expr> <Esc> denite#do_map('quit')
              inoremap <silent><buffer> <C-j> <Esc><C-w>p:call cursor(line('.')+1,0)<CR><C-w>pA
              inoremap <silent><buffer> <C-k> <Esc><C-w>p:call cursor(line('.')-1,0)<CR><C-w>pA
            endfunction
            autocmd FileType denite call g:DeniteBinds()
            autocmd FileType denite-filter call g:DeniteFilterBinds()
          ]]
        '';
      };
      # Display FIXME/TODO/etc. in handy browseable list pane, bound to <Leader>t,
      # then q to cancel, e to quit browsing but leave tasklist up, <CR> to quit
      # and place cursor on selected task
      "vim-scripts/TaskList.vim".enable = true;
      # Extended session management, auto-save/load
      "Shados/vim-session" = {
        enable = true;
        dependencies = [ "xolox/vim-misc" ];
        branch = "shados-local";
        extraConfig = let
        in ''
          vim.api.nvim_set_var "session_autoload", "no"
          vim.api.nvim_set_var "session_autosave", "prompt"
          vim.api.nvim_set_var "session_autosave_only_with_explicit_session", 1
          -- Session-prefixed command aliases, e.g. OpenSession -> SessionOpen
          vim.api.nvim_set_var "session_command_aliases", 1
          session_dir = "#{stdpath "data"}/sessions"
          session_lock_dir = "#{stdpath "data"}/session-locks"
          vim.api.nvim_set_var "session_directory", session_dir
          vim.api.nvim_set_var "session_lock_directory", session_lock_dir
          -- Ensure session dirs exist
          vim.api.nvim_call_function "mkdir", {session_dir, "p"}
          vim.api.nvim_call_function "mkdir", {session_lock_dir, "p"}
        '';
      };
      # Builds and displays a list of tags (functions, variables, etc.) for the
      # current file, in a sidebar
      tagbar = {
        enable = true;
        on_cmd = "TagbarToggle";
        extraConfig = ''
          --- Default tag sorting by order of appearance within file (still grouped by
          -- scope)
          vim.api.nvim_set_var "tagbar_sort", 0
          -- Keep all tagbar folds closed initially; better for a top-level overview
          vim.api.nvim_set_var "tagbar_foldlevel", 0
          -- Move cursor to the tagbar window when it is opened
          vim.api.nvim_set_var "tagbar_autofocus", 1

          vim.api.nvim_set_keymap "n", "<leader>m", ":TagbarToggle<CR>", {}
        '';
      };
      # }}}

      # Textobjects {{{
      # Upgrades many of vim's inbuilt textobjects and adds some very useful new
      # ones, like a, and i, for working with comma-separated lists
      targets-vim.enable = true;
      # al for indent + start/close lines, ai for indent + start line, ii for
      # inside-indent
      vim-indent-object.enable = true;
      # code-column textobject, adds ic, ac, iC and aC for working with columns,
      # a/inner column based on word/WORD
      "coderifous/textobj-word-column.vim".enable = true;
      # a_ and i_ for editing the middle of lines like foo_bar_baz, a_ includes the
      # _'s
      "lucapette/vim-textobj-underscore" = {
        enable = true;
        dependencies = [ "kana/vim-textobj-user" ];
      };
      argtextobj-vim.enable = true;
      # TODO: function-based textobject
      # }}}

      # General extra functionality {{{
      vim-easymotion = {
        enable = true;
        extraConfig = ''
          -- s{char}{char} to easymotion-highlight all matching two-character sequences in sight
          vim.api.nvim_set_keymap "n", "s", "<Plug>(easymotion-overwin-f2)", {}
        '';
      };
      # Allows for splitting/joining code into/from multi-line formats, gS and gJ
      # bydefault
      "AndrewRadev/splitjoin.vim".enable = true;
      # SublimeText-style multiple cursor impl., ctrl-n to start matching on
      # current word to place
      vim-multiple-cursors.enable = true;
      # Toggle commenting of lines with gc{motion}, also works in visual mode
      vim-commentary.enable = true;
      # Allows you to visualize your undo tree in a pane opened with :GundoToggle
      gundo-vim = {
        enable = true;
        on_cmd = "GundoToggle";
        remote.python3 = true;
        # Theoretically works with python 2 or 3; in practice it has a fixed
        # check for python2 support unless you specify this pref.
        # https://github.com/sjl/gundo.vim/pull/36 &&
        # https://github.com/sjl/gundo.vim/pull/35
        extraConfig = ''
          vim.api.nvim_set_var "gundo_prefer_python3", 1
          -- Visualize undo tree in pane
          vim.api.nvim_set_keymap "n", "<leader>u", ":GundoToggle<CR>", {noremap: true}
          vim.api.nvim_set_var "gundo_right", 1 -- Opposite nerdtree's pane
        '';
      };
      # Allows doing `vim filename:lineno`
      "bogado/file-line".enable = true;
      # ,w ,b and ,e alternate motions that support traversing CamelCase and
      # underscore_notation
      "vim-scripts/camelcasemotion".enable = true;
      # Primarily useful for surrounding existing lines in new delimiters,
      # quotation marks, xml tags, etc., or removing or modifying said
      # 'surroundings'. <operation>s<surrounding-type> is most-used
      vim-surround.enable = true;
      # Plugin-hookable `.`-replacement, user-transparent
      vim-repeat.enable = true;
      # Lets you do `:SudoWrite`/`:SudoRead`, and also launch vim with `nvim
      # sudo:/etc/fstab`, all of which are nicer+shorter than directly using the
      # tee trick; TODO has some issues
      "chrisbra/SudoEdit.vim".enable = true;
      # Reverse search ex command history ala Bash ctrl-r
      "goldfeld/ctrlr.vim".enable = true;
      # A fancy start screen for vim (mainly for bookmarks and session listing)
      vim-startify = {
        enable = true;
        after = [ "Shados/vim-session" ];
        extraConfig = optionalString (plugCfg."Shados/vim-session".enable) ''
          vim.api.nvim_set_var "startify_session_dir", (vim.api.nvim_get_var "session_directory")
        '' + ''
          vim.api.nvim_set_var "startify_list_order", {
            {'  Bookmarks'}, 'bookmarks',
            {'  Sessions'}, 'sessions',
            {'  Commands'}, 'commands',
            {'  MRU Current Tree Files by Modification Time'}, 'dir',
          }
          vim.api.nvim_set_var "startify_bookmarks", {
            -- FIXME stdpath?
            {c: '#{env_home}/.config/nvim/init.vim'},
            -- FIXME notes/todo.md?
            {d: '#{env_home}/todo.md'},
            -- FIXME xdg dir instead?
            {x: '#{env_home}/.tmuxp/'},
          }
          vim.api.nvim_set_var "startify_fortune_use_unicode", 1
          -- Prepend devicon language logos to file paths
          -- TODO: improve vim-startify to use this for bookmark entries as well
          -- FIXME once we have native Lua way of defining viml functions
          vim.api.nvim_command [[
            function! StartifyEntryFormat()
              return 'WebDevIconsGetFileTypeSymbol(absolute_path) ." ". entry_path'
            endfunction
          ]]
        '';
      };
      # Adds a set of functions to retrieve the name of the 'current' function in a
      # source file, for the scope the cursor is in
      "tyru/current-func-info.vim".enable = true;
      # Slightly gamifies programming, for shits 'n' giggles
      # "Shados/codestats.nvim" = {
      #   enable = true;
      #   dependencies = [ "Shados/facade.nvim" "Shados/earthshine" ];
      #   extraConfig = ''
      #     " Pull the oh-so-important sekret API key from an environment variable
      #     let g:codestats_api_key = $CODESTATS_API_KEY
      #   '';
      # };
      ack-vim = {
        enable = true;
        extraConfig = ''
          -- Use the current under-cursor word if the ack search is empty
          vim.api.nvim_set_var "ack_use_cword_for_empty_search", 1

          -- Don't jump to first match
          -- FIXME once we have native Lua / API method
          vim.api.nvim_command 'cnoreabbrev Ack Ack!'

          vim.api.nvim_set_keymap "n", "<leader>/", ":Ack!<Space>", {noremap: true}
        '';
      };
      "tpope/vim-unimpaired".enable = true;
      # }}}

      # Next-up {{{
      # Better mark handling and display
      # "bootleq/ShowMarks" = { };
      # git integration for vim, need to watch screencasts. Have activated for now
      # for commit wrapping.
      vim-fugitive.enable = true;
      # vim-based git viewer, needs fugitive repo viewer/browser
      # "gregsexton/gitv" = { };
      # Align elements on neighbouring lines, e.g. quickly build text 'tables'
      # "godlygeek/tabular" = { };
      # Lookup docs on word under cursor, configurable lookup command - this would
      # be extremely useful if I write PageUp
      # "Keithbsmiley/investigate.vim" = { };
      # }}}

      # Some transitive dependency specs {{{
      "Shados/facade.nvim" = {
        after = [
          "Shados/earthshine"
        ];
      };
      # }}}
    };
  };
}
