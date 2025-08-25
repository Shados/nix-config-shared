{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkAfter mkBefore;
  prefixEnvPath = varName: elems: (lib.concatStringsSep ":" elems) + "\${${varName}:+:}\$${varName}";
in
{
  config = lib.mkMerge [
    (lib.mkIf (config.sn.os == "darwin") {
      home.sessionPath = mkBefore [
        "${config.home.profileDirectory}/bin"
        "/nix/var/nix/profiles/default/bin"
      ];
      sn.programs.neovim.extraConfig = ''
        g.netrw_browsex_viewer = "/usr/bin/open -a \"/Applications/Google Chrome.app\""
      '';
    })
    # Work-around MacOS' `path_helper` insanity
    (lib.mkIf (config.sn.os == "darwin") {
      # These need to be in both .zshrc and .zprofile to avoid path_helper bullshit
      # See https://gist.github.com/Linerre/f11ad4a6a934dcf01ee8415c9457e7b2
      # for details of the this clusterfuck
      programs.zsh = {
        # In load order:
        # 1. ~/.zshenv
        envExtra = mkAfter ''
          # Ensure PATH elements are unique by enforcing uniqueness constraint
          typeset -U PATH path
          # Save PATH for later restoration after `path_helper` munging
          typeset -a path_pre_munge=($path)

          # Similar setup for MANPATH
          typeset -T MANPATH manpath
          typeset -U MANPATH manpath
          MANPATH="${prefixEnvPath "MANPATH" [ "$HOME/.nix-profile/share/man" ]}";
          typeset -a manpath_pre_munge=($manpath)

          export PATH
          export MANPATH
        '';
        # 2. /etc/zprofile runs `path_helper` and messes with ordering
        # 3. ~/.zprofile restores my path setup, retaining anything *added* by
        # `path_helper` at the end
        profileExtra = mkBefore ''
          path=($path_pre_munge $path)
          manpath=($manpath_pre_munge $manpath)
        '';
      };
    })
    # Don't use the MacOS-provided ssh-agent, as it doesn't support e.g. FIDO2-backed keys
    (lib.mkIf (config.sn.os == "darwin") {
      launchd.agents.ssh-agent = {
        enable = true;
        config = {
          ProgramArguments = let
            sshPkg = if (config.programs.ssh.package) != null
              then config.programs.ssh.package
              else pkgs.openssh;
          in [
            "/bin/sh"
            "-c"
            "rm -f $SSH_AUTH_SOCK; exec ${lib.getExe' sshPkg "ssh-agent"} -D -a $SSH_AUTH_SOCK"
          ];
          KeepAlive = {
            Crashed = true;
            SuccessfulExit = false;
          };
          RunAtLoad = true;
        };
      };

      home.activation.ensureNoDefaultSSHAgent =
        lib.hm.dag.entryBefore [ "setupLaunchAgents" ] ''
          agent_pid=$(/bin/launchctl list | ${lib.getExe pkgs.ripgrep} 'com\.openssh\.ssh-agent' | ${lib.getExe' pkgs.coreutils "cut"} -f 1)
          if [[ $agent_pid != "-" ]]; then
            warnEcho "Disabling and stopping default MacOS ssh-agent..."
            run launchctl disable "gui/$(id -u)/com.openssh.ssh-agent"
            run launchctl kill SIGTERM "gui/$(id -u)/com.openssh.ssh-agent"
          fi
        '';
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
      home.packages =
        with pkgs;
        let
          product-sans = (
            runCommand "font-product-sans"
              {
                src = lib.cleanSourceWith {
                  filter = name: _: (lib.hasSuffix ".ttf" (baseNameOf (toString name)));
                  src = pkgs.fetchzip {
                    url = "https://befonts.com/wp-content/uploads/2018/08/product-sans.zip";
                    sha256 = "sha256-PF2n4d9+t1vscpCRWZ0CR3X0XBefzL9BAkLHoqWFZR4=";
                    stripRoot = false;
                  };
                };
              }
              ''
                mkdir -p $out/share/fonts/truetype/ProductSans/
                cp -r $src/* $out/share/fonts/truetype/ProductSans/
              ''
          );
        in
        [
          mph_2b_damase
          # noto-fonts noto-fonts-cjk noto-fonts-emoji
          unifont
          unifont_upper
          product-sans
        ];
      fonts.fontconfig.enable = true;
      xdg.mimeApps.enable = true;
      xdg.configFile."mimeapps.list".force = true;
    })
  ];
}
