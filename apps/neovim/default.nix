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
    earlyConfig = /* vim */ ''
      " Early-load settings
      let mapleader = "\<Space>"
      " Define my autocmd group for later use
      augroup vimrc
        " Clear any existing autocmds (e.g. if re-sourcing init.vim)
        autocmd!
      augroup END
    '';
    prePluginConfig = ''
      " Theming stuff
      " The xterm and screen ones are actually both for Mosh
      if !empty($TMUX) || $TERM ==# 'rxvt-unicode' || $TERM ==# 'rxvt-unicode-256color' || $TERM==# 'xterm' || $TERM ==# 'xterm-256color' || $TERM ==# 'screen' || $TERM ==# 'screen-256color'
        set termguicolors
      endif
      syntax enable
    '';
    extraConfig = ''
      " Basic configuration {{{
        " Resize splits when the window is resized
        autocmd vimrc VimResized * exe "normal! \<c-w>="

        " Search
          " Incremental searching
          set incsearch
          " Highlight matches by default
          set hlsearch
          " Ignore case when searching
          set ignorecase
          " ^ unless a capital letter is typed
          set smartcase

        " Hybrid relative line numbers
          set number
          set relativenumber

        " Indentation
          " Copy indent to new line
          set autoindent
          " Use 2-space autoindentation
          set shiftwidth=2
          set softtabstop=2
          " Together with ^, number of spaces a <Tab> counts for
          set tabstop=2
          " Change <Tab> into spaces automatically in insert mode and with autoindent
          set expandtab
          " Insert a real <Tab> with CTRL-V<Tab> while in insert mode

        " Allow backspace in insert mode
        set backspace=indent,eol,start
        set history=1000
        " Buffers are not unloaded when 'abandoned' by editing a new file, only when actively quit
        set hidden
        " Wrap lines...
        set wrap
        " ...visually, at convenient places
        set linebreak
        " Display <Tab>s and trailing spaces visually
        set list listchars=trail:·,tab:»·
        " Because file-based folds are awesome
        set foldmethod=marker
        " Keep 6 lines minimum above/below cursor when possible; gives context
        set scrolloff=6
        " Similar, but for vertical space & columns
        set sidescrolloff=10
        " Minimum number of columns to scroll horiznotall when moving cursor off screen
        set sidescroll=1
        " Previous two only apply when `wrap` is off, something I occasionally need to do
        " Disable mouse cursor movement
        set mouse="c"
        " Support modelines in files
        set modeline
        " Always keep the gutter open, constant expanding/contracting gets annoying fast
        set signcolumn=yes

        " Set netrwhist home location to prevent .netrwhist being made in
        " .config/nvim/ -- it is data not config
        let g:netrw_home=stdpath('data')
      " }}}

      " Advanced configuration {{{
        " Use ripgrep for search backend
        " vimgrep == needed for compatibility with ack.vim
        " no-heading == grouping by file isn't needed for this use-case
        " smart-case == case-insensitive search if all-lowercase pattern,
        "               case-sensitive otherwise
        let g:ackprg = '${rg} --vimgrep --smart-case --no-heading --max-filesize=4M'
        set grepprg:${rg}\ --vimgrep\ --smart-case\ --no-heading\ --max-filesize=4M
        set grepformat=%f:%l:%c:%m,%f:%l:%m

        " When jumping from quickfix window to a location, use existing
        " matching open buffer if present
        set switchbuf=useopen

        " TODO: Delete old undofile automatically when vim starts
        " TODO: Delete old backup files automatically when vim starts
        " Both are under ~/.local/share/nvim/{undo,backup} in neovim by default
        " Keep undo history across sessions by storing it in a file
        set undodir=~/.local/share/nvim/undo/
        if !empty(glob(&undodir))
          silent call mkdir(&undodir, 'p')
        endif
        set backupdir=~/.local/share/nvim/backup/
        " TODO this doesn't work for backupdir, figure out why
        if !empty(glob(&backupdir))
          silent call mkdir(&backupdir, 'p')
        endif
        set undofile
        set backup
        " This one creates temporary backup files, as opposed to the permanent ones from 'backup'
        set nowritebackup
        " Otherwise, it may decide to do all writes by first moving the written
        " file to a temporary name, then writing out the modified files to the
        " original name, then moving the temporary file to the backupdir. This
        " approach generates way more filesystem events than necessary, and is
        " likely to trigger race conditions in e.g. compiler 'watch' modes that
        " use inotify.
        set backupcopy=yes

        " TODO: Make incremental search open all folds with matches while
        " searching, close the newly-opened ones when done (except the one the
        " selected match is in)

        " TODO: Configure makers for automake

        " File-patterns to ignore for wildcard matching on tab completion
          set wildignore=*.o,*.obj,*~
          set wildignore+=*.png,*.jpg,*.gif,*.mp3,*.ogg,*.bin

        " Have nvim jump to the last position when reopening a file
        autocmd vimrc BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
        " Exclude gitcommit type to avoid doing this in commit message editor
        " sessions
        autocmd vimrc FileType gitcommit normal! gg0

        " Default to opened folds in gitcommit filetype (having them closed by
        " default doesn't make sense in this context; only really comes up when
        " using e.g. `git commit -v` to get the commit changes displayed)
        autocmd vimrc FileType gitcommit normal zR

        " Track window- and buffer-local options in sessions
        set sessionoptions+=localoptions

        " TODO when working on code inside a per-project virtualenv or nix.shell,
        " automatically detect and use the python from the project env
      " }}}

      " Key binds/mappings {{{
        " Fuck hitting shift
        map ; :
        " Just in case we actually need ;, double-tap it
        noremap ;; ;
        " We leave the : mapping in place to avoid mishaps with typing
        " :Uppercasecommands

        " Easier window splits, C-w,v to vv, C-w,s to ss
        nnoremap <silent> vv <C-w>v
        nnoremap <silent> ss <C-w>s

        " Quicker split navigation with <leader>-h/l/j/k
        nnoremap <silent> <leader>h <C-w>h
        nnoremap <silent> <leader>l <C-w>l
        nnoremap <silent> <leader>k <C-w>k
        nnoremap <silent> <leader>j <C-w>j

        " Quicker split resizing with Ctrl-<Arrow Key>
        nnoremap <C-Up> <C-w>+
        nnoremap <C-Down> <C-w>-
        nnoremap <C-Left> <C-w><
        nnoremap <C-Right> <C-w>>

        " swap so that: 0 to go to first character, ^ to start of line, we want
        " the former more often
        nnoremap 0 ^
        nnoremap ^ 0

        " close quickfix window more easily
        nmap <silent> <Leader>qc :cclose<CR>

        " Quickly turn off search highlights
        nmap <Leader>hs :nohls<CR>

        " Backspace to swap to previous buffer
        noremap <BS> <C-^>
        " Shift-Backspace to delete line contents but leave the line itself
        noremap <S-BS> cc<ESC>

        " Open current file in external program
        nnoremap <Leader>o :exe ':silent !xdg-open % &'<CR>

        " Map C-j and C-k with the PUM visible to the arrows
        inoremap <expr> <C-j> pumvisible() ? "\<Down>" : "\<C-j>"
        inoremap <expr> <C-k> pumvisible() ? "\<Up>" : "\<C-k>"

        " For debugging syntax highlighters
        map <F10> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
          \ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
          \ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>
      " }}}
    '';
    pluginRegistry = {
      # Appearance & UI {{{
      oceanic-next.enable = true;
      gruvbox.enable = false;
      # Visually colorise CSS-compatible # colour code strings
      vim-css-color.enable = true;
      lightline-vim = {
        enable = true;
        nvimrc.postPlugin = ''
          " lightline {{{
          let g:lightline = {
            \ 'active': {
            \   'left': [ [ 'mode', 'paste' ],
            \             [ 'fugitive'],[ 'filename' ] ]
            \ },
            \ 'component_function': {
            \   'fugitive': 'LLFugitive',
            \   'readonly': 'LLReadonly',
            \   'modified': 'LLModified',
            \   'filename': 'LLFilename',
            \   'mode': 'LLMode'
            \ }
          \ }
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
          " }}}
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
        nvimrc.postPlugin = ''
          " Replace normal search with incsearch.vim
          map / <Plug>(incsearch-forward)
          map ? <Plug>(incsearch-backward)
          map g/ <Plug>(incsearch-stay)
        '';
      };
      # Visual display of indent levels
      "Yggdroot/indentLine" = {
        enable = true;
        nvimrc.postPlugin = ''
          let g:indentLine_char = '▏'
        '';
      };
      # Displays function signatures from completions in the command line
      "Shougo/echodoc.vim" = {
        enable = false;
        nvimrc.postPlugin = ''
          " So the current mode indicator in the command line does not overwrite the
          " function signature display
          set noshowmode
        '';
      };
      # }}}

      # Language support and syntax highlighting {{{
      # Async linting
      ale = with pkgs; mkMerge [
        # ALE config {{{
        { enable = true;
          nvimrc = {
            # TODO cleanup, should only have baseline config in here
            postPlugin = ''
              " Move forward/backward between flagged warnings & errors
              nmap <silent> <leader>] <Plug>(ale_next_wrap)
              nmap <silent> <leader>[ <Plug>(ale_previous_wrap)

              " TODO: use devicons for error/warning signs?
              " TODO: auto-open any lines in folds with linter errors in them, or at
              " least do so on changing to their location-list position to them...

              " Clear the warning buffer immediately on any change (to prevent
              " highlights on the edited line from falling out of sync and throwing me
              " off)
              autocmd vimrc TextChanged,TextChangedI * ALEResetBuffer

              " To still make it easy to know if there is *something* in the gutter *somewhere*
              let g:ale_change_sign_column_color = 1

              " Enable completion where LSP servers are available
              let g:ale_completion_enabled = 1

              " Per-language, non-LSP config after here
              function! s:register_ale_tool(dict, lang, tool, ...) abort
                " Previously used the 'tool' argument to do executable()
                " checks, but we're statically providing the executables with
                " Nix now, so this is unnecessary -- now it is just
                " documentation :)
                let l:linter_name = a:0 >= 1 ? a:1 : a:tool
                if has_key(a:dict, a:lang) == 0
                  let a:dict[a:lang] = []
                endif
                call add(a:dict[a:lang], l:linter_name)
              endfunction
              " By default, all available tools for all supported languages will be run
              " ...but explicit is better than implicit, especially given we
              " generate the set of available tools using Nix :)
              let g:ale_fixers = {}
              let g:ale_linters = {}
            '';
          };
        }
        { nvimrc.postPlugin = mkAfter ''
            " Bash
            call s:register_ale_tool(g:ale_linters, 'sh', 'shell')
            call s:register_ale_tool(g:ale_linters, 'sh', 'shellcheck')
            call s:register_ale_tool(g:ale_fixers, 'sh', 'shfmt')
            autocmd vimrc FileType sh let b:ale_fix_on_save = 1
          '';
          binDeps = [
            bash
            shellcheck
            shfmt
          ];
        }
        { nvimrc.postPlugin = mkAfter ''
            " JSON
            call s:register_ale_tool(g:ale_fixers, 'json', 'prettier')
            autocmd vimrc FileType json let b:ale_fix_on_save = 1
          '';
          binDeps = [
            pkgs.nodePackages.prettier
          ];
        }
        { nvimrc.postPlugin = mkAfter ''
            " Nix
            call s:register_ale_tool(g:ale_linters, 'nix', 'nix-instantiate', 'nix')
          '';
        }
        { nvimrc.postPlugin = mkAfter ''
            " VimL/vimscript
            call s:register_ale_tool(g:ale_linters, 'vim', 'vint')
          '';
          binDeps = [
            vim-vint
          ];
        }
        { nvimrc.postPlugin = mkAfter ''
            " YAML
            call s:register_ale_tool(g:ale_linters, 'yaml', 'yamllint')
          '';
          binDeps = with python3Packages; [
            yamllint
          ];
        }
        # }}}
      ];
      "ericpruitt/tmux.vim".enable = true;
      "gabrielelana/vim-markdown" = {
        enable = true;
        nvimrc.postPlugin = ''
          " Enable/disable syntax-based folding.
          " This will have negative performance impact on sufficiently large files,
          " however, and simply disabling folding in general does not stop that.
          let g:markdown_enable_folding = 0
          let g:markdown_enable_spell_checking = 0
          let g:markdown_enable_input_abbreviations = 0
          let g:markdown_enable_conceal = 0
          " Automatically unfold all
          autocmd vimrc FileType markdown normal zR
          let g:markdown_composer_autostart = 0
          " Set indent/tab for markdown files to 4 spaces
          autocmd vimrc FileType markdown setlocal shiftwidth=4 softtabstop=4 tabstop=4
        '';
      };
      # Nix syntax highlighting, error checking/linting is handled by ALE
      vim-nix.enable = true;
      "Matt-Deacalion/vim-systemd-syntax".enable = true;
      # Notably, let's you fold on json dict/lists
      vim-json = {
        enable = true;
        nvimrc.postPlugin = ''
          " vim-json
          " Set foldmethod to syntax so we can fold json dicts and lists
          autocmd vimrc FileType json setlocal foldmethod=syntax
          " Then automatically unfold all so we don't start at 100% folded :)
          autocmd vimrc FileType json normal zR
          " Don't conceal quote marks, that's fucking horrific. Who the hell would
          " choose to default to that behaviour? Do they only ever read json, never
          " write it?! Hell, even then it's still problematic!
          let g:vim_json_syntax_conceal = 0
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
        nvimrc.postPlugin = ''
          let g:neosnippet#snippets_directory = stdpath('config') . '/neosnippets/'
          " Use actual tabstops in snippet files
          autocmd vimrc FileType neosnippet setlocal noexpandtab

          " Mappings
          imap <C-k>     <Plug>(neosnippet_expand_or_jump)
          smap <C-k>     <Plug>(neosnippet_expand_or_jump)
          xmap <C-k>     <Plug>(neosnippet_expand_target)
        '';
      };
      neosnippet-snippets = {
        enable = true;
        dependencies = [ "Shougo/neosnippet.vim" ];
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
        nvimrc.postPlugin = ''
          set shortmess+=c
          set completeopt+=preview " Open preview/details window
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
        nvimrc = {
          postPlugin = ''
            " Disable lightline's tabline functionality, as it conflicts with this
            if has_key(g:lightline, 'enable') == 0
              let g:lightline.enable = {}
            endif
            let g:lightline.enable.tabline = 0

            " Prettify TODO proper module deps for these
            let g:workspace_powerline_separators = 1
            let g:workspace_tab_icon = "\uf00a"
            let g:workspace_left_trunc_icon = "\uf0a8"
            let g:workspace_right_trunc_icon = "\uf0a9"
          '';
        };
      };
      nerdtree = {
        enable = true;
        on = [ "NERDTreeToggle" "NERDTreeFind" ];
        nvimrc.postPlugin = ''
          " Prettify NERDTree
          let NERDTreeMinimalUI = 1
          let NERDTreeDirArrows = 1

          " Open project file explorer in pane
          nmap <Leader>p :NERDTreeToggle<CR>
          " Open the project tree and expose current file in the tree with Ctrl-\
          nnoremap <silent> <C-\> :NERDTreeFind<CR>

          " Disable the scrollbars (NERDTree)
          set guioptions-=r
          set guioptions-=L
        '';
      };
      # Full path fuzzy file/buffer/mru/tag/.../arbitrary list search, bound to
      # <leader>f (for find?)
      denite-nvim = {
        enable = true;
        remote.python3 = true;
        nvimrc.postPlugin = ''
          " Sane ignore for file tree matching, this ignores vcs files, binaries,
          " temporary files, etc.
          call denite#custom#filter ('matcher_ignore_globs', 'ignore_globs',
            \ [ '.git/', '.hg/', '.svn/', '.yardoc/', 'public/mages/',
            \   'public/system/', 'log/', 'tmp/', '__pycache__/', 'venv/', '*.min.*',
            \   '*.pyc', '*.exe', '*.so', '*.dat', '*.bin', '*.o'])
          " Use ripgrep for denite file search backend
          call denite#custom#var('file/rec', 'command',
            \ ['${rg}', '--files', '--color', 'never'])
          call denite#custom#var('grep', {
            \ 'command': ['${rg}'],
            \ 'default_opts': ['--vimgrep', '--smart-case', '--no-heading', '--max-filesize=4M'],
            \ 'recursive_opts': [],
            \ 'pattern_opt': ['--regexp'],
            \ 'separator': ['--'],
            \ 'final_opts': [],
            \ })
          " Change the default sorter for the sources I care about
          call denite#custom#source('file/rec', 'sorters', ['sorter_sublime'])
          call denite#custom#source('file_mru', 'sorters', ['sorter_sublime'])
          call denite#custom#source('buffer', 'sorters', ['sorter_sublime'])

          " Searches through most-recently-used files, recursive file/dir tree, and
          " current buffers
          nnoremap <leader>f :<C-u>Denite buffer file/rec file_mru <cr>
          nnoremap <leader>b :<C-u>Denite buffer -quick-move="immediately" <cr>
        '';
      };
      # neomru-vim.enable = true;
      # Display FIXME/TODO/etc. in handy browseable list pane, bound to <Leader>t,
      # then q to cancel, e to quit browsing but leave tasklist up, <CR> to quit
      # and place cursor on selected task
      "vim-scripts/TaskList.vim".enable = true;
      # Extended session management, auto-save/load
      "Shados/vim-session" = {
        enable = true;
        dependencies = [ "xolox/vim-misc" ];
        branch = "shados-local";
        nvimrc.postPlugin = let
        in ''
          let g:session_autoload = 'no'
          let g:session_autosave = 'prompt'
          let g:session_autosave_only_with_explicit_session = 1
          " Session-prefixed command aliases, e.g. OpenSession -> SessionOpen
          let g:session_command_aliases = 1
          let g:session_directory = stdpath('data') . '/sessions'
          let g:session_lock_directory = stdpath('data') . '/session-locks'
          " Ensure session dirs exist
          silent call mkdir(g:session_directory, 'p')
          silent call mkdir(g:session_lock_directory, 'p')
        '';
      };
      # Builds and displays a list of tags (functions, variables, etc.) for the
      # current file, in a sidebar
      tagbar = {
        enable = true;
        on = "TagbarToggle";
        nvimrc.postPlugin = ''
          " Default tag sorting by order of appearance within file (still grouped by
          " scope)
          let g:tagbar_sort = 0
          " Keep all tagbar folds closed initially; better for a top-level overview
          let g:tagbar_foldlevel = 0
          " Move cursor to the tagbar window when it is opened
          let g:tagbar_autofocus = 1

          nmap <leader>m :TagbarToggle<CR>
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
        nvimrc.postPlugin = ''
          " s{char}{char} to easymotion-highlight all matching two-character sequences in sight
          nmap s <Plug>(easymotion-overwin-f2)
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
        on = "GundoToggle";
        remote.python3 = true;
        # Theoretically works with python 2 or 3; in practice it has a fixed
        # check for python2 support unless you specify this pref.
        # https://github.com/sjl/gundo.vim/pull/36 &&
        # https://github.com/sjl/gundo.vim/pull/35
        nvimrc = {
          prePlugin = ''
          let g:gundo_prefer_python3 = 1
          '';
          postPlugin = ''
            " Visualize undo tree in pane
            nnoremap <Leader>u :GundoToggle<CR>
            let g:gundo_right = 1 " Opposite nerdtree's pane
          '';
        };
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
        nvimrc.postPlugin = optionalString (plugCfg."Shados/vim-session".enable) ''
          let g:startify_session_dir = g:session_directory
        '' + ''
          let g:startify_list_order = [
            \ ['  Bookmarks'], 'bookmarks',
            \ ['  Sessions'], 'sessions',
            \ ['  Commands'], 'commands',
            \ ['  MRU Current Tree Files by Modification Time'], 'dir',
          \ ]
          let g:startify_bookmarks = [
            \ {'c': '~/.config/nvim/init.vim'},
            \ {'d': '~/todo.md'},
            \ {'x': '~/.tmuxp/'},
          \ ]
          let g:startify_fortune_use_unicode = 1
          " Prepend devicon language logos to file paths
          " TODO: improve vim-startify to use this for bookmark entries as well
          function! StartifyEntryFormat()
            return 'WebDevIconsGetFileTypeSymbol(absolute_path) ." ". entry_path'
          endfunction
        '';
      };
      # Adds a set of functions to retrieve the name of the 'current' function in a
      # source file, for the scope the cursor is in
      "tyru/current-func-info.vim".enable = true;
      # Slightly gamifies programming, for shits 'n' giggles
      # "Shados/codestats.nvim" = {
      #   enable = true;
      #   dependencies = [ "Shados/facade.nvim" "Shados/earthshine" ];
      #   nvimrc.postPlugin = ''
      #     " Pull the oh-so-important sekret API key from an environment variable
      #     let g:codestats_api_key = $CODESTATS_API_KEY
      #   '';
      # };
      ack-vim = {
        enable = true;
        nvimrc.postPlugin = ''
          " Use the current under-cursor word if the ack search is empty
          let g:ack_use_cword_for_empty_search = 1

          " Don't jump to first match
          cnoreabbrev Ack Ack!

          nnoremap <Leader>/ :Ack!<Space>
        '';
      };
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
