{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.sn.programs.neovim;

  langPkgDefs = with pkgs; {
    bash = {
      minimal = [
        shellcheck
        shfmt
      ];
      full = [
        bash-language-server
      ];
    };
    c = {
      minimal = [
      ];
      full = [
        clangd
      ];
    };
    css = {
      minimal = [
      ];
      full = [
        vscode-css-langserver
      ];
    };
    elm = with elmPackages; {
      minimal = [
        ["elm-make" elm] # elm-make for linting
        elm-format
      ];
      full = [
      ];
    };
    go = {
      minimal = [
        ["gofmt" go]
        gocode
      ];
      full = [
        go-langserver
      ];
    };
    haskell = {
      minimal = [
      ];
      full = [
        # use hie-wrapper to launch correct HIE binary for project's GHC?
        ["hie-wrapper" hies]
      ];
    };
    lua = with lua52Packages; {
      minimal = [
        ["luac" lua]
        luacheck
      ];
      full = [
      ];
    };
    python = with python36Packages; {
      minimal = [
        flake8 # Linting/static checking
        black # Strict style auto-formatting
        isort # Auto-sorts import statements
      ];
      full = [
        # TODO need a solid solution for managing globally-available Python
        # modules before I can add optional deps properly?...
        ["pyls" python-language-server]
        cython # For Cython linting
      ];
    };
    ruby = {
      minimal = [
      ];
      full = [
        solargraph
      ];
    };
    rust = {
      minimal = [
        ["racer" rustracer]
      ];
      full = [
        ["rls" rustup]
      ];
    };
    vim = {
      minimal = [
        ["vint" vim-vint] # Vim linter
      ];
      full = [
      ];
    };
  };

  getPkgName = pkg: let
      parse = drv: (builtins.parseDrvName drv).name;
    in if isString pkg then
      parse pkg
    else parse pkg.name;


  concatOxford = stringList: let
      commaSeparated = concatStringSep ", " (init stringList);
      oxfordComma = ", and " (last stringList);
    in commaSeparated + oxfordComma;
  concatMapOxford = fn: stringList: concatOxford (map fn stringList);

  langSupportType = types.enum [ "none" "minimal" "full" ];

  mkLangSupportOpt = lang: minPkgs: fullPkgs: let
      mkPkgDesc = pkg: if (isList pkg) then
          "`${elemAt pkg 0}` (${getPkgName (elemAt pkg 1)})"
        else
          "`${getPkgName pkg}`";
      pkgDescriptions = pkgs: concatMapOxford (mkPkgDesc) pkgs;
    in mkOption {
      type = with types; langSupportType;
      default = cfg.defaultLanguageSupport;
      description = ''
        The level of native programs to install into the system profile for
        ${lang} support in neovim.

        Options:
        - none: nothing will be installed
        - minimal: ${pkgDescriptions minPkgs}
        - full: minimal plus ${pkgDescriptions fullPkgs}
      '';
    };

  langSupportOpts = langPkgs: let
      mapLangPkgs = lang: pkgs: mkLangSupportOpt lang pkgs.minimal pkgs.full;
    in mapAttrs (mapLangPkgs) langPkgs;

  mkLangPkgList = lang: pkgs: let
      stripLangPkgBinName = langPkg: if (isList langPkg) then
          elemAt langPkg 1
        else
          langPkg;
      minPkgs = map (stripLangPkgBinName) pkgs.minimal;
      fullPkgs = map (stripLangPkgBinName) pkgs.full;
      langSupport = cfg.languageSupport.${lang};
    in if (langSupport == "none") then
      []
    else if (langSupport == "minimal") then
      minPkgs
    else
      minPkgs ++ fullPkgs;
in
{
  options = {
    sn.programs.neovim = {
      defaultLanguageSupport = mkOption {
        type = with types; langSupportType;
        default = "none";
        description = ''
          The default level of per-language support packages to install Can be
          overridden on a per-language basis using the options under
          `${toString cfg}.languageSupport`.
        '';
      };
      languageSupport = langSupportOpts langPkgDefs;
    };
  };

  config = mkMerge [
    {
      environment.systemPackages = let
          pkgToString = pkg: getPkgName pkg;
          languageSupportPackages = concatLists (mapAttrsToList (mkLangPkgList) langPkgDefs);
        in with pkgs; [
          neovim
          neovim-remote
          silver-searcher # `ag`
          universal-ctags
        ] ++ languageSupportPackages;

      # cachix caches
      nix = {
        binaryCaches = [
          # Haskell IDE Engine
          "https://hie-nix.cachix.org"
        ];
        binaryCachePublicKeys = [
          "hie-nix.cachix.org-1:EjBSHzF6VmDnzqlldGXbi0RM3HdjfTU3yDRi9Pd0jTY="
        ];
      };
      nixpkgs.overlays = [
        (let
          rev = "96af698f0cfefdb4c3375fc199374856b88978dc";
          sha256 = "1ar0h12ysh9wnkgnvhz891lvis6x9s8w3shaakfdkamxvji868qa";
          # Get sha256 with e.g.: `nix-prefetch-url --unpack https://github.com/domenkozar/hie-nix/archive/96af698f0cfefdb4c3375fc199374856b88978dc.tar.gz`
        in self: super: {
          hies = (import (builtins.fetchTarball {
            url = "https://github.com/domenkozar/hie-nix/archive/${rev}.tar.gz";
            inherit sha256;
          }) {}).hies;
        })
      ];
    }
    (mkIf (cfg.languageSupport.python != "none") {
      sn.programs.flake8 = {
        enable = true;
        plugins = with pkgs.python36Packages; [
          flake8-bugbear
        ];
      };
    })
  ];
}
