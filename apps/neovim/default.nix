{ config, lib, pkgs, ... }:
with lib;
let
  nvimCfg = config.sn.programs.neovim;
  plugCfg = nvimCfg.pluginRegistry;
  pins = import ../../pins;
  # TODO figure out why moonscript filetype doesn't appear to be applying automatically/correctly
  # TODO migrate plugins to non-upstream packages where possible, for more control over updates
in
{
  imports = [
    # Theme-related defaults
    ./gruvbox.nix
    ./oceanicnext.nix
  ];
  nixpkgs.overlays = [
    (import pins.neovim-nightly-overlay)
  ];

  sn.programs.neovim = let
    rgPkg = pkgs.ripgrep;
    rg = "${rgPkg}/bin/rg";
  in {
    neovimPackage = pkgs.neovim-nightly;
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

      local sl -- Mildly hacky forward-declaration to work around a code ordering issue
      ${builtins.readFile ./prePluginConfig.moon}
    '';
    extraConfig = ''
      rg_bin = '${rg}'
      ${builtins.readFile ./extraConfig.moon}
    '' + optionalString plugCfg.ale.enable ''
      g["ale_linters"] = ale_linters
      g["ale_fixers"] = ale_fixers
    '';
    pluginRegistry = {
      # Appearance & UI {{{
      oceanic-next.enable = true;
      gruvbox.enable = false;
      # Visually colorise CSS-compatible # colour code strings
      "norcalli/nvim-colorizer.lua" = {
        enable = true;
        extraConfig = ''
          require("colorizer").setup {
            "*",
            css:
              css: true
          }
        '';
      };
      nvim-web-devicons = {
        # TODO add font dep and config?
        enable = true;
        extraConfig = ''
          nvim_web_devicons = require "nvim-web-devicons"
          nvim_web_devicons.setup
            default: true
        '';
      };

      # Visual display of indent levels
      "lukas-reineke/indent-blankline.nvim" = {
        enable = true;
        branch = "lua"; # TODO can revert to master once nvim 0.5 is released
        # TODO indent_blankline_use_treesitter ?
        # TODO indent_blankline_show_current_context ? may be extra-useful when
        # working with Python and MoonScript
        extraConfig = ''
          -- FIXME Remove once identline-blankline.nvim#59 / neovim#14209 is resolved
          set "colorcolumn", "99999"
          g.indent_blankline_char = '▏'
          g.indent_blankline_buftype_exclude = {
            "terminal", "help", "quickfix", "prompt", "nofile", "nowrite"
          }
          g.indent_blankline_show_first_indent_level = false
        '';
      };

      # Displays function signatures from completions in the command line
      "Shougo/echodoc.vim" = {
        # TODO re-enable once I sort out my completion setup
        enable = false;
        extraConfig = ''
          -- So the current mode indicator in the command line does not overwrite the
          -- function signature display
          set "showmode", false
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
            map "n", "<leader>]", "<Plug>(ale_next_wrap)", {silent: true}
            map "n", "<leader>[", "<Plug>(ale_previous_wrap)", {silent: true}

            -- TODO: use devicons for error/warning signs?
            -- TODO: auto-open any lines in folds with linter errors in them, or at
            -- least do so on changing to their location-list position to them...

            -- Clear the warning buffer immediately on any change (to prevent
            -- highlights on the edited line from falling out of sync and throwing me
            -- off)
            cmd 'autocmd vimrc TextChanged,TextChangedI * ALEResetBuffer'

            -- To still make it easy to know if there is *something* in the gutter *somewhere*
            g["ale_change_sign_column_color"] = 1

            -- Enable completion where LSP servers are available
            g["ale_completion_enabled"] = 1

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
            cmd 'autocmd vimrc FileType sh let b:ale_fix_on_save = 1'
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
            cmd 'autocmd vimrc FileType json let b:ale_fix_on_save = 1'
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
      # TODO debug weird auto-un/folding shit when entering a newline after a
      # #-level title in a markdown file with a YAML frontmatter
      vim-markdown = {
        enable = true;
        extraConfig = ''
          -- Open all folds by default
          cmd 'autocmd vimrc FileType markdown normal zR'
          -- Set indent/tab for markdown files to 4 spaces
          cmd 'autocmd vimrc FileType markdown setlocal shiftwidth=4 softtabstop=4 tabstop=4'
          -- Fixes re-wrapping long list items
          g.vim_markdown_auto_insert_bullets = 0

          g.vim_markdown_toc_autofit = 1

          -- Explicitly disable conceal usage
          g.vim_markdown_conceal = 0
          g.vim_markdown_conceal_code_blocks = 0
          g.tex_conceal = ""

          -- Extensions
          g.vim_markdown_strikethrough = 1
          g.vim_markdown_frontmatter = 1
          ${optionalString plugCfg.vim-toml.enable ''g.vim_markdown_toml_frontmatter = 1''}
          ${optionalString plugCfg.vim-json.enable ''g.vim_markdown_json_frontmatter = 1''}
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
          cmd 'autocmd vimrc FileType json setlocal foldmethod=syntax'
          -- Then automatically unfold all so we don't start at 100% folded :)
          cmd 'autocmd vimrc FileType json normal zR'
          -- Don't conceal quote marks, that's fucking horrific. Who the hell would
          -- choose to default to that behaviour? Do they only ever read json, never
          -- write it?! Hell, even then it's still problematic!
          g["vim_json_syntax_conceal"] = 0
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
      # TODO: Consider building my own solution on top of snippets.nvim instead
      neosnippet-vim = {
        enable = true;
        extraConfig = ''
          -- Use actual tabstops in snippet files
          cmd 'autocmd vimrc FileType neosnippet setlocal noexpandtab'

          -- Mappings
          map "i", "<C-k>", "<Plug>(neosnippet_expand_or_jump)", {}
          map "s", "<C-k>", "<Plug>(neosnippet_expand_or_jump)", {}
          map "x", "<C-k>", "<Plug>(neosnippet_expand_target)", {}
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
          set "shortmess", "#{o["shortmess"]}c"
          -- Open preview/details window
          set "completeopt", "#{o["completeopt"]},preview"
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
        commit = "044f2954a5e49aea8625973de68dda8750f1c42d";
        extraConfig = ''
          -- Prettify
          g["workspace_powerline_separators"] = 1
          g["workspace_tab_icon"] = ""
          g["workspace_left_trunc_icon"] = ""
          g["workspace_right_trunc_icon"] = ""
        '';
      };
      nerdtree = {
        enable = true;
        on_cmd = [ "NERDTreeToggle" "NERDTreeFind" ];
        extraConfig = ''
          -- Prettify NERDTree
          g["NERDTreeMinimalUI"] = 1
          g["NERDTreeDirArrows"] = 1

          -- Open project file explorer in pane
          map "n", "<leader>p", ":NERDTreeToggle<CR>", {}
          -- Open the project tree and expose current file in the tree with Ctrl-\
          map "n", "<C-\\>", ":NERDTreeFind<CR>", {noremap: true, silent: true}

          -- Disable the scrollbars
          -- FIXME once we have Lua equivalent to set-=
          cmd 'set guioptions-=r'
          cmd 'set guioptions-=L'
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
          fn['denite#custom#filter'] "matcher_ignore_globs", "ignore_globs", {
            '.git/', '.hg/', '.svn/', '.yardoc/', 'public/mages/',
            'public/system/', 'log/', 'tmp/', '__pycache__/', 'venv/',
            '*.min.*', '*.pyc', '*.exe', '*.so', '*.dat', '*.bin', '*.o'
          }
          -- Use ripgrep for denite file search backend
          fn['denite#custom#var'] "file/rec", "command",
            {"${rg}", "--files", "--color", "never"}
          fn['denite#custom#var'] "grep", {
            command: {"${rg}"}
            default_opts: {"--vimgrep", "--smart-case", "--no-heading", "--max-filesize=4M"}
            recursive_opts: {}
            pattern_opt: {"--regexp"}
            separator: {"--"}
            final_opts: {}
          }
          -- Change the default sorter for the sources I care about
          fn['denite#custom#source'] "file/rec", "sorters", {"sorter_sublime"}
          -- fn['denite#custom#source'] "file/mru", "sorters", {"sorter_sublime"}
          fn['denite#custom#source'] "buffer", "sorters", {"sorter_sublime"}

          -- Searches through current buffers and recursive file/dir tree
          map "n", "<leader>f", ":<C-u>Denite buffer file/rec -split=floating -winrow=1<cr>", {noremap: true}
          map "n", "<leader>b", ':<C-u>Denite buffer -quick-move="immediately" -split=floating -winrow=1<cr>', {noremap: true}

          -- Default to filtering the resultant buffer
          fn['denite#custom#option'] "_", {start_filter: 1}

          -- Define default mappings for the denite buffers
          -- FIXME once we have a more native Lua way to do this
          cmd [[
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
          g["session_autoload"] = "no"
          g["session_autosave"] = "prompt"
          g["session_autosave_only_with_explicit_session"] = 1
          -- Session-prefixed command aliases, e.g. OpenSession -> SessionOpen
          g["session_command_aliases"] = 1
          session_dir = "#{stdpath "data"}/sessions"
          session_lock_dir = "#{stdpath "data"}/session-locks"
          g["session_directory"] = session_dir
          g["session_lock_directory"] = session_lock_dir
          -- Ensure session dirs exist
          fn.mkdir session_dir, "p"
          fn.mkdir session_lock_dir, "p"
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
          g["tagbar_sort"] = 0
          -- Keep all tagbar folds closed initially; better for a top-level overview
          g["tagbar_foldlevel"] = 0
          -- Move cursor to the tagbar window when it is opened
          g["tagbar_autofocus"] = 1

          map "n", "<leader>m", ":TagbarToggle<CR>", {}
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
          map "n", "s", "<Plug>(easymotion-overwin-f2)", {}
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
          g["gundo_prefer_python3"] = 1
          -- Visualize undo tree in pane
          map "n", "<leader>u", ":GundoToggle<CR>", {noremap: true}
          g["gundo_right"] = 1 -- Opposite nerdtree's pane
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
        after = [ "Shados/vim-session" "nvim-web-devicons" ];
        extraConfig = optionalString (plugCfg."Shados/vim-session".enable) ''
          g["startify_session_dir"] = g["session_directory"]
        '' + ''
          g["startify_lists"] = {
            { header: {'  Bookmarks'}, type: 'bookmarks' },
            { header: {'  Sessions'}, type: 'sessions' },
            { header: {'  Commands'}, type: 'commands' },
            { header: {'  MRU Current Tree Files by Modification Time'}, type: 'dir' },
          }
          g["startify_bookmarks"] = {
            {d: "~/notes/Todo.md"},
            -- FIXME move it to an xdg dir instead?
            {x: "~/.tmuxp/"},
          }
          g["startify_fortune_use_unicode"] = 1
        '' + optionalString plugCfg.nvim-web-devicons.enable ''
          -- Prepend devicon language logos to file paths
          -- TODO: improve vim-startify to use this for bookmark entries as well
          -- FIXME once we have native Lua way of defining viml functions
          export icon_from_path
          icon_from_path = (path) ->
            file_name = path\match "^.-([^/]*)$"
            extension = path\match "^.-([^.]*)$"
            nvim_web_devicons.get_icon file_name, extension
          cmd [[
            function! StartifyEntryFormat()
              return 'luaeval("icon_from_path(_A[1])", [absolute_path]) ." ". entry_path'
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
          g["ack_use_cword_for_empty_search"] = 1

          -- Don't jump to first match
          -- FIXME once we have native Lua / API method
          cmd 'cnoreabbrev Ack Ack!'

          map "n", "<leader>/", ":Ack!<Space>", {noremap: true}
        '';
      };
      "tpope/vim-unimpaired".enable = true;
      # TODO set these up
      "nvim-telescope/telescope.nvim" = {
        enable = true;
        dependencies = [ "nvim-lua/plenary.nvim" "nvim-lua/popup.nvim" ];
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
        dependencies = [
          "Shados/earthshine"
        ];
      };
      "nvim-lua/popup.nvim".dependencies = [ "nvim-lua/plenary.nvim" ];
      # }}}
    };
  };
}
