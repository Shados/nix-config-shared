{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.programs.fish;
in
{
  imports = [
    ./module.nix
  ];

  config = mkMerge [
    {
      programs.fish = {
        enable = mkDefault true;
      };
    }
    (mkIf cfg.enable {
      programs.fish = {
        interactiveShellInit = ''
          # If we're not already in tmux (or screen, or at a console prompt), make
          # a new session
          if test -z (echo $TMUX)
            if begin; test $TERM != "screen"; and test $TERM != "screen-256color"; and test $TERM != "linux"; end
              tmux
            end
          end
        '';

        functionDirs = singleton ./functions;

        shellAliases = {
          ll = "ls -lh"; # Long-format listing of files
          la = "ls -ah"; # Listing all files
          l = "ls -Glah"; # Long-format colorised listing of all files
          lsd = "ls -l | grep --color=never '^d'"; # List only directories
          ".." = "cd ..";
          "..." = "cd ../..";
          g = "git";
          whois = "whois -h whois-servers.net";
          # SSH while ignoring host key checking (potentially risky)
          scpbad = "scp -o UserKnownHostsFile=/dev/null -o StrictHostKeychecking=no";
          sshbad = "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeychecking=no";

          # ZFS stuff
          arc_drop = "sudo bash -c 'echo 3 > /proc/sys/vm/drop_caches'";
          arc_set_max = ''sudo bash -c "echo \$(($argv[1] * 1024 * 1024)) > /sys/module/zfs/parameters/zfs_arc_max"; and arc_drop'';
          arc_check_sizes = ''cat /proc/spl/kstat/zfs/arcstats | grep -P '^(?:c_|size)' | awk '{ print $1":\t"$3 / 1024 / 1024" MiB"; }' '';
        };
      };

      environment.systemPackages = with pkgs; [
        which # Fish doesn't have `which` by default
      ];
    })
  ];
}
