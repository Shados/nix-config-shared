# NOTE: Not really a full service module. Reliant on pipewire being enabled
# system-wide. Not really a sane other way of doing it, because this involves
# multi-user hardware management.

# Mostly copied from the upstream NixOS module.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrNames
    concatMapStringsSep
    flip
    mapAttrs'
    mkEnableOption
    mkIf
    mkOption
    nameValuePair
    types
    ;
  cfg = config.services.pipewire;

  json = pkgs.formats.json { };
  generate =
    name: value:
    pkgs.callPackage (
      { runCommand, jq }:
      runCommand name
        {
          nativeBuildInputs = [ jq ];
          value = builtins.toJSON value;
          passAsFile = [ "value" ];
        }
        ''
          jq . "$valuePath"> $out
        ''
    ) { };

in
{
  options.services.pipewire = {
    enable = mkEnableOption "pipewire service configuration";
    configOverrides = mkOption {
      type = types.attrsOf json.type;
      default = { };
      description = ''
        Pipewire configuration overrides, each attribute will create a separate
        file in ~/.config/pipewire/pipewire.conf.d/.
      '';
    };
  };

  config = mkIf cfg.enable ({
    # Create the config override directory; we create the directory instead of
    # individual files so that the `onChange` hook will fire even when
    # individual overrides are removed
    xdg.configFile."pipewire/pipewire.conf.d/" =
      let
        mkConfFileName = overrideName: "home-manager_${overrideName}.conf";
      in
      {
        source =
          pkgs.runCommandNoCC "pipewire-config-overrides"
            {
              preferLocalBuild = true;
              nativeBuildInputs = [ pkgs.jq ];
              confFiles = builtins.toJSON (
                flip mapAttrs' cfg.configOverrides (name: value: nameValuePair name value)
              );
              passAsFile = [ "confFiles" ];
            }
            (
              ''
                echo "Creating compound file" # TODO remove
                mkdir $out
              ''
              + concatMapStringsSep "\n" (name: ''
                jq ".\"${name}\"" "$confFilesPath" > "$out/${mkConfFileName name}"
              '') (attrNames cfg.configOverrides)
            );
        # TODO: Figure out when/if I need pipewire-pulse restarts as well
        onChange = ''
          restartServices["pipewire"]=1
        '';
      };
    xdg.configFile."systemd/user/pipewire-pulse.service.d/restart.conf".text = ''
      [Unit]
      Requires=pipewire.service
    '';
  });
}
