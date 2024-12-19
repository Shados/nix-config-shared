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
      extraConfig = ''
        set "background", "dark"
        cmd 'colorscheme OceanicNext'
        statusline_base_highlights, statusline_highlights = do
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
          base_hi = { bg: colors.base01, fg: colors.white, style: "NONE" }
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
            base_hi,
            base_hi,
          }, {
            mode_highlight
            file_hi
            warning_hi,
            base_hi,
            fileinfo_hi
            base_hi
          }
      '';
    };
    # TODO change colour
    indent-blankline-nvim = {
      after = mkIfOceanic [ "oceanic-next" ];
      extraConfig = mkIfOceanic (mkBefore ''
        -- Set the indent line's colour to a subtle, faded grey
        cmd "highlight IblIndent guifg=#343d46 gui=nocombine"
      '');
    };
    ale.extraConfig = mkIfOceanic ''
      -- Gutter colours that match with oceanic-next
      cmd [[
        highlight ALEErrorSign guibg=#ec5f67
        highlight ALEWarningSign guibg=#ec5f67
        highlight ALESignColumnWithErrors guibg=#ec5f67
      ]]
    '';
    bufferline-nvim.extraConfig = mkIfOceanic (mkBefore ''
      bufferline_highlights = {
        -- Colour the background of the buffer bar
        fill: { bg: "#112029" }
        -- Colour the little vertical bar indicating the currently-active buffer
        indicator_selected: { fg: "#6699cc" }
      }
      bufferline_offset_highlight = "Normal"
    '');
  };
}
