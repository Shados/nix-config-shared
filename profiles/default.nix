{ config, pkgs, ... }:

{
  imports = [
    # Basic SN SOHO router profile
    ./router
  ];
}
