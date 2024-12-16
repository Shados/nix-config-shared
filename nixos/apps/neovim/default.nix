{ config, inputs, lib, pkgs, ... }:
with lib;
let
  nvimCfg = config.sn.programs.neovim;
  plugCfg = nvimCfg.pluginRegistry;
  pins = import ./pins { };
  # TODO migrate plugins to non-upstream packages where possible, for more control over updates
  inherit (pkgs) vimPlugins;
in
{
  imports = [
    # Theme-related defaults
    ./oceanicnext.nix
  ];
  nixpkgs.overlays = [
    (inputs.neovim-nightly-overlay.overlays.default)
  ];

  sn.programs.neovim = let
    rgPkg = pkgs.ripgrep;
    rg = "${rgPkg}/bin/rg";
  in {
    neovimPackage = pkgs.neovim;
    mergePlugins = mkDefault true;
    files = {
      "ftplugin/python.vim".source = ./nvim-files/ftplugin/python.vim;
      neosnippets.source = ./nvim-files/neosnippets;
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
    # TODO disable my statusline in the nvim-tree, and mundo windows
    extraConfig = ''
      rg_bin = '${rg}'
      ${builtins.readFile ./extraConfig.moon}
    '' + optionalString plugCfg.ale.enable ''
      g.ale_linters_explicit = 1
      g.ale_linters = ale_linters
      g.ale_fixers = ale_fixers
    '';
    pluginRegistry = {
      # Appearance & UI {{{
      oceanic-next = {
        enable = true;
        source = vimPlugins.oceanic-next;
      };
      # Visually colorise CSS-compatible # colour code strings
      nvim-colorizer-lua = {
        enable = true;
        source = vimPlugins.nvim-colorizer-lua;
        extraConfig = ''
          require("colorizer").setup { filetypes: { "css", "javascript" } }
        '';
      };
      nvim-web-devicons = {
        # TODO add font dep and config?
        enable = true;
        source = vimPlugins.nvim-web-devicons;
        extraConfig = ''
          nvim_web_devicons = require "nvim-web-devicons"
          nvim_web_devicons.setup
            default: true
        '';
      };

      # Visual display of indent levels
      indent-blankline-nvim = {
        enable = true;
        source = vimPlugins.indent-blankline-nvim;
        # TODO indent_blankline_use_treesitter ?
        # TODO indent_blankline_show_current_context ? may be extra-useful when
        # working with Python and MoonScript
        extraConfig = ''
          require"ibl".setup
            indent:
              char: '▏'
            exclude:
              buftypes: { "terminal", "nofile", "quickfix", "prompt", "help", "nowrite" }
          hooks = require "ibl.hooks"
          hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)
          ${optionalString plugCfg.vim-startify.enable ''
          -- Disable in startify buffer
          vim.api.nvim_create_autocmd {"FileType"}, {
            group: "vimrc",
            pattern: { "startify" },
            callback: -> (require "ibl").setup_buffer 0, {enabled: false}
          }
          ''}
        '';
      };

      # Displays function signatures from completions in the command line
      echodoc = {
        # TODO re-enable once I sort out my completion setup
        enable = false;
        source = vimPlugins.echodoc;
        extraConfig = ''
          -- So the current mode indicator in the command line does not overwrite the
          -- function signature display
          o.showmode = false
        '';
      };
      # }}}

      # Language support and syntax highlighting {{{
      # nvim-treesitter = {
      #   # FIXME: unclear why, but this shit is broken AF. Doesn't appear to be
      #   # a "upstream neovim parsers taking precedence over nvim-treesitter's",
      #   # not clear what else could be causing the issues I was seeing.
      #   enable = false;
      #   source = pkgs.vimPlugins.nvim-treesitter.withAllGrammars;
      #   extraConfig = ''
      #     require"nvim-treesitter.configs".setup
      #       auto_install: false
      #       highlight:
      #         enable: true
      #         additional_vim_regex_highlighting: false
      #   '';
      # };
      # Async linting
      ale = with pkgs; mkMerge [
        # ALE config {{{
        { enable = true;
          source = vimPlugins.ale;
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
            vim.api.nvim_create_autocmd {"TextChanged", "TextChangedI"}, {
              group: "vimrc",
              pattern: { "*" },
              command: "ALEResetBuffer"
            }

            -- To still make it easy to know if there is *something* in the gutter *somewhere*
            g.ale_change_sign_column_color = 1

            -- Enable completion where LSP servers are available
            g.ale_completion_enabled = 1

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
            vim.api.nvim_create_autocmd {"FileType"}, {
              group: "vimrc",
              pattern: { "sh" },
              command: "let b:ale_fix_on_save = 1"
            }
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
            vim.api.nvim_create_autocmd {"FileType"}, {
              group: "vimrc",
              pattern: { "json" },
              command: "let b:ale_fix_on_save = 1"
            }
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
      "tmux.vim" = {
        enable = true;
        source = nvimCfg.lib.buildVimPluginFromNiv pins "tmux.vim";
      };
      vim-markdown = {
        enable = true;
        source = vimPlugins.vim-markdown;
        extraConfig = ''
          -- Just disable header folding; it's pretty buggy
          g.vim_markdown_folding_disabled = 1
          -- Set indent/tab for markdown files to 4 spaces
          vim.api.nvim_create_autocmd {"FileType"}, {
            group: "vimrc",
            pattern: { "markdown" },
            command: "setlocal shiftwidth=4 softtabstop=4 tabstop=4"
          }
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
      vim-nix = {
        enable = true;
        source = vimPlugins.vim-nix;
      };
      vim-systemd-syntax = {
        enable = true;
        source = nvimCfg.lib.buildVimPluginFromNiv pins "vim-systemd-syntax";
      };
      # Notably, let's you fold on json dict/lists
      vim-json = {
        enable = true;
        source = vimPlugins.vim-json;
        extraConfig = ''
          -- vim-json
          -- Set foldmethod to syntax so we can fold json dicts and lists
          vim.api.nvim_create_autocmd {"FileType"}, {
            group: "vimrc",
            pattern: { "json" },
            command: "setlocal foldmethod=syntax"
          }
          -- Then automatically unfold all so we don't start at 100% folded :)
          vim.api.nvim_create_autocmd {"FileType"}, {
            group: "vimrc",
            pattern: { "json" },
            command: "normal zR"
          }
          -- Don't conceal quote marks, that's fucking horrific. Who the hell would
          -- choose to default to that behaviour? Do they only ever read json, never
          -- write it?! Hell, even then it's still problematic!
          g.vim_json_syntax_conceal = 0
        '';
      };
      "json5.vim" = {
        enable = true;
        source = nvimCfg.lib.buildVimPluginFromNiv pins "json5.vim";
      };
      vim-toml = {
        enable = true;
        source = vimPlugins.vim-toml;
      };
      vim-fish = {
        enable = true;
        source = vimPlugins.vim-fish;
        for = "fish";
      };
      nginx-vim = {
        enable = true;
        source = vimPlugins.nginx-vim;
      };
      yuescript-vim = {
        enable = true;
        source = nvimCfg.lib.buildVimPluginFromNiv pins "yuescript-vim";
      };
      # }}}

      # Text/code creation & refactoring {{{
      # Code snippets, the mighty slayer of boilerplate
      # TODO: Consider building my own solution on top of snippets.nvim instead
      neosnippet-vim = {
        enable = true;
        source = vimPlugins.neosnippet-vim;
        extraConfig = ''
          -- Use actual tabstops in snippet files
          vim.api.nvim_create_autocmd {"FileType"}, {
            group: "vimrc",
            pattern: { "neosnippet" },
            command: "setlocal noexpandtab"
          }

          -- Mappings
          map "i", "<C-k>", "<Plug>(neosnippet_expand_or_jump)", {}
          map "s", "<C-k>", "<Plug>(neosnippet_expand_or_jump)", {}
          map "x", "<C-k>", "<Plug>(neosnippet_expand_target)", {}
        '';
      };
      neosnippet-snippets = {
        enable = true;
        source = vimPlugins.neosnippet-snippets;
        dependencies = [ "neosnippet-vim" ];
      };
      # Automatic closing of control flow blocks for most languages, eg. `end`
      # inserted after `if` in Ruby
      vim-endwise = {
        enable = true;
        source = vimPlugins.vim-endwise;
      };
      # Automatic context-sensitive closing of quotes, parenthesis, brackets, etc.
      # and related features
      delimitMate = {
        enable = true;
        source = vimPlugins.delimitMate;
      };
      # Flexible word-variant tooling; mostly useful to me for 'coercing' between
      # different variable-naming styles (e.g. snake_case to camelCase via `crc`)
      vim-abolish = {
        enable = true;
        source = vimPlugins.vim-abolish;
      };
      nvim-cmp = {
        enable = true;
        source = vimPlugins.nvim-cmp;
        # TODO lspconfig stuff, snippets
        extraConfig = ''
          opt.shortmess\append { c: true }
          opt.completeopt = {"menu", "menuone", "noselect"}
          cmp = require "cmp"
          lspkind = require "lspkind"
          -- TODO add treesitter source once I have ts set up?
          cmp.setup
            sources: cmp.config.sources {
              { name: "nvim_lsp" },
              { name: "nvim_lua" }
              { name: "buffer" },
              { name: "path" },
            }
            mapping: cmp.mapping.preset.insert {
              ["<C-j>"]: cmp.mapping.select_next_item()
              ["<C-k>"]: cmp.mapping.select_prev_item()
              ["<C-f>"]: cmp.mapping.scroll_docs(4)
              ["<C-d>"]: cmp.mapping.scroll_docs(-4)
              ["<C-Space>"]: cmp.mapping.complete()
              ["<C-e>"]: cmp.mapping.abort()
              ["<CR>"]: cmp.mapping.confirm({ select: false })
            }
            formatting:
              format: lspkind.cmp_format {
                mode: "symbol_text"
                menu:
                  nvim_lsp: "[LSP]"
                  nvim_lua: "[Lua]"
                  buffer: "[Buffer]"
                  path: "[Path]"
              }
        '';
        # '';
        dependencies = [
          vimPlugins.lspkind-nvim
          # Completion sources
          vimPlugins.cmp-buffer vimPlugins.cmp-path vimPlugins.cmp-nvim-lsp vimPlugins.cmp-nvim-lua
        ];
      };
      # }}}

      # Project management {{{
      # Statusline with buffers and tabs listed very cleanly
      # TODO consider writing my own version in MoonScript, with a
      # jump-to-buffer function that works like vimfx follow-links?
      vim-buffet = {
        enable = true;
        source = nvimCfg.lib.buildVimPluginFromNiv pins "vim-buffet";
        extraConfig = ''
          -- Prettify
          g.workspace_powerline_separators = 1
          g.workspace_tab_icon = ""
          g.workspace_left_trunc_icon = ""
          g.workspace_right_trunc_icon = ""
        '';
      };
      nvim-tree-lua = {
        # TODO override the git icons with something more legible / immediately comprehensible
        # TODO add lines and arrows for dir structure?
        enable = true;
        source = vimPlugins.nvim-tree-lua;
        dependencies = [
          "nvim-web-devicons"
        ];
        extraConfig = ''
          nvim_tree = require "nvim-tree"
          nvim_tree.setup
            disable_netrw: false
            hijack_netrw: false
            git:
              ignore: false
            filters:
              custom: {".git"}

          map "n", "<leader>p", ":NvimTreeToggle<CR>", {noremap: true}
          map "n", "<C-\\>", ":NvimTreeFindFile<CR>", {noremap: true}
        '';
      };
      # Display FIXME/TODO/etc. in handy browseable list pane, bound to <Leader>t,
      # then q to cancel, e to quit browsing but leave tasklist up, <CR> to quit
      # and place cursor on selected task
      # TODO find/make equivalent but for telescope.nvim
      "TaskList.vim" = {
        enable = true;
        source = nvimCfg.lib.buildVimPluginFromNiv pins "TaskList.vim";
      };
      # Extended session management, auto-save/load
      vim-session = {
        enable = true;
        source = nvimCfg.lib.buildVimPluginFromNiv pins "vim-session";
        dependencies = [ (nvimCfg.lib.buildVimPluginFromNiv pins "vim-misc") ];
        extraConfig = let
        in ''
          g.session_autoload = "no"
          -- g.session_autosave = "prompt"
          g.session_autosave_only_with_explicit_session = 1
          -- Session-prefixed command aliases, e.g. OpenSession -> SessionOpen
          g.session_command_aliases = 1
          session_dir = "#{stdpath "data"}/sessions"
          session_lock_dir = "#{stdpath "data"}/session-locks"
          g.session_directory = session_dir
          g.session_lock_directory = session_lock_dir
          -- Ensure session dirs exist
          fn.mkdir session_dir, "p"
          fn.mkdir session_lock_dir, "p"
        '';
      };
      # Builds and displays a list of tags (functions, variables, etc.) for the
      # current file, in a sidebar
      tagbar = {
        enable = true;
        source = vimPlugins.tagbar;
        on_cmd = "TagbarToggle";
        extraConfig = ''
          --- Default tag sorting by order of appearance within file (still grouped by
          -- scope)
          g.tagbar_sort = 0
          -- Keep all tagbar folds closed initially; better for a top-level overview
          g.tagbar_foldlevel = 0
          -- Move cursor to the tagbar window when it is opened
          g.tagbar_autofocus = 1
          g.tagbar_ctags_bin = '${pkgs.universal-ctags}/bin/ctags'

          map "n", "<leader>m", ":TagbarToggle<CR>", {}
        '';
      };
      vim-addon-local-vimrc = {
        enable = true;
        source = vimPlugins.vim-addon-local-vimrc;
        extraConfig = ''
          g.local_vimrc =
            names: { ".vimrc.lua" }
            -- LVRHashOfFile will try sha512sum, sha256sum, sha1sum, and md5sum from PATH, if none exist it'll use a crappy VimL hash
            hash_fun: "LVRHashOfFile"
            -- Despite being called a cache file, the session-state path feels more appropriate here
            cache_file: "#{vim.fn.stdpath("state")}/vim_local_rc_cache"
        '';
        binDeps = [
          pkgs.coreutils
        ];
      };
      # }}}

      # Textobjects {{{
      # Upgrades many of vim's inbuilt textobjects and adds some very useful new
      # ones, like a, and i, for working with comma-separated lists
      targets-vim = {
        enable = true;
        source = vimPlugins.targets-vim;
      };
      # al for indent + start/close lines, ai for indent + start line, ii for
      # inside-indent
      vim-indent-object = {
        enable = true;
        source = vimPlugins.vim-indent-object;
      };
      # code-column textobject, adds ic, ac, iC and aC for working with columns,
      # a/inner column based on word/WORD
      "textobj-word-column.vim" = {
        enable = true;
        source = nvimCfg.lib.buildVimPluginFromNiv pins "textobj-word-column.vim";
      };
      # a_ and i_ for editing the middle of lines like foo_bar_baz, a_ includes the
      # _'s
      vim-textobj-underscore = {
        enable = true;
        source = nvimCfg.lib.buildVimPluginFromNiv pins "vim-textobj-underscore";
        dependencies = [ vimPlugins.vim-textobj-user ];
      };
      argtextobj-vim = {
        enable = true;
        source = vimPlugins.argtextobj-vim;
      };
      # TODO: function-based textobject
      # }}}

      # General extra functionality {{{
      vim-easymotion = {
        enable = true;
        source = vimPlugins.vim-easymotion;
        extraConfig = ''
          -- s{char}{char} to easymotion-highlight all matching two-character sequences in sight
          map "n", "s", "<Plug>(easymotion-overwin-f2)", {}
        '';
      };
      # Allows for splitting/joining code into/from multi-line formats, gS and gJ
      # by default
      splitjoin-vim = {
        enable = true;
        source = vimPlugins.splitjoin-vim;
      };
      # SublimeText-style multiple cursor impl., ctrl-n to start matching on
      # current word to place
      vim-multiple-cursors = {
        enable = true;
        source = vimPlugins.vim-multiple-cursors;
      };
      # Toggle commenting of lines with gc{motion}, also works in visual mode
      vim-commentary = {
        enable = true;
        source = vimPlugins.vim-commentary;
      };
      # Allows you to visualize your undo tree in a pane opened with :GundoToggle
      vim-mundo = {
        enable = true;
        source = vimPlugins.vim-mundo;
        remote.python3 = true;
        extraConfig = ''
          -- Visualize undo tree in pane
          map "n", "<leader>u", ":MundoToggle<CR>", {noremap: true}
          g.mundo_right = 1 -- Opposite nerdtree's pane
        '';
      };
      # Allows doing `vim filename:lineno`
      file-line ={
        enable = true;
        source = vimPlugins.file-line;
      };
      # ,w ,b and ,e alternate motions that support traversing CamelCase and
      # underscore_notation
      camelcasemotion = {
        enable = true;
        source = vimPlugins.camelcasemotion;
      };
      # Primarily useful for surrounding existing lines in new delimiters,
      # quotation marks, xml tags, etc., or removing or modifying said
      # 'surroundings'. <operation>s<surrounding-type> is most-used
      vim-surround = {
        enable = true;
        source = vimPlugins.vim-surround;
      };
      # Plugin-hookable `.`-replacement, user-transparent
      vim-repeat = {
        enable = true;
        source = vimPlugins.vim-repeat;
      };
      # Lets you do `:SudoWrite`/`:SudoRead`, and also launch vim with `nvim
      # sudo:/etc/fstab`, all of which are nicer+shorter than directly using the
      # tee trick; TODO has some issues
      "SudoEdit.vim" = {
        enable = true;
        source = nvimCfg.lib.buildVimPluginFromNiv pins "SudoEdit.vim";
      };
      # Reverse search ex command history ala Bash ctrl-r
      "ctrlr.vim" = {
        enable = true;
        source = nvimCfg.lib.buildVimPluginFromNiv pins "ctrlr.vim";
      };
      # A fancy start screen for vim (mainly for bookmarks and session listing)
      vim-startify = {
        enable = true;
        source = vimPlugins.vim-startify;
        after = [ "vim-session" "nvim-web-devicons" ];
        extraConfig = optionalString (plugCfg."vim-session".enable) ''
          g.startify_session_dir = g.session_directory
        '' + ''
          g.startify_lists = {
            { header: {'  Bookmarks'}, type: 'bookmarks' },
            { header: {'  Sessions'}, type: 'sessions' },
            { header: {'  Commands'}, type: 'commands' },
          }
          g.startify_skiplist = {
            "^/home/shados/technotheca/cdata"
          }
          g.startify_bookmarks = {
            {d: "~/notes/Todo.md"},
            {l: "~/notes/Log.md"},
            {s: "~/notes/Shopping.md"},
          }
          g.startify_fortune_use_unicode = 1
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
      "current-func-info.vim" = {
        enable = true;
        source = nvimCfg.lib.buildVimPluginFromNiv pins "current-func-info.vim";
      };
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
        source = vimPlugins.ack-vim;
        extraConfig = ''
          -- Use the current under-cursor word if the ack search is empty
          g.ack_use_cword_for_empty_search = 1

          -- Don't jump to first match
          -- FIXME once we have native Lua / API method
          cmd 'cnoreabbrev Ack Ack!'

          map "n", "<leader>/", ":Ack!<Space>", {noremap: true}
        '';
      };
      vim-unimpaired = {
        enable = true;
        source = vimPlugins.vim-unimpaired;
      };
      telescope-nvim = {
        enable = true;
        source = vimPlugins.telescope-nvim;
        binDeps = [
          pkgs.ripgrep pkgs.fd
        ];
        extraConfig = ''
          -- Setup with defaults
          telescope = require "telescope"
          telescope.setup!

          -- Searches through current buffers and recursive file/dir tree
          map "n", "<leader>b", "<cmd>lua require('telescope.builtin').buffers()<CR>", {noremap: true}
          map "n", "<leader>f", "<cmd>lua require('telescope.builtin').find_files()<CR>", {noremap: true}
        '';
      };
      telescope-fzy-native-nvim = {
        enable = true;
        source = vimPlugins.telescope-fzy-native-nvim;
        extraConfig = ''
          telescope.load_extension "fzy_native"
        '';
      };
      # }}}

      # Next-up {{{
      # Better mark handling and display
      # "bootleq/ShowMarks" = { };
      # git integration for vim, need to watch screencasts. Have activated for now
      # for commit wrapping.
      vim-fugitive = {
        enable = true;
        source = vimPlugins.vim-fugitive;
      };
      # vim-based git viewer, needs fugitive repo viewer/browser
      # "gregsexton/gitv" = { };
      # Align elements on neighbouring lines, e.g. quickly build text 'tables'
      # "godlygeek/tabular" = { };
      # Lookup docs on word under cursor, configurable lookup command - this would
      # be extremely useful if I write PageUp
      # "Keithbsmiley/investigate.vim" = { };
      # }}}

      # Some transitive dependency specs {{{
      # "Shados/facade.nvim" = {
      #   dependencies = [
      #     "Shados/earthshine"
      #   ];
      # };
      # }}}
    };
  };
}
