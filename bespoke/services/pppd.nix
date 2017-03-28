{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.pppd;

  makePPPDJob = cfg: name:
    let
      configFile = pkgs.writeText "pppd-config-${name}" cfg.config;
    in {
        description   = "PPP link to ${name}";
        before        = [ "network.target" ];
        wantedBy      = [ "multi-user.target" ];

        serviceConfig = {
          ExecStart   = "${pkgs.ppp}/bin/pppd file ${configFile} nodetach nolog debug";
        };
    };
in
{
  options = {
    services.pppd.connections = mkOption {
      default = {};
      description = ''
        Each attribute of this option defines a systemd service that runs a
        pppd instance with a single connection. The name of each systemd
        service is <literal>pppd-<replaceable>name</replaceable>.service</literal>,
        where <replaceable>name</replaceable> is the corresponding
        attribute name.
      '';

      type = with types; attrsOf (submodule {
        options = {
          config = mkOption {
            type = types.lines;
            description = ''
              Configuration for this pppd connection instance. In a
              traditional distribution, this would be a file under
              /etc/ppp/peers/name. See <citerefentry><refentrytitle>pppd</refentrytitle><manvolnum>8</manvolnum></citerefentry> for details.
            '';
          };
        };
      });
    };
  };

  config = mkIf (cfg.connections != {}) {
    # assertions = [
    #   { assertion = cfg.config != null;
    #     message   = "please provide at least one pppd connection file";
    #   }
    # ];

    boot.kernelModules = [ "ppp_generic" ];
    environment.systemPackages = [ pkgs.ppp ];

    systemd.services = listToAttrs (mapAttrsFlatten (name: value: nameValuePair "pppd-${name}" (makePPPDJob value name)) cfg.connections);

    networking.sn-firewall.v4rules.filter = ''
      # We need to clamp MSS as PMTU doesn't work universally on the open net, due to bad or mis-configured firewalls
      -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
    '';
  };
}
