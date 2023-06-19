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
  inherit (lib) mkIf mkMerge singleton;
in
{
  config = mkIf (config.sn.os == "nixos" && config.xsession.enable) (mkMerge [
    (let
      # locker = mkXSSLocker "/run/wrappers/bin/slock";
      # locker = mkXSSLocker "${pkgs.xsecurelock}/bin/xsecurelock";
      locker = mkXSSLocker (pkgs.writers.writeBash "xsecurelock-shados" ''
        export XSECURELOCK_AUTH_TIMEOUT=30
        export XSECURELOCK_BLANK_TIMEOUT=5
        exec -a "$0" ${pkgs.xsecurelock}/bin/xsecurelock "$@"
      '');
      mkXSSLocker = lockCmd: pkgs.writers.writeBash "xss-locker-wrapper" ''
        # Command to start the locker (should not fork)
        locker="${lockCmd}"

        # Kill locker if we get killed
        trap 'kill "$LOCKER_PID" 2>/dev/null' TERM INT

        # Run the locker in the background
        $locker &
        LOCKER_PID="$!"

        # If we've been passed a XSS_SLEEP_LOCK_FD, we need to ensure we clean
        # it up; once both us and the locker have closed it, systemd will know
        # it is OK to proceed to sleep
        if [[ -e /dev/fd/''${XSS_SLEEP_LOCK_FD:--1} ]]; then
          exec {XSS_SLEEP_LOCK_FD}<&-
        fi

        # Wait for the locker to exit
        wait

        # Now that we're unlocked again, trigger a logind Unlock event; we can
        # hook this in dbus (or in systemd via systemd-lock-handler)
        ${pkgs.systemd}/bin/loginctl unlock-session &
      '';
    in {
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
      systemd.user.services.xss-lock = {
        Unit = {
          PartOf = [ "hm-graphical-session.target" ];
          # Don't restart on home-manager activation if paths have changed
          X-RestartIfChanged = false;
        };
        Service = {
          ExecStart = "${pkgs.xss-lock}/bin/xss-lock -s $XDG_SESSION_ID -n ${pkgs.xsecurelock}/libexec/xsecurelock/dimmer -l -- ${locker}";
          Slice = "session.slice";
        };
        Install = {
          WantedBy = [ "hm-graphical-session.target" ];
        };
      };
      systemd.user.services.power-switch-lock = {
        Service = {
          ExecStart = "/run/current-system/sw/bin/lock-power-switch lock";
          Slice = "session.slice";
          Type = "oneshot";
        };
        Unit = {
          Before = [ "lock.target" ];
          # Don't restart on home-manager activation if paths have changed
          X-RestartIfChanged = false;
        };
        Install = {
          WantedBy = [ "lock.target" ];
        };
      };
      systemd.user.services.power-switch-unlock = {
        Service = {
          ExecStart = "/run/current-system/sw/bin/lock-power-switch unlock";
          Slice = "session.slice";
          Type = "oneshot";
        };
        Unit = {
          Before = [ "unlock.target" ];
          # Don't restart on home-manager activation if paths have changed
          X-RestartIfChanged = false;
        };
        Install = {
          WantedBy = [ "unlock.target" ];
        };
      };
      home.packages = with pkgs; [
        nur.repos.shados.systemd-lock-handler
        xss-lock
      ];
    })
    (mkIf config.xsession.windowManager.openbox.enable {
      # Screen-lock keybind
      xsession.windowManager.openbox.keyboard.keybind."W-A-l" = singleton { action = "execute"; command = "loginctl lock-session"; };
    })
  ]);
}
