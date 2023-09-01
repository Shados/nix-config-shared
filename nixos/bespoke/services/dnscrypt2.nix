{ config, lib, pkgs, ... }:
let
  inherit (lib) concatMapStringsSep concatStringsSep length listToAttrs literalExpression mapAttrs mkEnableOption mkIf mkOption optional optionalAttrs types;

  cfg = config.services.dnscrypt-proxy2;

  # TODO: genericise and move to lib?
  jsonCfgFile = pkgs.writeText "dnscrypt-proxy2.json" (builtins.toJSON cfg.settings);
  tomlCfgFile = pkgs.runCommandNoCCLocal "dnscrypt-proxy2.toml" { } ''
    ${pkgs.remarshal}/bin/json2toml < ${jsonCfgFile} > $out
  '';

  serviceDirName = "dnscrypt-proxy";
  isAbsolute = path: builtins.substring 0 1 path == "/";
  # These will show up under /var/log/private/${serviceDirName} and
  # /var/cache/private/${serviceDirName}, and when running, the process itself
  # will get symlinks to those directories from /var/lib/${serviceDirName} and
  # /var/cache/${serviceDirName} -- see `man systemd.exec` for more.
  logLocation = logPath:
    if isAbsolute logPath
    then logPath
    else "/var/log/${serviceDirName}/${logPath}";
  cacheLocation = cachePath:
    if isAbsolute cachePath
    then cachePath
    else "/var/cache/${serviceDirName}/${cachePath}";

  mapAddressesToStrings = addrs: map (a: "${a.address}:${toString a.port}") addrs;
  defaultPortAddrs = builtins.filter (a: a.port == 53) cfg.listenAddresses;


  # Types and option submodules {{{
  addressType = types.submodule {
    options = {
      address = mkOption {
        type = with types; str;
        description = ''
          An IP address.
        '';
      };
      port = mkOption {
        type = with types; ints.u16;
        default = 53;
        description = ''
          A TCP/UDP port number.
        '';
      };
    };
  };

  domainOpt = mkOption {
    type = with types; str;
    description = ''
      The domain to match on.
    '';
    example = "example.com";
  };
  forwardingRule = types.submodule {
    options = {
      domain = domainOpt;
      servers = mkOption {
        type = with types; listOf str;
        description = ''
          The servers to forward queries for the matched domain to.
        '';
        example = [ "9.9.9.9" ];
      };
    };
  };
  cloakingRule = types.submodule {
    options = {
      domain = domainOpt;
      return = mkOption {
        type = with types; str;
        description = ''
          The IP address or domain name to return.

          Names will be resolved and CNAMES will be flattened before returning.
        '';
        example = "forcesafesearch.google.com";
      };
    };
  };

  schedule = types.submodule {
    options = mkScheduleOptsFor [ "mon" "tue" "wed" "thu" "fri" "sat" "sun" ];
  };
  mkScheduleOptsFor = dayNames: let
      dayList = map (name: { inherit name; value = dayOpt; }) dayNames;
    in listToAttrs dayList;
  dayOpt = mkOption {
    type = with types; listOf daySchedule;
    default = null;
    description = ''
      A list of periods of time within which to apply the scheduled blocklist.

      { after = "21:00"; before = "7:00"; } matches 0:00-7:00 and 21:00-0:00
      { after = "9:00"; before = "18:00"; } matches 9:00-18:00
    '';
  };
  daySchedule = types.submodule {
    options = {
      after = timeOpt;
      before = timeOpt;
    };
  };
  timeOpt = mkOption {
    type = with types; timeType;
    description = ''
      A time specification, in 24-hour HH:MM format.
    '';
  };
  timeType = types.strMatching "[0-2]?[[:digit:]]:[[:digit:]]{2}";

  logFormat = with types; enum [ "tsv" "ltsv" ];
  formatOpt = mkOption {
    type = with types; logFormat;
    default = "tsv";
    description = ''
      Query log format. Available optsion:
      - tsv (a simple list of Tab-Separated Values)
      - ltsv (a structured format that is less human-readable, but simple to parse and usually a better fit for log processors)
    '';
  };

  serverSource = types.submodule {
    options = {
      urls = mkOption {
        type = with types; listOf str;
        description = ''
          A list of (mirrored) URLs for the same remote source.
        '';
        example = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v2/public-resolvers.md"
          "https://download.dnscrypt.info/resolvers-list/v2/public-resolvers.md"
        ];
      };
      cacheFile = mkOption {
        type = with types; str;
        description = ''
          The path to store a locally-cached version of the remote source in.

          Relative paths will end up under /var/cache/private/${serviceDirName}.
        '';
        example = "public-resolvers.md";
      };
      minisignKey = mkOption {
        type = with types; str;
        description = ''
          The minisign key the source is signed with.
        '';
        example = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
      };
      refreshDelay = mkOption {
        type = with types; int;
        default = 72;
        description = ''
          The amount of time to wait between checks for an updated source list,
          in hours.
        '';
      };
      prefix = mkOption {
        type = with types; str;
        default = "";
        description = ''
          A prefix to be prepended to server names in order to
          avoid collisions if different sources share the same name for
          different servers. Leave as an empty string to disable.
        '';
      };
    };
  };

  stampType = types.strMatching "sdns://[[:alnum:]]+";
  # }}}
