{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.programs.urxvt;
in
{
  options = {
    programs.urxvt = {
      plugins = mkOption {
        type = with types; attrsOf (nullOr package);
        default = {
          default = null;
          selection-to-clipboard = null;
          config-reload = pkgs.nur.repos.shados.urxvt-config-reload;
        };
        description = ''
          Attribute set mapping perl-ext-common extension names to
          corresponding Nix derivations for said extensions (or null, if
          builtin), thus specifying the extensions to install and enable.
        '';
        example = {
          default = null;
          color-themes = null;
        };
      };
      font = mkOption {
        type = with types; str;
        default = "FantasqueSansM Nerd Font:style=Regular";
        description = ''
          XFT font name for urxvt to use.
        '';
      };
      fontSize = mkOption {
        type = with types; int;
        default = 10;
        description = ''
          XFT font size to use for urxvt.
        '';
      };
      daemon = mkOption {
        type = with types; bool;
        default = true;
        description = ''
          Whether or not to enable the urxvt daemon service.
        '';
      };
    };
  };
  config = mkIf cfg.enable {
    nixpkgs.overlays = singleton (self: super: {
      rxvt-unicode-unwrapped-truecolor-emoji = super.rxvt-unicode-unwrapped-emoji.overrideAttrs(oa: rec {
        name = "${pname}-${oa.version}";
        pname = "rxvt-unicode-unwrapped-truecolor";
        patches = oa.patches or [] ++ [
          (super.fetchpatch {
            name = "24-bit-color.patch";
            url = "https://aur.archlinux.org/cgit/aur.git/plain/24-bit-color.patch?h=rxvt-unicode-truecolor-wide-glyphs";
            sha256 = "sha256-HYBe2s4vVgiLnShaZmYps17sd46u9d7qp9xTPshsz4Q=";
            extraPrefix = "";
          })
          (super.fetchpatch {
            name = "7-bit-queries.patch";
            url = "https://aur.archlinux.org/cgit/aur.git/plain/7-bit-queries.patch?h=rxvt-unicode-truecolor-wide-glyphs";
            sha256 = "sha256-hnRfQc4jPiBrm06nJ3I7PHdypUc3jwnIfQV3uMYz+/Y=";
            extraPrefix = "";
          })
        ];
        configureFlags = oa.configureFlags or [] ++ [
          "--enable-24-bit-color"
        ];
      });
    });
    programs.urxvt = {
      package = pkgs.rxvt-unicode.override(oa: {
        rxvt-unicode-unwrapped = pkgs.rxvt-unicode-unwrapped-truecolor-emoji;
        configure = { availablePlugins, ... }: {
          plugins = with availablePlugins; [
            autocomplete-all-the-things
            perl
            perls
            tabbedex
            font-size
            theme-switch
            vtwheel
          ] ++ attrValues (filterAttrs (n: v: v != null) cfg.plugins);
        };
      });
      fonts = [
        "xft:${cfg.font}:size=${toString cfg.fontSize}:antialias=true"
      ];
      keybindings = {
        "Control-Shift-V" = "perl:pasta:paste";
      };
      extraConfig = {
        perl-ext-common = concatStringsSep "," (attrNames cfg.plugins);
        # TODO make it accept sub-options like this
        # matcher.button = 1;
      };
    };
    home.file.${config.xresources.path}.onChange = optionalString cfg.daemon ''
      if systemctl --user is-active urxvtd.service 2>/dev/null; then
        systemctl --user reload urxvtd.service
      fi
    '';
    systemd.user.services = mkIf cfg.daemon {
      urxvtd = {
        Unit = {
          Description = "Urxvt Terminal Daemon";
          Documentation = [ "man:urxvtd(1)" "man:urxvt(1)" ];
          # Avoid killing active terminals; newer urxvtc versions can generally
          # talk to older urxvtd instances anyway
          X-RestartIfChanged = false;
        };

        # TODO prefer reload over restart when updating? are newer clients
        # backwards-compatible with older daemons?
        Service = {
          ExecStart = "${cfg.package}/bin/urxvtd -q -m";
          ExecReload = mkIf (cfg.plugins ? config-reload)
            "${pkgs.utillinux}/bin/kill -HUP $MAINPID";
          Restart = "always";
        };

        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };
  };
}
