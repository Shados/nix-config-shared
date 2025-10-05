{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    mkEnableOption
    mkIf
    mkOption
    optionalString
    types
    ;
  cfg = config.services.crontab;
  tabfile = pkgs.writeText "crontab" ((concatStringsSep "\n" cfg.jobs) + "\n");
in
{
  options = {
    services.crontab = {
      enable = mkEnableOption "MacOS crontab file management";
      jobs = mkOption {
        type = with types; listOf str;
        example = [
          "*/1 * * * * cd ~/Documents/Python/cron && /usr/local/bin/python3 cron_test.py >> ~/Documents/Python/cron/cron.txt 2>&1"
        ];
        default = [ ];
        description = ''
          A list of cron jobs, in the usual format:

          * * * * * command
          - minute (0-59)
            - hour (0-23)
              - day of the month (1-31)
                - month (1-12)
                  - day of the week (0-6, 0 is Sunday)
                    - command to execute
        '';
      };
      files = mkOption {
        type = with types; listOf path;
        default = [ ];
        description = ''
          A list of extra crontab files that will be read and appended to the
          main crontab file when the crontab is installed.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.sn.os == "darwin";
        message = "crontab: only implemented for darwin";
      }
    ];
    # TODO: Install crontab only if its hash differs from the current one, just to minimise unnecessary permissions-checks
    home.activation.crontab = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      TMP_CRON=$(mktemp "$TMPDIR/crontab.XXXXXX")
      $DRY_RUN_CMD cp -f "${tabfile}" "$TMP_CRON"
      ${
        if (cfg.files != [ ]) then
          ''
            echo "Installing the crontab from generated ${tabfile} and given files ${concatStringsSep " " cfg.files}"
            for tabfile in ${lib.escapeShellArgs cfg.files}; do
              $DRY_RUN_CMD cat "$tabfile" >> "$TMP_CRON"
            done
          ''
        else
          ''
            echo "Installing the crontab from generated ${tabfile}"
          ''
      }
      $DRY_RUN_CMD /usr/bin/crontab "$TMP_CRON"
      rm -f "$TMP_CRON"
    '';
  };
}