in
{
  meta = {
    maintainers = with lib.maintainers; [ arobyn ];
  };

  # TODO options:
  # package
  options = {
    services.dnscrypt-proxy2 = {
      enable = mkEnableOption "DNSCrypt v2 client proxy";
      package = mkOption {
        type = with types; package;
        default = pkgs.dnscrypt-proxy2;
        defaultText = "pkgs.dnscrypt-proxy2";
        description = ''
          The dnscrypt-proxy2 derivation to use.
        '';
      };
      listenAddresses = mkOption {
        type = with types; listOf addressType;
        default = [
          { address = "127.0.0.1"; port = 53; }
          { address = "[::1]"; port = 53; }
        ];
        description = ''
          A list of address + port pairs on which to listen for DNS requests.
        '';
      };
      socketActivated = mkOption {
        type = with types; bool;
        default = true;
        description = ''
          Whether or not to use systemd socket activation to start
          dnscrypt-proxy.
        '';
      };
      resolveLocalQueries = mkOption {
        type = with types; bool;
        default = false;
        description = ''
          Whether dnscrypt-proxy should resolve local queries (i.e. add
          127.0.0.1 to /etc/resolv.conf).
        '';
      };
      selectedServers = mkOption {
        type = with types; listOf str;
        default = [];
        description = ''
          List of server names (from registered servers.sources) to use.

          If not specified (empty), all registered servers matching the
          servers.filters options will be used.

          The proxy will automatically pick the fastest, working servers from
          the list.
        '';
        example = [ "scaleway-fr" "google" "yandex" "cloudflare" ];
      };
      maxClients = mkOption {
        type = with types; int;
        default = 250;
        description = ''
          The maximum number of simultaneous client connections to accept.
        '';
      };
      forceTcp = mkOption {
        type = with types; bool;
        default = false;
        description = ''
          If true, always use TCP to connect to upstream servers.

          This can be useful if you need to route everything through Tor.
          Otherwise, leave this to `false`, as it doesn't improve security
          (dnscrypt-proxy will always encrypt everything even using UDP), and
          can only increase latency.
        '';
      };
      socksProxy = mkOption {
        type = with types; nullOr str;
        default = null;
        description = ''
          If set, route all TCP connections through the specified SOCKS proxy.

          Requires `forceTcp` to be set to `true`, or it doesn't do much.
        '';
        example = "socks5://127.0.0.1:9050";
      };
      httpProxy = mkOption {
        type = with types; nullOr str;
        default = null;
        description = ''
          If set, route all connections through the specified HTTP proxy.
          Only for DoH servers.
        '';
        example = "http://127.0.0.1:8888";
      };
      timeout = mkOption {
        type = with types; int;
        default = 2500;
        description = ''
          How long a DNS query will wait for a response, in milliseconds.
        '';
      };
      keepalive = mkOption {
        type = with types; int;
        default = 30;
        description = ''
          Keepalive interval for HTTPS and HTTP/2 queries, in seconds.
        '';
      };
      blockedQueryResponse = mkOption {
        # TODO proper format for the "IP response" instead of just str
        type = with types; either (enum [ "refused" "hinfo" ]) str;
        default = "hinfo";
        description = ''
          Response for blocked queries. Options are `refused`, `hinfo`
          (default) or an IP response. To give an IP response, use the format
          `a:<IPv4>,aaaa:<IPv6>`. Using the `hinfo` option means that some
          responses will be lies.
          Unfortunately, the `hinfo` option appears to be required for Android
          8+
        '';
      };
      loadBalancingStrategy = mkOption {
        type = with types; enum [ "p2" "ph" "fastest" "random" ];
        default = "p2";
        description = ''
          The load-balancing strategy to use. Available options:
          - "p2" (randomly choose between the top 2 fastest servers; the default)
          - "fastest" (always pick the fastest server in the list)
          - "ph" (randomly choose between the top fastest half of all servers)
          - "random" (just pick any random server from the list)
        '';
      };
      certRefreshDelay = mkOption {
        type = with types; int;
        default = 240;
        description = ''
          Delay after which certificates are reloaded, in minutes.
        '';
      };
      dnscryptEphemeralKeys = mkOption {
        type = with types; bool;
        default = false;
        description = ''
          Create a new, unique key for every individual DNSCrypt query.

          This may improve privacy but can also have a significant impact on
          CPU usage.
        '';
      };
      tlsDisableSessionTickets = mkOption {
        type = with types; bool;
        default = false;
        description = ''
          Disables TLS session tickets; doing so increases privacy but also
          latency.
        '';
      };
      tlsCipherSuite = mkOption {
        type = with types; listOf (enum [ 49199 49195 52392 52393 ]);
        default = [];
        description = ''
          For DNS-over-HTTPS, use a specific suite of ciphers instead of
          following the upstream server's preferences.

          Available suites:
          - 49199 (TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256)
          - 49195 (TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256)
          - 52392 (TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305)
          - 52393 (TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305)

          On non-Intel CPUs (e.g. MIPS routers and ARM systems), and possibly
          on 32-bit OS on Intel CPUs, the following suite improves performance:
          `[ 52392, 49199 ]`

          Keep this option empty if you have issues fetching sources or
          connecting to some DoH servers.
        '';
      };
      bootstrapResolvers = mkOption {
        type = with types; listOf str;
        default = [ "9.9.9.9:53" "8.8.8.8:53" ];
        description = ''
          These are normal, non-encrypted DNS resolvers, that will be only used
          for one-shot queries when retrieving the initial resolvers list and
          if the system DNS configuration doesn't work.

          No user queries will ever be leaked through these resolvers, and they
          will not be used after IP addresses of DoH resolvers have been found
          (if you are using DoH).

          They will never be used if lists have already been cached, and if the
          stamps of the configured servers already include IP addresses (which
          is the case for most of DoH servers, and for all DNSCrypt servers and
          relays).

          They will not be used if the configured system DNS works, or after
          the proxy already has at least one usable secure resolver.

          Resolvers supporting DNSSEC are recommended, and, if you are using
          DoH, bootstrap resolvers should ideally be operated by a different
          entity than the DoH servers you will be using, especially if you have
          IPv6 enabled.

          People in China may want to use 114.114.114.114:53 here.
          Other popular options include 8.8.8.8, 9.9.9.9 and 1.1.1.1.

          If more than one resolver is specified, they will be tried in
          sequence.

          TL;DR: put valid standard resolver addresses here. Your actual
          queries will not be sent there. If you're using DNSCrypt or
          Anonymized DNS and your lists are up to date, these resolvers will
          not even be used.

          The default (Quad9) is backed by the GCA (Global Cyber Alliance), an
          international organization founded by law enforcement agencies in the
          US and UK, and a US cyber-security research organization.
        '';
      };
      ignoreSystemDns = mkOption {
        type = with types; bool;
        default = true;
        description = ''
          Never let dnscrypt-proxy try to use the system DNS settings;
          unconditionally use the bootstrap resolvers.
        '';
      };
      netprobeTimeout = mkOption {
        type = with types; int;
        default = 60;
        description = ''
          Maximum time (in seconds) to wait before initializing the proxy.

          Useful if the proxy is automatically started at boot, and network
          connectivity is not guaranteed to be immediately available.

          Set to 0 to disable.
        '';
      };
      offlineMode = mkOption {
        type = with types; bool;
        default = false;
        description = ''
          Enables 'offline mode' - disables use of any remote encrypted
          servers.
          The proxy will remain fully functional to respond to queries that
          plugins can handle directly (forwarding, cloaking, ...)
        '';
      };

      forwardingRules = mkOption {
        type = with types; listOf forwardingRule;
        default = [];
        description = ''
          Routes queries for specific domains to dedicated sets of servers.
        '';
        example = [
          { domain = "example.com"; servers = [ "9.9.9.9" ]; }
          { domain = "example.net"; servers = [ "9.9.9.9" "8.8.8.8" "1.1.1.1" ]; }
        ];
      };

      cloakingRules = mkOption {
        type = with types; listOf cloakingRule;
        default = [];
        description = ''
          Cloaking returns a predefined address for a specific name.
          In addition to acting as a HOSTS file, it can also return the IP
          address of a different name. It will also do CNAME flattening.
        '';
        example = literalExpression ''
          [
            { domain = "example.com"; return = "10.1.1.1"; }
            { domain = "www.google.com"; return = "forcesafesearch.google.com"; }
          ]
        '';
      };

      cache = {
        enable = mkOption {
          type = with types; bool;
          default = true;
          description = ''
            Whether or not to enable a DNS cache to reduce latency and outgoing traffic.
          '';
        };
        size = mkOption {
          type = with types; int;
          default = 512;
          description = ''
            Cache size, in entries.
          '';
        };
        minTtl = mkOption {
          type = with types; int;
          default = 600;
          description = ''
            The minimum DNS TTL for cached entries (in seconds).
          '';
        };
        maxTtl = mkOption {
          type = with types; int;
          default = 86400;
          description = ''
            The maximum DNS TTL for cached entries (in seconds).
          '';
        };
        negMinTtl = mkOption {
          type = with types; int;
          default = 60;
          description = ''
            The minimum DNS TTL for negatively cached entries (in seconds).
          '';
        };
        negMaxTtl = mkOption {
          type = with types; int;
          default = 600;
          description = ''
            The maximum DNS TTL for negatively cached entries (in seconds).
          '';
        };
      };

      logging = {
        level = mkOption {
          type = with types; ints.between 0 6;
          default = 2;
          description = ''
            The log level to use.
            Ranges from 0 to 6, 0 is very verbose, 6 is fatal errors only, 2 is
            the default.
          '';
        };
        useFile = mkOption {
          type = with types; nullOr str;
          default = null;
          description = ''
            If set, log to the specified file path.

            Relative paths will end up under /var/log/private/${serviceDirName}.
          '';
        };
        useSyslog = mkOption {
          type = with types; bool;
          default = true;
          description = ''
            Whether or not to use the system logger.
          '';
        };

        query = {
          file = mkOption {
            type = with types; nullOr str;
            default = null;
            description = ''
              If set, log client queries to the specified file path.

              Relative paths will end up under /var/log/private/${serviceDirName}.
            '';
          };
          format = formatOpt;
          ignoredQtypes = mkOption {
            type = with types; listOf (enum [
              "A" "AAAA" "AFSDB" "APL" "CAA" "CDNSKEY" "CDS" "CERT" "CNAME"
              "DHCID" "DLV" "DNAME" "DNSKEY" "DS" "HIP" "IPSECKEY" "KEY" "KX"
              "LOC" "MX" "NAPTR" "NS" "NSEC" "NSEC3" "NSEC3PARAM" "OPENPGPKEY"
              "PTR" "RRSIG" "RP" "SIG" "SMIMEA" "SOA" "SRV" "SSHFP" "TA" "TKEY"
              "TLSA" "TSIG" "TXT" "URI"
              "*" "AXFR" "IXFR" "OPT"
            ]);
            default = [];
            description = ''
              Do not log these query types, to reduce verbosity. Leave empty to
              log everything.
            '';
            example = [ "DNSKEY" "NS" ];
          };
        };

        nx = {
          file = mkOption {
            type = with types; nullOr str;
            default = null;
            description = ''
              If set, log client queries to non-existent zones to the specified
              file path.

              These queries can reveal the presence of malware, broken/obsolete
              applications, and devices signaling their presence to 3rd
              parties.

              Relative paths will end up under /var/log/private/${serviceDirName}.
            '';
          };
          format = formatOpt;
        };

        blacklist = {
          file = mkOption {
            type = with types; nullOr str;
            default = null;
            description = ''
              If set, log client queries that are blocked by the blacklist to
              the specified file path.

              Only relevant if a blacklist file is actually used.

              Relative paths will end up under /var/log/private/${serviceDirName}.
            '';
          };
          format = formatOpt;
        };

        ipBlacklist = {
          file = mkOption {
            type = with types; nullOr str;
            default = null;
            description = ''
              If set, log client queries that are blocked by the IP blacklist
              to the specified file path.

              Only relevant if an IP blacklist file is actually used.

              Relative paths will end up under /var/log/private/${serviceDirName}.
            '';
          };
          format = formatOpt;
        };

        whitelist = {
          file = mkOption {
            type = with types; nullOr str;
            default = null;
            description = ''
              If set, log client queries that are allowed by the whitelist to
              the specified file path.

              Only relevant if a whitelist file is actually used.

              Relative paths will end up under /var/log/private/${serviceDirName}.
            '';
          };
          format = formatOpt;
        };

        logRotation = {
          maxSize = mkOption {
            type = with types; int;
            default = 10;
            description = ''
              Maximum log files size in MB.
            '';
          };
          maxAge = mkOption {
            type = with types; int;
            default = 7;
            description = ''
              How long to retain backup log files, in days.
            '';
          };
          maxBackups = mkOption {
            type = with types; int;
            default = 1;
            description = ''
              Maximum backup log files to retain (or 0 to keep all backup log
              files).
            '';
          };
        };
      };

      queryFilters = {
        blockIpv6 = mkOption {
          type = with types; bool;
          default = false;
          description = ''
            Immediately respond to IPv6-related queries with an empty response.

            This makes things faster when there is no IPv6 connectivity, but
            can also cause reliability issues with some stub resolvers.

            Do not enable if you added a validating resolver such as dnsmasq in
            front of the proxy.
          '';
        };
        blacklist = mkOption {
          type = with types; nullOr str;
          default = null;
          description = ''
            If set, the path to a blacklist file, used to block queries based
            on the domain queried.

            The path can absolute, or relative to /var/lib/private/${serviceDirName}.

            Blacklists are made of one pattern per line. Example of valid patterns:

                example.com
                =example.com
                *sex*
                ads.*
                ads*.example.*
                ads*.example[0-9]*.com

            Example blacklist files can be found at
            https://download.dnscrypt.info/blacklists/

            A script to build blacklists from public feeds can be found in the
            `utils/generate-domains-blacklists` directory of the dnscrypt-proxy
            source code.
          '';
          example = "blacklist.txt";
        };
        ipBlacklist = mkOption {
          type = with types; nullOr str;
          default = null;
          description = ''
            If set, the path to an IP blacklist file, used to block queries
            based on the IP resolved by the query.

            The path can absolute, or relative to the /var/lib/private/${serviceDirName}.

            IP blacklists are made of one pattern per line. Example of valid patterns:

                127.*
                fe80:abcd:*
                192.168.1.4
          '';
          example = "ip_blacklist.txt";
        };
        whitelist = mkOption {
          type = with types; nullOr str;
          default = null;
          description = ''
            If set, the path to a whitelist file, used to bypass the name and
            IP blacklists, based on the name of the queried domain.

            The path can absolute, or relative to the /var/lib/private/${serviceDirName}.

            Supports the same patterns as the blacklist.

            Time-based rules are also supported to make some websites only
            accessible at specific times of the day.
          '';
          example = "whitelist.txt";
        };
        schedules = mkOption {
          type = with types; attrsOf schedule;
          default = {};
          description = ''
            One or more weekly schedules can be defined here.
            Patterns in the name-based blocklist can optionally be followed
            with @schedule_name to apply the pattern 'schedule_name' only when
            it matches a time range of that schedule.

            For example, the following rule in a blacklist file:
            *.youtube.* @time-to-sleep
            would block access to YouTube only during the days, and period of
            the days define by the 'time-to-sleep' schedule.
          '';
          example = {
            "time-to-sleep" = {
              mon = [ { after = "21:00"; before = "7:00"; } ];
              tue = [ { after = "21:00"; before = "7:00"; } ];
              wed = [ { after = "21:00"; before = "7:00"; } ];
              thu = [ { after = "21:00"; before = "7:00"; } ];
              fri = [ { after = "23:00"; before = "7:00"; } ];
              sat = [ { after = "23:00"; before = "7:00"; } ];
              sun = [ { after = "21:00"; before = "7:00"; } ];
            };
            work = {
              mon = [ { after = "9:00"; before = "18:00"; } ];
              tue = [ { after = "9:00"; before = "18:00"; } ];
              wed = [ { after = "9:00"; before = "18:00"; } ];
              thu = [ { after = "9:00"; before = "18:00"; } ];
              fri = [ { after = "9:00"; before = "17:00"; } ];
            };
          };
        };
      };

      servers = {
        sources = mkOption {
          type = with types; attrsOf serverSource;
          default = {
            "public-resolvers" = {
              urls = [
                "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v2/public-resolvers.md"
                "https://download.dnscrypt.info/resolvers-list/v2/public-resolvers.md"
              ];
              cacheFile = "public-resolvers.md";
              minisignKey = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
              refreshDelay = 72;
            };
          };
          description = ''
            Set of remotely-maintained lists of available servers.

            Multiple sources can be used simultaneously, but every source
            requires a dedicated cache file.

            Refer to the dnscrypt-proxy 2 documentation for URLs of public
            sources.

            A prefix can be prepended to server names in order to avoid
            collisions if different sources share the same for different
            servers. In that case, names listed in `selectedServers` must
            include the prefixes.

            If the `urls` property is missing, cache files and valid signatures
            must be already present; This doesn't prevent these cache files
            from expiring after `refreshDelay` hours.
          '';
        };
        static = mkOption {
          type = with types; attrsOf stampType;
          default = {};
          description = ''
            Optional local, static list of additional servers.

            Mostly useful for testing your own servers.

            The values are DNS stamps -- more information: https://dnscrypt.info/stamps/
          '';
          example = {
            google = "sdns://AgUAAAAAAAAAAAAOZG5zLmdvb2dsZS5jb20NL2V4cGVyaW1lbnRhbA";
          };
        };
        filters = {
          ipv4 = mkOption {
            type = with types; bool;
            default = true;
            description = ''
              Whether or not to use servers reachable over IPv4.

              Do not enable if you do not have IPv4 connectivity.
            '';
          };
          ipv6 = mkOption {
            type = with types; bool;
            default = false;
            description = ''
              Whether or not to use servers reachable over IPv6.

              Do not enable if you do not have IPv6 connectivity.
            '';
          };
          dnscrypt = mkOption {
            type = with types; bool;
            default = true;
            description = ''
              Whether or not to use servers that implement the DNSCrypt protocol.
            '';
          };
          doh = mkOption {
            type = with types; bool;
            default = true;
            description = ''
              Whether or not to use servers that implement the DNS-over-HTTPS
              protocol.
            '';
          };
          requireDnssec = mkOption {
            type = with types; bool;
            default = false;
            description = ''
              If true, filtered servers *must* support DNSSEC.
            '';
          };
          requireNolog = mkOption {
            type = with types; bool;
            default = true;
            description = ''
              If true, filtered servers *must* claim that they do not log
              queries.
            '';
          };
          requireNofilter = mkOption {
            type = with types; bool;
            default = true;
            description = ''
              If true, filtered servers *must* claim that they do not blacklist
              or modify query results (e.g. for parental controls, ad blocking,
              monetization).
            '';
          };
          disabledServerNames = mkOption {
            type = with types; listOf str;
            default = [];
            description = ''
              Server names to avoid even if they match all criteria.
            '';
          };
        };
      };

      settings = mkOption {
        type = with types; attrs;
        default = {};
        description = ''
          JSON representation of the dnscrypt TOML configuration file. This is
          set internally by module options, and can be used directly to
          configure settings not exposed by the module options.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      { assertion = length cfg.listenAddresses > 0;
        message = "dnscrypt-proxy2: You must specify at least one listen address";
      }
      { assertion = cfg.socksProxy == null || cfg.forceTcp;
        message = "dnscrypt-proxy2: If a socks proxy is configured, forceTcp must be set to `true`";
      }
      { assertion = (! cfg.resolveLocalQueries) || cfg.ignoreSystemDns;
        message = "dnscrypt-proxy2: ignoreSystemDns must be `true` if resolveLocalQueries is enabled";
      }
      { assertion = (! cfg.resolveLocalQueries) || (length defaultPortAddrs > 0);
        message = "dnscrypt-proxy2: at least one address must be listening on port 53 if resolveLocalQueries is enabled, as libresolv/glibc do not support non-standard DNS ports";
      }
    ];

    networking.nameservers = optional cfg.resolveLocalQueries (map (a: a.address) defaultPortAddrs);

    environment.systemPackages = with pkgs; [
      cfg.package
    ];

    services.dnscrypt-proxy2.settings = let
      forwardingRuleFile = pkgs.writeText "forwarding-rules.txt" (concatMapStringsSep "\n" (fr:
          "${fr.domain} ${concatStringsSep "," fr.servers}"
        ) cfg.forwardingRules);
      cloakingRuleFile = pkgs.writeText "cloaking-rules.txt" (concatMapStringsSep "\n" (cr:
          "${cr.domain} ${cr.return}"
        ) cfg.forwardingRules);
    in {
      listen_addresses = if cfg.socketActivated
        then []
        else mapAddressesToStrings cfg.listenAddresses;
      max_clients = cfg.maxClients;
      ipv4_servers = cfg.servers.filters.ipv4;
      ipv6_servers = cfg.servers.filters.ipv6;
      dnscrypt_servers = cfg.servers.filters.dnscrypt;
      doh_servers = cfg.servers.filters.doh;
      require_dnssec = cfg.servers.filters.requireDnssec;
      require_nolog = cfg.servers.filters.requireNolog;
      require_nofilter = cfg.servers.filters.requireNofilter;
      disabled_server_names = cfg.servers.filters.disabledServerNames;
      force_tcp = cfg.forceTcp;
      timeout = cfg.timeout;
      keepalive = cfg.keepalive;
      blocked_query_response = cfg.blockedQueryResponse;
      lb_strategy = cfg.loadBalancingStrategy;
      log_level = cfg.logging.level;
      use_syslog = cfg.logging.useSyslog;
      cert_refresh_delay = cfg.certRefreshDelay;
      dnscrypt_ephemeral_keys = cfg.dnscryptEphemeralKeys;
      tls_disable_session_tickets = cfg.tlsDisableSessionTickets;
      bootstrap_resolvers = cfg.bootstrapResolvers;
      ignore_system_dns = cfg.ignoreSystemDns;
      netprobe_timeout = cfg.netprobeTimeout;
      offline_mode = cfg.offlineMode;
      log_files_max_size = cfg.logging.logRotation.maxSize;
      log_files_max_age = cfg.logging.logRotation.maxAge;
      log_files_max_backups = cfg.logging.logRotation.maxBackups;
      block_ipv6 = cfg.queryFilters.blockIpv6;
      cache = cfg.cache.enable;
      cache_size = cfg.cache.size;
      cache_min_ttl = cfg.cache.minTtl;
      cache_max_ttl = cfg.cache.maxTtl;
      cache_neg_min_ttl = cfg.cache.negMinTtl;
      cache_neg_max_ttl = cfg.cache.negMaxTtl;
      query_log = {
        format = cfg.logging.query.format;
        ignored_qtypes = cfg.logging.query.ignoredQtypes;
      } // optionalAttrs (cfg.logging.query.file != null) {
        file = logLocation cfg.logging.query.file;
      };
      nx_log = {
        format = cfg.logging.nx.format;
      } // optionalAttrs (cfg.logging.nx.file != null) {
        file = logLocation cfg.logging.nx.file;
      };
      blacklist = {
        log_format = cfg.logging.blacklist.format;
      } // optionalAttrs (cfg.logging.blacklist.file != null) {
        log_file = logLocation cfg.logging.blacklist.file;
      } // optionalAttrs (cfg.queryFilters.blacklist != null) {
        blacklist_file = cfg.queryFilters.blacklist;
      };
      ip_blacklist = {
        log_format = cfg.logging.ipBlacklist.format;
      } // optionalAttrs (cfg.logging.ipBlacklist.file != null) {
        log_file = logLocation cfg.logging.ipBlacklist.file;
      } // optionalAttrs (cfg.queryFilters.ipBlacklist != null) {
        blacklist_file = cfg.queryFilters.ipBlacklist;
      };
      whitelist = {
        log_format = cfg.logging.whitelist.format;
      } // optionalAttrs (cfg.logging.whitelist.file != null) {
        log_file = logLocation cfg.logging.whitelist.file;
      } // optionalAttrs (cfg.queryFilters.whitelist != null) {
        whitelist_file = cfg.queryFilters.whitelist;
      };
      schedules = cfg.queryFilters.schedules;
      sources = mapAttrs (name: source: {
        inherit (source) urls prefix;
        cache_file = cacheLocation source.cacheFile;
        minisign_key = source.minisignKey;
        refresh_delay = source.refreshDelay;
      }) cfg.servers.sources;
      static = cfg.servers.static;
    } // optionalAttrs (cfg.selectedServers != []) {
      server_names = cfg.selectedServers;
    } // optionalAttrs (cfg.socksProxy != null) {
      proxy = cfg.socksProxy;
    } // optionalAttrs (cfg.httpProxy != null) {
      http_proxy = cfg.httpProxy;
    } // optionalAttrs (cfg.logging.useFile != null) {
      log_file = logLocation cfg.logging.useFile;
    } // optionalAttrs (cfg.forwardingRules != []) {
      forwarding_rules = forwardingRuleFile;
    } // optionalAttrs (cfg.cloakingRules != []) {
      cloaking_rules = cloakingRuleFile;
    } // optionalAttrs (cfg.tlsCipherSuite != []) {
      tls_cipher_suite = cfg.tlsCipherSuite;
    };

    systemd.services.dnscrypt-proxy2 = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      requires = optional cfg.socketActivated "dnscrypt-proxy2.socket";
      serviceConfig = rec {
        ExecStart = "${cfg.package}/bin/dnscrypt-proxy -config ${tomlCfgFile}";

        WorkingDirectory = "/var/lib/${StateDirectory}";
        StateDirectory = serviceDirName;
        CacheDirectory = serviceDirName;
        LogsDirectory = serviceDirName;

        DynamicUser = true;
        ProtectControlGroups = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
      } // (if cfg.socketActivated then {
        NonBlocking = true;
      } else {
        AmbientCapabilities = "CAP_NET_BIND_SERVICE";
      });
    };
    systemd.sockets = optionalAttrs cfg.socketActivated {
      dnscrypt-proxy2 = {
        wantedBy = [ "sockets.target" ];
        socketConfig = {
          ListenDatagram = mapAddressesToStrings cfg.listenAddresses;
          ListenStream = mapAddressesToStrings cfg.listenAddresses;
          NoDelay = true;
          DeferAcceptSec = 1;
        };
      };
    };
  };
}
