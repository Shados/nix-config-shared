{ config, pkgs, ... }:

{
  services.haveged = {
    enable = true;
    refill_threshold = 3072;
  };
}
