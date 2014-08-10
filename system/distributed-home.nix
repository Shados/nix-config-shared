{ config, pkgs, ... }:

{
# TODO: Fix & re-implement this in a generically useful manner
# programs.ssh.extraConfig =
# ''
#   Host s2
#     HostName home.shados.net
#     Port 54201
# '';
# nix = {
#   distributedBuilds = true;
#   buildMachines = [
#     { hostName = "s2";
#       maxJobs = 2;
#       sshKey = "/etc/nixos/keys/private/nix-build@r1.shados.net.id_ecdsa";
#       sshUser = "nix";
#       system = "x86_64-linux";
#       supportedFeatures = [ "kvm" ];
#       mandatoryFeatures = [];
#       speedFactor = 1;
#     }
#   ];
#   maxJobs = pkgs.lib.mkForce 4; # Override the hardware-set value... TODO: Build from the hardware-set value + sum of per-host values, assuming this is possible
# };
}
