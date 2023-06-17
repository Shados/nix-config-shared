{ config, lib, pkgs, ... }:
{
  # TODO: Probably chuck this behind an option?
  programs.chromium.flags = [
    # Hardware decoding
    "--enable-features=VaapiVideoDecoder"
    "--disable-features=UseChromeOSDirectVideoDecoder"
  ];
}
