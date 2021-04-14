{ config, lib, pkgs, ... }:
with lib;
let
  nvimCfg = config.sn.programs.neovim;
  plugCfg = nvimCfg.pluginRegistry;
  mkIfOceanic = mkIf plugCfg.oceanic-next.enable;
in
{
  sn.programs.neovim.extraConfig = mkAfter ''
    -- Interim fix for https://github.com/mhartington/oceanic-next/issues/95
    vim.api.nvim_command 'hi Normal guifg=#c0c5ce'
  '';
  sn.programs.neovim.pluginRegistry = {
    oceanic-next = {
      extraConfig = ''
        vim.api.nvim_set_option "background", "dark"
        vim.api.nvim_command 'colorscheme OceanicNext'
      '';
    };
    # TODO figure out why I can't just mkIf the whole block, or even mapAttrs mkIf them...
    # I can mkIf at any level beneath the pluginRegistry.<pluginName> level...
    lightline-vim.extraConfig = mkIfOceanic (mkAfter ''
      vim.api.nvim_command "let g:lightline.colorscheme = 'oceanicnext'"
    '');
    vim-buffet.extraConfig = mkIfOceanic ''
      -- Customize vim-workspace colours based on oceanic-next colours
      vim.api.nvim_command [[
        function g:WorkspaceSetCustomColors()
          highlight WorkspaceBufferCurrentDefault guibg=#65737e guifg=#cdd3de
          highlight WorkspaceBufferActiveDefault guibg=#4f5b66 guifg=#a7adba
          highlight WorkspaceBufferHiddenDefault guibg=#343d46 guifg=#a7adba
          highlight WorkspaceBufferTruncDefault guibg=#343d46 guifg=#c594c5
          highlight WorkspaceTabCurrentDefault guibg=#99c794 guifg=#343d46
          highlight WorkspaceTabHiddenDefault guibg=#6699cc guifg=#343d46
          highlight WorkspaceFillDefault guibg=#343d46 guifg=#343d46
          highlight WorkspaceIconDefault guibg=#343d46 guifg=#343d46
        endfunction
      ]]
    '';
    # TODO change colour
    "Yggdroot/indentLine".extraConfig = mkIfOceanic ''
      -- Set the indent line's colour to a subtle, faded grey
      vim.api.nvim_command [[
        let g:indentLine_color_gui = '#343d46'
      ]]
    '';
    ale.extraConfig = mkIfOceanic ''
      -- Gutter colours that match with oceanic-next
      vim.api.nvim_command [[
        highlight ALEErrorSign guibg=#ec5f67
        highlight ALEWarningSign guibg=#ec5f67
        highlight ALESignColumnWithErrors guibg=#ec5f67
      ]]
    '';
  };
}
