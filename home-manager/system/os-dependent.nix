{ config, lib, pkgs, ... }:
let
  prefixEnvPath = varName: elems: (lib.concatStringsSep ":" elems) + "\${${varName}:+:}\$${varName}";
in
{
  config = lib.mkMerge [
    (lib.mkIf (config.sn.os == "darwin") {
      home.sessionVariables = {
        NIX_PATH = prefixEnvPath "NIX_PATH" [
          "nixpkgs=/nix/var/nix/profiles/per-user/${config.home.username}/channels/nixpkgs"
          "darwin-config=$HOME/.config/darwin-config/configuration.nix"
          "nixos-config=$HOME/.config/nixos-config/configuration.nix"
          "$HOME/.nix-defexpr/channels"
          "/nix/var/nix/profiles/per-user/${config.home.username}/channels"
        ];
        PATH = prefixEnvPath "PATH" [
          "$HOME/.rvm/bin" # TODO manage rvm with Nix?
          "${config.home.profileDirectory}/bin"
          "/nix/var/nix/profiles/default/bin"
        ];
      };
      sn.programs.neovim.extraConfig = ''
        g.netrw_browsex_viewer = "/usr/bin/open -a \"/Applications/Google Chrome.app\""
      '';
      # These need to be in both .zshrc and .zprofile to avoid path_helper bullshit
      # See https://gist.github.com/Linerre/f11ad4a6a934dcf01ee8415c9457e7b2
      programs.zsh = let
        pathSetup = ''
          export PATH="${prefixEnvPath "PATH" [
            "$HOME/.rvm/bin" # TODO manage rvm with Nix?
            "$HOME/.nix-profile/bin"
            "/nix/var/nix/profiles/default/bin"
          ]}";
          export MANPATH="$HOME/.nix-profile/share/man:$(manpath 2>/dev/null)";
          typeset -U PATH path
        '';
      in {
        initExtra = pathSetup;
        profileExtra = pathSetup;
      };
    })
    (lib.mkIf (config.sn.os == "nixos") {
      xsession.initExtra = ''
        # GDK_PIXBUF_MODULE_FILE is needed for GTK to render SVG; requires NixOS
        # conf setting this variable
        ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd GDK_PIXBUF_MODULE_FILE GDK_DPI_SCALE
      '';
    })
    (lib.mkIf (config.sn.os != "darwin") {
      home.sessionVariables = {
        # Correct manpage search path to prefer home-manager man pages over system-wide ones
        MANPATH = "$HOME/.nix-profile/share/man:$(manpath)";
      };
      home.packages = with pkgs; let
        product-sans = (runCommandNoCC "font-product-sans" {
          src = lib.cleanSourceWith {
            filter = name: _: (lib.hasSuffix ".ttf" (baseNameOf (toString name)));
            src = pkgs.fetchzip {
              url = "https://befonts.com/wp-content/uploads/2018/08/product-sans.zip";
              sha256 = "sha256-PF2n4d9+t1vscpCRWZ0CR3X0XBefzL9BAkLHoqWFZR4=";
              stripRoot = false;
            };
          };
        } ''
          mkdir -p $out/share/fonts/truetype/ProductSans/
          cp -r $src/* $out/share/fonts/truetype/ProductSans/
        '');
      in [
        mph_2b_damase
        # noto-fonts noto-fonts-cjk noto-fonts-emoji
        unifont unifont_upper
        (nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })
        product-sans
      ];
      fonts.fontconfig.enable = true;
      xdg.mimeApps.enable = true;
      xdg.configFile."mimeapps.list".force = true;
    })
  ];
}
