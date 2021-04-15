{ config, lib, pkgs, ... }:
with lib;
let
  nvimCfg = config.sn.programs.neovim;
  plugCfg = nvimCfg.pluginRegistry;
  mkIfGruvbox = mkIf plugCfg.gruvbox.enable;
in
{
  sn.programs.neovim.pluginRegistry = {
    gruvbox = {
      extraConfig = ''
        set "background", "dark"
        cmd 'colorscheme gruvbox'

        g["gruvbox_contrast_dark"] = "hard"
        g["gruvbox_number_column"] = "bg1"

        -- gruvbox cursor highlight in search fixes
        map "n", "[oh", ":call gruvbox:hls_show()<CR>", {noremap: true}
        map "n", "]oh", ":call gruvbox:hls_hide()<CR>", {noremap: true}
        map "n", "coh", ":call gruvbox:hls_toggle()<CR>", {noremap: true}

        map "n", "*", ':let @/ = ""<CR>:call gruvbox#hls_show()<CR>*', {noremap: true}
        map "n", "/", ':let @/ = ""<CR>:call gruvbox#hls_show()<CR>/', {noremap: true}
        map "n", "?", ':let @/ = ""<CR>:call gruvbox#hls_show()<CR>?', {noremap: true}

        " Tweak the colour of the visible tab/space characters
        cmd 'highlight Whitespace guifg=#857767'
      '';
    };
    lightline-vim.extraConfig = mkIfGruvbox (mkAfter ''
      cmd "let g:lightline.colorscheme = 'gruvbox'"
    '');
    vim-buffet.extraConfig = mkIfGruvbox ''
      -- Customize vim-workspace colours based on gruvbox colours
      cmd [[
        function g:WorkspaceSetCustomColors()
          highlight WorkspaceBufferCurrentDefault guibg=#a89984 guifg=#282828
          highlight WorkspaceBufferActiveDefault guibg=#504945 guifg=#a89984
          highlight WorkspaceBufferHiddenDefault guibg=#3c3836 guifg=#a89984
          highlight WorkspaceBufferTruncDefault guibg=#3c3836 guifg=#b16286
          highlight WorkspaceTabCurrentDefault guibg=#689d6a guifg=#282828
          highlight WorkspaceTabHiddenDefault guibg=#458588 guifg=#282828
          highlight WorkspaceFillDefault guibg=#3c3836 guifg=#3c3836
          highlight WorkspaceIconDefault guibg=#3c3836 guifg=#3c3836
        endfunction
      ]]
    '';
    "Yggdroot/indentLine".extraConfig = mkIfGruvbox ''
      -- Set the indent line's colour to a subtle, faded grey-brown
      g["indentLine_color_gui"] = '#474038'
    '';
    ale.extraConfig = mkIfGruvbox ''
      -- Gutter colours that work well with gruvbox
      cmd [[
        highlight ALEErrorSign guibg=#9d0006
        highlight ALEWarningSign guibg=#9d0006
        highlight ALESignColumnWithErrors guibg=#9d0006
      ]]
    '';
  };
}
