# 1. Trigger lock via `loginctl lock-session`, or via logind's idle timeout
#    option. Can also trigger a Sleep event.
# 2. xss-lock and systemd-lock-handler both read the Lock/Sleep event:
#    - xss-lock starts the configured locker process. If on sleep, it can
#      pass the sleep-inhibiting file descriptor to this process, and the
#      wrapper ensures this is cleaned up within the wrapper if it exists (the
#      spawned locker will also need to clean it up, of course).
#    - systemd-lock-handler starts its `lock.target` systemd target, to
#      allow us to trigger systemd units off of locking (or sleeping). In the
#      sleep case, it will inhibit sleeping until `sleep.target` has been fully
#      started.
# 3. The user later unlocks the screen locker.
# 4. The xss-locker-wrapper script sees the locker has exited and runs
#    `loginctl unlock-session` to generate an Unlock event.
# 5. xss-lock sees this and will attempt to kill the locker script if it is
#    still around, but that shouldn't be relevant :). systemd-lock-handler sees
#    the event and starts the `unlock.target`.
# FIXME: `sleep.target` is never actually *stopped* after returning from
# sleep.
{ config, lib, pkgs, ... }:
let
  inherit (lib) mkIf mkDefault mkForce mkMerge;
in
{
  config = mkMerge [
    # Enable by default if using NixOS w/ graphical xorg setup
    (mkIf (config.sn.os == "nixos" && config.xsession.enable) {
      services.screen-locker.enable = mkDefault true;
    })

    # Openbox screen-lock keybind
    (mkIf (config.services.screen-locker.enable && config.xsession.windowManager.openbox.enable) {
      xsession.windowManager.openbox.keyboard.keybind."W-A-l" = lib.singleton { action = "execute"; command = "loginctl lock-session"; };
    })

    # Helper for wrapping lockers in xss-lock-compatible behaviour + configuring dpms
    (let
      inherit (lib) getExe;

      # TODO share with shared/home-manager/apps/openbox.nix ?
      unsetDpms = pkgs.writers.writeBashBin "unset-dpms" ''
        # Disable all DPMS timeouts, but ensure DPMS itself is enabled, so that
        # our screen locker can use it
        ${xset} s 0 0 s noblank s noexpose dpms 0 0 0 +dpms
      '';
      setDpms = pkgs.writers.writeBashBin "set-dpms" ''
        # Set the DPMS-off timeout to 15 seconds
        ${xset} dpms 0 0 15 +dpms
      '';
      xset = getExe pkgs.xorg.xset;
    in mkIf config.services.screen-locker.enable {
      lib.xss-locker-wrapper = pkgs.writeShellApplication {
        name = "xss-locker-wrapper";
        text = builtins.readFile ./xss-locker-wrapper.sh;
        runtimeInputs = with pkgs; [
          systemd jq
          setDpms unsetDpms
        ];
      };
    })

    # Modify upstream xss-lock config to use systemd-lock-handler, and make some other improvements
    (let
      inherit (lib) getExe';
    in mkIf config.services.screen-locker.enable {
      # Don't restart on home-manager activation if paths have changed
      # TODO somehow only restart if we're not currently locked?
      systemd.user.services.xss-lock.Unit.X-RestartIfChanged = false;
      systemd.user.services.xss-lock.Service.Slice = "session.slice";

      # We don't use xautolock
      services.screen-locker.xautolock.enable = mkDefault false;

      # We also don't use xset
      systemd.user.services.xss-lock.Service.ExecStartPre = mkForce (getExe' pkgs.coreutils "true");

      # Instead we use systemd-lock-handler
      # FIXME: Find a way to just enable the existing, packaged user file?
      systemd.user.services.systemd-lock-handler = {
        Unit = {
          Description = "Logind lock event to systemd target translation";
          Documentation = "https://sr.ht/~whynothugo/systemd-lock-handler";
          # Don't restart on home-manager activation if paths have changed
          X-RestartIfChanged = false;
        };

        Service = {
          ExecStart = "${pkgs.nur.repos.shados.systemd-lock-handler}/lib/systemd-lock-handler";
          Slice = "session.slice";
          Type = "notify";
        };

        Install = {
          WantedBy = [ "default.target" ];
        };
      };
      home.packages = with pkgs; [
        # We must add this to get the un/lock target files
        nur.repos.shados.systemd-lock-handler
        # Nice to have in the env
        xss-lock
      ];
      # TODO move hasUnitChanged into a more generic activation-script-env-setup type of thing?
      home.activation.schedule-unlock-only-restarts = let
        configHome = lib.removePrefix config.home.homeDirectory config.xdg.configHome;
        systemctl = lib.getExe' pkgs.systemd "systemctl";
      in lib.hm.dag.entryBetween [ "performServiceRestarts" ] [ "onFilesChange" "reloadSystemd" "initServiceRestartArray" ] ''
        # Returns success if it is changed, failure if it hasn't (or if we can't determine if it has or not)
        function hasUnitChanged {
          unit="$1"
          if [[ -v oldGenPath ]]; then
            local oldUnitsDir="$oldGenPath/home-files${configHome}/systemd/user"
            if [[ ! -e $oldUnitsDir ]]; then
              return 1
            fi
          fi

          local newUnitsDir="$newGenPath/home-files${configHome}/systemd/user"
          if [[ ! -e $newUnitsDir ]]; then
            return 1
          fi

          declare oldHash newHash
          oldHash=($(sha256sum "$oldUnitsDir/$unit"))
          newHash=($(sha256sum "$newUnitsDir/$unit"))
          [[ "$oldHash" != "$newHash" ]]
          return $?
        }

        if ! ${systemctl} --user is-active lock.target >/dev/null; then
          if hasUnitChanged "xss-lock.service"; then
            restartServices["xss-lock"]=1
          fi
        fi
      '';
    })

    # Handle running system-provided lock-power-switch, if it exists
    (mkIf config.services.screen-locker.enable (let
      inherit (lib) getExe';

      powerSwitchScript = "/run/current-system/sw/bin/lock-power-switch";
    in {
      systemd.user.services.power-switch-lock = {
        Service = {
          ExecStart = "${powerSwitchScript} lock";
          Slice = "session.slice";
          Type = "oneshot";
        };
        Unit = rec {
          Before = [ "lock.target" ]; PartOf = Before;
          # home-manager activation shouldn't touch the state of this
          RefuseManualStart = true;
          RefuseManualStop = true;
          ConditionPathExists = powerSwitchScript;
        };
        Install = {
          WantedBy = [ "lock.target" ];
        };
      };
      systemd.user.services.power-switch-unlock = {
        Service = {
          ExecStart = "${powerSwitchScript} unlock";
          Slice = "session.slice";
          Type = "oneshot";
        };
        Unit = rec {
          Before = [ "unlock.target" ]; PartOf = Before;
          # home-manager activation shouldn't touch the state of this
          RefuseManualStart = true;
          RefuseManualStop = true;
          ConditionPathExists = powerSwitchScript;
        };
        Install = {
          WantedBy = [ "unlock.target" ];
        };
      };
    }))
  ];
}
