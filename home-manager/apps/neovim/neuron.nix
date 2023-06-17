{ config, lib, pkgs, ... }:
let
  # TODO pin from github + use cachix cache for it?
  neuronPkg = pkgs.neuron-notes;
in
{
  home.packages = [
    neuronPkg
  ];
  sn.programs.neovim.pluginRegistry = {
    "oberblastmeister/neuron.nvim" = {
      enable = true;
      dependencies = [
        "nvim-lua/plenary.nvim"
        "nvim-telescope/telescope.nvim"
      ];
      binDeps = [
        neuronPkg # TODO this dep is huge, move this to hm config instead?
      ];
      extraConfig = ''
        neuron = require "neuron"
        neuron.setup {
          virtual_titles: false -- Re-enable once neuron.nvim#21 is resolved, I have issues I suspect relate to that
          mappings: true
          run: nil
          neuron_dir: vim.loop.fs_realpath (fn.expand "~/notes/zettelkasten")
          leader: "gz"
        }
      '';
    };
  };
}
