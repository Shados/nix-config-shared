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
    cmd 'hi Normal guifg=#c0c5ce'
  '';
  sn.programs.neovim.pluginRegistry = {
    oceanic-next = {
      before = [
        "famiu/feline.nvim"
      ];
      extraConfig = ''
        set "background", "dark"
        cmd 'colorscheme OceanicNext'
        statusline_highlights = do
          statusline_highlights
          colors =
            base00: '#1b2b34'
            base01: '#343d46'
            base02: '#4f5b66'
            base03: '#65737e'
            base04: '#a7adba'
            base05: '#c0c5ce'
            base06: '#cdd3de'
            base07: '#d8dee9'
            red: '#ec5f67'
            orange: '#f99157'
            yellow: '#fac863'
            green: '#99c794'
            cyan: '#62b3b2'
            blue: '#6699cc'
            purple: '#c594c5'
            brown: '#ab7967'
            white: '#ffffff'
          mode_colors =
            NORMAL: {colors.white, colors.blue}
            ['OP-PENDING']: {colors.base01, colors.green}
            INSERT: {colors.base01, colors.red}
            VISUAL: {colors.base01, colors.cyan}
            ['V-LINE']: {colors.base01, colors.cyan}
            ['V-BLOCK']: {colors.base01, colors.cyan}
            REPLACE: {colors.white, colors.purple}
            ENTER: {colors.base01, colors.yellow}
            MORE: {colors.base01, colors.yellow}
            SELECT: {colors.base01, colors.orange}
            COMMAND: {colors.base01, colors.green}
            SHELL: {colors.base01, colors.green}
            TERM: {colors.base01, colors.green}
            NONE: {colors.base01, colors.purple}
          base_hi = { bg: colors.base01, fg: colors.white }
          file_hi = { bg: colors.base03, fg: colors.white }
          fileinfo_hi = file_hi
          warning_hi = { bg: colors.yellow, fg: colors.base01 }
          mode_highlight = (statusline_winid) ->
            if is_active_statusline statusline_winid
              {fg, bg} = mode_colors[sl.get_mode_str!]
              { :fg, :bg }
            else
              base_hi

          {
            mode_highlight
            file_hi
            warning_hi,
            base_hi,
            fileinfo_hi
            base_hi
          }
      '';
    };
    vim-buffet.extraConfig = mkIfOceanic ''
      -- Customize vim-workspace colours based on oceanic-next colours
      cmd [[
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
    "lukas-reineke/indent-blankline.nvim" = {
      after = mkIfOceanic [ "oceanic-next" ]; # Ensure 'colorscheme' is applied first, or it resets the highlight we set here
      extraConfig = mkIfOceanic ''
        -- Set the indent line's colour to a subtle, faded grey
        cmd "highlight IndentBlanklineChar guifg=#343d46 gui=nocombine"
      '';
    };
    ale.extraConfig = mkIfOceanic ''
      -- Gutter colours that match with oceanic-next
      cmd [[
        highlight ALEErrorSign guibg=#ec5f67
        highlight ALEWarningSign guibg=#ec5f67
        highlight ALESignColumnWithErrors guibg=#ec5f67
      ]]
    '';
  };
}
