{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
{
  # Python-support stuff
  sn.programs.flake8 = {
    enable = true;
    plugins = with pkgs.python3Packages; [
      # Provides some extra classes of exceptions; specifically we want
      # this for B950 for better compatibility with Black
      flake8-bugbear
      # TODO implement my own flake8 plugin to ignore E265 in nix-shell
      # shebang lines in Python scripts, so I don't need to litter .flake8
      # config files around with my scripts.
      # TODO assert python version of plugins matches that of flake8
    ];
    extraConfig = # dosini
      ''
        # vim: set ft=dosini :
        [flake8]
        max-complexity = 12

        # Black-compatible flake8 config
        max-line-length=80
        select = C,E,F,W,B,B950
        ignore =
          E501,E203,W503
          # This one is for nix-shell shebangs
          E265
      '';
  };
  xdg.configFile = {
    "isort.cfg".text = ''
      [isort]
      # Black-compatible isort config
      multi_line_output=3
      include_trailing_comma=true
      force_grid_wrap=0
      combine_as_imports=true
      line_length=88
    '';
  };
  sn.programs.neovim.pluginRegistry = with pkgs; {
    ale = {
      extraConfig = mkAfter ''
        -- Python
        register_ale_tool ale_linters, "python", "flake8"
        register_ale_tool ale_fixers, "python", "isort"

        -- Lets us disable the use of black on a per-project basis with an environment variable
        unless env["ALE_NO_BLACK"] and #env["ALE_NO_BLACK"] > 0
          register_ale_tool ale_fixers, "python", "black"
          vim.api.nvim_create_autocmd {"FileType"}, {
            group: "vimrc",
            pattern: { "python" },
            command: "let b:ale_fix_on_save = 1"
          }

        -- Use env-provided tooling
        g["ale_python_auto_pipenv"] = 1
        g["ale_python_auto_poetry"] = 1
        g["ale_python_auto_uv"] = 1

        -- Use custom flake8
        g["ale_python_flake8_use_global"] = 1

        -- Type checking via mypy
        register_ale_tool ale_linters, "python", "mypy"
        -- NOTE: mypy is pretty dependent on the project-specific python
        -- environment/setup, so we don't add it to bindeps -- we rely on
        -- per-project instance of it instead

        -- Cython linting
        register_ale_tool ale_linters, "cython", "cython"
      '';
      binDeps = with python3Packages; [
        flake8-configured # custom one, some config set later
        black
        isort
        cython
      ];
    };
  };
}
