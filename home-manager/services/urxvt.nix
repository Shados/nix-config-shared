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
          pasta = pkgs.writeTextFile rec {
            name = "pasta";
            destination = "/lib/urxvt/perl/${name}";
            text = ''
              #! /usr/bin/env perl -w
              # Author:   Aaron Caffrey
              # Website:  https://github.com/wifiextender/urxvt-pasta
              # License:  GPLv3

              # Usage: put the following lines in your .Xdefaults/.Xresources:
              # URxvt.perl-ext-common           : selection-to-clipboard,pasta
              # URxvt.keysym.Control-Shift-V    : perl:pasta:paste

              use strict;

              sub on_user_command {
                my ($self, $cmd) = @_;
                if ($cmd eq "pasta:paste") {
                  $self->selection_request (urxvt::CurrentTime, 3);
                }
                ()
              }
            '';
          };
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
            sha256 = "sha256-gVPT27G6vVA9SiKuiYt4JLYikShvexCqlzptU7Rvumc=";
            extraPrefix = "";
          })
          # FIXME: remove this once I'm on nixpkgs including PR #249166
          (super.fetchpatch {
            name = "perl538-locale-c.patch";
            url = "https://github.com/exg/rxvt-unicode/commit/16634bc8dd5fc4af62faf899687dfa8f27768d15.patch";
            excludes = [ "Changes" ];
            sha256 = "sha256-JVqzYi3tcWIN2j5JByZSztImKqbbbB3lnfAwUXrumHM=";
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
      if systemctl --user is-active urxvtd.service; then
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
