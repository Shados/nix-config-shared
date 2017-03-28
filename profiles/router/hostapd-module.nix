# Override normal hostapd module with one that allows setting the logging level
{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.hostapd;

  configFile = pkgs.writeText "hostapd.conf"
    ''
    interface=${cfg.interface}
    driver=${cfg.driver}
    ssid=${cfg.ssid}
    hw_mode=${cfg.hwMode}
    channel=${toString cfg.channel}

    # logging (debug level)
    logger_syslog=-1
    logger_syslog_level=${toString cfg.logLevel}
    logger_stdout=-1
    logger_stdout_level=${toString cfg.logLevel}

    ctrl_interface=/var/run/hostapd
    ctrl_interface_group=${cfg.group}

    ${if cfg.wpa then ''
      wpa=1
      wpa_passphrase=${cfg.wpaPassphrase}
      '' else ""}

    ${cfg.extraConfig}
    '' ;

in

{
  ###### interface
  options = {
    services.hostapd = {
      logLevel = mkOption { 
        default = 2;
        example = 0;
        type = types.int;
        description = 
          ''
          Logging level to use, from 0 to 4.
          0 logs everything including detailed/verbose debug information, 4 logs only the most critical events.
          '';
      };
    };
  };

  ###### implementation
  config = mkIf cfg.enable {
    environment.systemPackages =  [ pkgs.hostapd ];
    systemd.services.hostapd.serviceConfig.ExecStart = mkForce "${pkgs.hostapd}/bin/hostapd ${configFile}";
  };
}
