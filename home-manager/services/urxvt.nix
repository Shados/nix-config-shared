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
    programs.urxvt = {
      package = pkgs.callPackage ../pkgs/urxvt/wrapper.nix {
        inherit (pkgs.perlPackages) makePerlPath;
        rxvt_unicode = pkgs.rxvt-unicode-unwrapped-emoji;
        plugins = [
          pkgs.urxvt_autocomplete_all_the_things
          pkgs.urxvt_perl
          pkgs.urxvt_perls
          pkgs.urxvt_tabbedex
          pkgs.urxvt_font_size
          pkgs.urxvt_theme_switch
          pkgs.urxvt_vtwheel
        ] ++ attrValues (filterAttrs (n: v: v != null) cfg.plugins);
      };
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
