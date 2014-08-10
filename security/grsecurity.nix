{ config, pkgs, ... }:

pkgs.lib.mkIf config.security.grsecurity.enable {
  # TODO: Figure out how to get this to work (or if we want it at all)
  security.grsecurity = {
    testing = true;
    config = {
      system = "server";
      mode = "auto";
      priority = "performance";
      virtualisationConfig = "host";
      virtualisationSoftware = "kvm";
      hardwareVirtualisation = true;
    };
  };
}
