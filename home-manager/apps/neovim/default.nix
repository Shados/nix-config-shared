{
  config,
  lib,
  pkgs,
  ...
}:
# TODO universal ctags
with lib;
let
  nvimCfg = config.sn.programs.neovim;
  plugCfg = nvimCfg.pluginRegistry;
  inherit (pkgs) vimPlugins;
in
{
  imports = [
    ./moonscript.nix
    # ./neuron.nix
    ./python.nix
  ];
  home.packages = with pkgs; [
    nixfmt-rfc-style
  ];
  sn.programs.neovim = {
    mergePlugins = true;
    extraBinPackages = with pkgs; [
      xdg-utils # xdg-open
    ];
    files."autoload/snlib/list.vim".source = ./nvim-files/autoload/snlib/list.vim;
    # TODO replace remaining python plugins:
    # - denite (only starts python host on use)
    # - gundo (only starts python host on use)
    pluginRegistry = {
      # Linting & LSP setup
      nvim-lspconfig = mkMerge [
        {
          enable = true;
          source = vimPlugins.nvim-lspconfig;
          after = [
            "ale" # As we modify some ALE settings :O
          ];
          extraConfig = ''
            lspconfig = require "lspconfig"
            lsp_on_attach = (client, bufnr) ->
              -- bo.omnifunc = "v:lua.vim.lsp.omnifunc"
              local_map = (...) -> api.nvim_buf_set_keymap bufnr, ...

              -- Some mappings
              local_map "n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", { noremap: true, silent: true }
              local_map "n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { noremap: true, silent: true }
              local_map "n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", { noremap: true, silent: true }
              local_map "n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", { noremap: true, silent: true }
              local_map "n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", { noremap: true, silent: true }
              local_map "n", "<leader>wa", "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", { noremap: true, silent: true }
              local_map "n", "<leader>wr", "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>", { noremap: true, silent: true }
              local_map "n", "<leader>wl", "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>", { noremap: true, silent: true }
              local_map "n", "<leader>D", "<cmd>lua vim.lsp.buf.type_definition()<CR>", { noremap: true, silent: true }
              local_map "n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", { noremap: true, silent: true }
              local_map "n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", { noremap: true, silent: true }
              local_map "n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", { noremap: true, silent: true }
              local_map "n", "<leader>e", "<cmd>lua vim.diagnostic.show_line_diagnostics()<CR>", { noremap: true, silent: true }
              local_map "n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>", { noremap: true, silent: true }
              local_map "n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>", { noremap: true, silent: true }
              local_map "n", "<leader>q", "<cmd>lua vim.diagnostic.set_loclist()<CR>", { noremap: true, silent: true }

              -- Set some keybinds conditional on server capabilities
              if client.server_capabilities.documentFormattingProvider
                local_map "n", "<leader>F", "<cmd>lua vim.lsp.buf.format()<CR>", { noremap: true, silent: true }
              if client.server_capabilities.documentRangeFormattingProvider
                local_map "v", "<leader>F", "<cmd>lua vim.lsp.buf.format()<CR>", { noremap: true, silent: true }

              -- Set autocommands conditional on server_capabilities
              if client.server_capabilities.documentHighlightProvider
                -- TODO set these & other LSP HL groups in my theming files
                lsp_reference_hl = { cterm: { bold: true }, ctermbg: "red", bg: "LightYellow" }
                vim.api.nvim_set_hl 0, "LspReferenceRead", lsp_reference_hl
                vim.api.nvim_set_hl 0, "LspReferenceText", lsp_reference_hl
                vim.api.nvim_set_hl 0, "LspReferenceWrite", lsp_reference_hl
                augroup "lsp_document_highlight", ((autocmd) ->
                  autocmd {"CursorHold"}, {
                    buffer: bufnr,
                    callback: -> vim.lsp.buf.document_highlight!
                  }
                  autocmd {"CursorMoved"}, {
                    buffer: bufnr,
                    callback: -> vim.lsp.buf.clear_references!
                  }),
                  { clear: true }
          '';
        }
        # Bash/Shell
        {
          extraConfig = mkAfter ''
            lspconfig.bashls.setup
              on_attach: lsp_on_attach
            ale_linters.sh = {}
          '';
          binDeps = [
            pkgs.nodePackages.bash-language-server
          ];
        }
        # CSS
        {
          extraConfig = mkAfter ''
            lspconfig.cssls.setup
              on_attach: lsp_on_attach
            ale_linters.css = {}
            ale_linters.less = {}
            ale_linters.sass = {}
            ale_linters.scss = {}
          '';
          binDeps = [
            pkgs.nodePackages.vscode-langservers-extracted
          ];
        }
        # Go
        {
          extraConfig = mkAfter ''
            lspconfig.gopls.setup
              on_attach: lsp_on_attach
            ale_linters.go = {}
          '';
          binDeps = [
            pkgs.gopls
          ];
        }
        # Nix
        {
          extraConfig = mkAfter ''
            lspconfig.nil_ls.setup
              on_attach: lsp_on_attach
              settings:
                nil:
                  formatting:
                    command: { "nixfmt" }
            nix_fixer_cb = (event) -> (autocmd) ->
              autocmd {"BufWritePre"}, {
                buffer: event.buf,
                callback: -> vim.lsp.buf.format!
              }
            vim.api.nvim_create_autocmd {"FileType"}, {
              group: "vimrc",
              pattern: { "nix" },
              callback: (event) -> augroup "Fixers", (nix_fixer_cb event), { clear: true }
            }
            ale_linters.nix = {}
          '';
          binDeps = [
            pkgs.nil
            pkgs.nixfmt-rfc-style
          ];
        }
        # # OCaml
        # { extraConfig = mkAfter ''
        #     lspconfig.ocamllsp.setup
        #       on_attach: lsp_on_attach
        #     ale_linters.ocaml = {}
        #   '';
        #   binDeps = [
        #     pkgs.ocamlPackages_latest.ocaml-lsp
        #   ];
        # }
        # Ruby
        {
          extraConfig = mkAfter ''
            lspconfig.solargraph.setup
              on_attach: lsp_on_attach
            ale_linters.ruby = {}
          '';
          binDeps = [
            pkgs.solargraph
          ];
        }
        # Rust
        # Rust tooling inevitably ends up being very project specific, so we
        # don't add a global rust-analyzer, instead add it to the path in
        # shell.nix files per-project, with direnv to make it convenient
        {
          extraConfig = mkAfter ''
            if (fn.executable "cargo") != 0
              lspconfig.rust_analyzer.setup
                on_attach: lsp_on_attach
              ale_fixers.rust = {}
              ale_linters.rust = {}
              rust_fixer_cb = (event) -> (autocmd) ->
                autocmd {"BufWritePre"}, {
                  buffer: event.buf,
                  callback: -> vim.lsp.buf.format!
                }
              vim.api.nvim_create_autocmd {"FileType"}, {
                group: "vimrc",
                pattern: { "rust" },
                callback: (event) -> augroup "Fixers", (rust_fixer_cb event), { clear: true }
              }
          '';
        }
        # TypeScript/JavaScript
        # Project-specific tooling provided by direnv+Nix
        {
          extraConfig = mkAfter ''
            if (fn.executable "typescript-language-server") != 0
              lspconfig.ts_ls.setup
                on_attach: lsp_on_attach
          '';
        }
      ];

      ale =
        with pkgs;
        mkMerge [
          # ALE config {{{
          # { extraConfig = mkAfter ''
          #     -- Elm
          #     call s:register_ale_tool(g:ale_linters, 'elm', 'elm-make')
          #     call s:register_ale_tool(g:ale_fixers, 'elm', 'elm-format')
          #     autocmd vimrc FileType elm let b:ale_fix_on_save = 1
          #   '';
          #   binDeps = with elmPackages; [
          #     elm
          #     elm-format
          #   ];
          # }
          {
            extraConfig = mkAfter ''
              -- Go
              register_ale_tool(ale_fixers, "go", "gofmt")
              vim.api.nvim_create_autocmd {"FileType"}, {
                group: "vimrc",
                pattern: { "go" },
                command: "let b:ale_fix_on_save = 1"
              }
            '';
            binDeps = [
              go
            ];
          }
          {
            extraConfig = mkAfter ''
              -- Javascript
              register_ale_tool(ale_linters, "javascript", "eslint")
              register_ale_tool(ale_linters, "javascript", "jshint")
            '';
            binDeps = with pkgs.nodePackages; [
              eslint
              jshint
            ];
          }
          {
            extraConfig = mkAfter ''
              -- Lua
              register_ale_tool(ale_linters, "lua", "luac")
              register_ale_tool(ale_linters, "lua", "luacheck")
            '';
            binDeps = [
              lua5_1
              luajitPackages.luacheck
            ];
          }
          {
            extraConfig = mkAfter ''
              -- OCaml
              register_ale_tool(ale_fixers, "ocaml", "ocamlformat")
              vim.api.nvim_create_autocmd {"FileType"}, {
                group: "vimrc",
                pattern: { "ocaml" },
                command: "let b:ale_fix_on_save = 1"
              }
            '';
            binDeps = [
              ocamlformat
            ];
          }
          {
            extraConfig = mkAfter ''
              -- Perl
              register_ale_tool(ale_linters, "perl", "perlcritic")
              register_ale_tool(ale_fixers, "perl", "perltidy")
              vim.api.nvim_create_autocmd {"FileType"}, {
                group: "vimrc",
                pattern: { "perl" },
                command: "let b:ale_fix_on_save = 1"
              }
            '';
            binDeps = with perlPackages; [
              PerlTidy
              PerlCritic
            ];
          }
          {
            extraConfig = mkAfter ''
              -- C/C++
              register_ale_tool(ale_fixers, "c", "cppcheck")
              register_ale_tool(ale_fixers, "c", "clang-tidy", "clangtidy")
            '';
            binDeps = [
              cppcheck
              clang-tools
            ];
          }
          {
            extraConfig = mkAfter ''
              -- Elixir
              if (fn.executable "mix") != 0
                register_ale_tool(ale_linters, "elixir", "credo")
                register_ale_tool(ale_linters, "elixir", "dialyxir")
                register_ale_tool(ale_linters, "elixir", "mix")
                register_ale_tool(ale_fixers, "elixir", "mix_format")
                vim.api.nvim_create_autocmd {"FileType"}, {
                  group: "vimrc",
                  pattern: { "elixir" },
                  command: "let b:ale_fix_on_save = 1"
                }
            '';
            # Use per-project binaries
            binDeps = [ ];
          }
          {
            extraConfig = mkAfter ''
              -- TypeScript/JS
              if (fn.executable "prettier") != 0
                register_ale_tool(ale_fixers, "typescript", "prettier")
                register_ale_tool(ale_fixers, "javascript", "prettier")
                vim.api.nvim_create_autocmd {"FileType"}, {
                  group: "vimrc",
                  pattern: { "typescript", "javascript" },
                  command: "let b:ale_fix_on_save = 1"
                }
            '';
            # Use per-project binaries
            binDeps = [ ];
          }
          # TODO LaTeX (and/or markdown) prose linting?
          # }}}
        ];

      # Language support and syntax highlighting {{{
      # vim-markdown-composer = {
      #   enable = true;
      #   extraConfig = ''
      #     g.markdown_composer_autostart = 0
      #   '';
      # };
      vim-erlang-runtime = {
        enable = true;
        source = vimPlugins.vim-erlang-runtime;
      };
      vim-erlang-compiler = {
        enable = true;
        source = vimPlugins.vim-erlang-compiler;
      };
      vim-erlang-omnicomplete = {
        enable = true;
        source = vimPlugins.vim-erlang-omnicomplete;
      };
      vim-erlang-tags = {
        enable = true;
        source = vimPlugins.vim-erlang-tags;
      };
      vim-elixir = {
        enable = true;
        source = vimPlugins.vim-elixir;
      };
      # Ocaml
      rust-vim = {
        enable = true;
        source = vimPlugins.rust-vim;
      };
      # TODO re-enable and test
      # "lervag/vimtex" = {
      #   enable = true;
      #   for = "tex";
      #   binDeps = with pkgs; [
      #     neovim-remote
      #     zathura
      #   ];
      #   extraConfig = ''
      #     g.vimtex_compiler_progname = "${pkgs.neovim-remote}/bin/nvr"
      #     g.vimtex_compiler_method = "latexmk"
      #     g.vimtex_compiler_latexmk = {
      #       build_dir: "build"
      #     }
      #     g.vimtex_view_method = "zathura"
      #     g.vimtex_view_use_temp_files = 1
      #     g.vimtex_disable_recursive_main_file_detection = 1
      #     -- Just to prevent vim occasionally deciding we're using 'plaintex' for no
      #     -- apparent reason
      #     g.tex_flavor = "latex"
      #     -- Turn auto-writing on so we get more of a 'live' PDF preview
      #     vim.api.nvim_create_autocmd {"FileType"}, {
      #       group: "vimrc",
      #       pattern: { "tex" },
      #       command: "silent! AutoSaveToggle"
      #     }
      #     -- Turn off the horrific 'conceal' anti-feature; VIM is not a WYSIWYG editor FFS
      #     g.vimtex_syntax_conceal = {
      #       accents: 0
      #       greek: 0
      #       math_bounds: 0
      #       math_delimiters: 0
      #       math_super_sub: 0
      #       math_symbols: 0
      #       styles: 0
      #     }
      #     '';
      # };
      elm-vim = {
        enable = true;
        source = vimPlugins.elm-vim;
        extraConfig = ''
          -- Elm
          -- Set indent/tab for Elm files to 4 spaces
          vim.api.nvim_create_autocmd {"FileType"}, {
            group: "vimrc",
            pattern: { "elm" },
            command: "setlocal shiftwidth=4 softtabstop=4 tabstop=4"
          }
        '';
      };
      salt-vim = {
        enable = true;
        source = vimPlugins.salt-vim;
      };
      moonscript-vim = {
        enable = true;
        source = vimPlugins.moonscript-vim;
      };
      mediawiki-vim = {
        enable = true;
        source = vimPlugins.mediawiki-vim;
      };
      vim-qml = {
        enable = true;
        source = vimPlugins.vim-qml;
      };
      vim-ps1 = {
        enable = true;
        source = vimPlugins.vim-ps1;
        for = "ps1";
      };
      yuecheck-vim = {
        enable = true;
        dependencies = [ "ale" ];
        binDeps = with pkgs; [ lua52Packages.yuecheck-vim ];
        # dir = "/home/shados/technotheca/artifacts/media/software/lua/yuecheck-vim";
        source = pkgs.lua52Packages.yuecheck-vim.src;
        extraConfig = ''
          g.ale_yue_yuecheck_options = "-c"
          register_ale_tool(ale_linters, "yue", "yuecheck")
        '';
      };
      # }}}

      # General Extra Functionality {{{
      # Post and edit gists directly from vim
      # vim-gist = {
      #   enable = true;
      #   dependencies = [ "mattn/webapi-vim" ];
      #   extraConfig = ''
      #     -- vim-gist
      #     let g:gist_clip_command = 'xclip -selection clipboard'
      #     let g:gist_detect_filetype = 1
      #     let g:open_browser_after_post = 1
      #     let g:gist_browser_command = 'xdg-open %URL% &'
      #     let g:gist_show_privates = 1 -- show private posts with :Gist -l
      #     let g:gist_post_private = 1 -- default to private gists
      #   '';
      # };
      # Escape text in html doc with \he, \hu to unescape
      # "skwp/vim-html-escape" = { };
      # Buffer auto-writing, which I only want for specific project/file types
      vim-auto-save = {
        enable = true;
        source = vimPlugins.vim-auto-save;
        for = "tex";
      };
      # A vim plugin to help with writing vim plugins; most notably :PP acts as a
      # decent REPL
      vim-scriptease = {
        enable = true;
        source = vimPlugins.vim-scriptease;
      };
      # Integration with direnv
      direnv-vim = {
        enable = true;
        source = vimPlugins.direnv-vim;
      };
      # }}}
    };
  };
}
