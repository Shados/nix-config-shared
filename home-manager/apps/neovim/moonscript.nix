{ config, lib, pkgs, ... }:
let
  inherit (pkgs.luajitPackages) moonpick-vim;
  # For dev purposes
  # moonpick-vim = pkgs.luajitPackages.moonpick-vim.overrideAttrs(oa: {
  #   src = /home/shados/technotheca/artifacts/media/software/lua/moonpick-vim;
  # });
in
with lib;
{
  sn.programs.neovim.pluginRegistry = with pkgs; {
    moonpick-vim = {
      enable = true;
      dependencies = singleton "ale";
      binDeps = [ moonpick-vim luajitPackages.moonscript ];
      source = moonpick-vim.src;
      # For dev purposes
      # dir = "/home/shados/technotheca/artifacts/media/software/lua/moonpick-vim";
      luaDeps = ps: with ps; [
        moonpick
      ];
      extraConfig = ''
        register_ale_tool ale_linters, "moon", "moonpick"
      '';
    };
  };
}
