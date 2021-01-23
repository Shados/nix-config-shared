{ config, lib, pkgs, ... }:
with lib;
let
  sddmAvatarFor = username: icon: pkgs.runCommand "sddm-avatar-${username}"
    { preferLocalBuild = true;
      inherit icon username;
    }
    ''
      mkdir -p "$out/share/sddm/faces/"
      cp "$icon" "$out/share/sddm/faces/$username.face.icon"
    '';
in
{
  config = mkIf config.services.xserver.displayManager.sddm.enable {
    # services.xserver.displayManager.sddm.theme = "";
    environment.systemPackages = [
      (sddmAvatarFor "shados" ./shadow_diagram_v2.png)
      (pkgs.libsForQt5.callPackage ./sddm-sugar-dark.nix {
        configOverrides = pkgs.writeText "custom-theme.conf" ''
          [General]
          # Force default/blank these
          ScreenWidth=
          ScreenHeight=
        '';
      })
      pkgs.xlockmore
    ];
  };
}
