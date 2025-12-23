{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkDefault
    mkDerivedConfig
    mkIf
    mkOption
    singleton
    types
    ;
in
{
  options = {
    # TODO assertions
    files = mkOption {
      type = types.attrsOf (
        types.submodule (
          {
            name,
            config,
            options,
            ...
          }:
          {
            options = {
              enable = mkOption {
                type = types.bool;
                default = true;
                description = ''
                  Whether this path should be generated.  This option allows
                  specific paths to be disabled.
                '';
              };

              target = mkOption {
                # TODO assert absolute path
                type = types.str;
                description = ''
                  Name of the path to create within the image.  Defaults to the
                  attribute name.
                '';
              };

              text = mkOption {
                default = null;
                type = types.nullOr types.lines;
                description = ''
                  Text of the file. If not specified, `source` must be set for this
                  file. Must not be set for symlinks and directories.
                '';
              };

              source = mkOption {
                type = with types; nullOr path;
                # TODO assert these bits
                description = ''
                  Path of the source file, symlink, or directory. Must be set for
                  symlinks. For files, if this is not specified, `text` must be
                  set. For directories, if this is not specified, the directory
                  will be created but not populated with anything.
                '';
              };

              type = mkOption {
                type = types.enum [
                  "file"
                  "directory"
                  "symlink"
                ];
                default = "file";
                description = ''
                  The type of path to create.

                  If `file` (the default), then a regular file will be created
                  either by writing out the contents of the `text` value, or by
                  copying `source`, depending on which one is set. Both cannot be
                  set simultaneously.

                  If `directory`, `source` (which must be set) will be copied into
                  place. The mode of files and folders copied within this directory
                  will be 644 and 755, respectively, with owner and group both set
                  to root.

                  If `symlink`, this will create create a link pointing from
                  `target` to `source` (which must be set).
                '';
              };

              mode = mkOption {
                type = types.str;
                default = if config.type == "file" then "0644" else "0755";
                description = ''
                  The permissions mode to apply to the created path.

                  Defaults to 0644 for files, 0755 for directories. Ignored for
                  symlinks.
                '';
              };
            };
            config = {
              target = mkDefault name;
              source = mkIf (config.text != null) (
                let
                  name' = "openwrt-" + baseNameOf name;
                in
                mkDerivedConfig options.text (pkgs.writeText name')
              );
            };
          }
        )
      );
      default = { };
      description = ''
        Files to populate in the generated image.

        Entries with type `directory` will be populated first, allowing `file`
        and `symlink` type entries to overwrite paths in copied directories.
      '';
    };
  };

  config =
    let
      fileTree =
        pkgs.runCommandLocal "openwrt-file-tree"
          {
            nativeBuildInputs = [
              (pkgs.luajit.withPackages (
                p: with p; [
                  moonscript
                  rapidjson
                  inspect
                  luv
                ]
              ))
            ];
            src = ./setup-files.moon;
            filesJson = pkgs.writeText "openwrt-files.json" (builtins.toJSON config.files);
          }
          ''
            moon "$src" "$filesJson" "$out"
          '';
    in
    {
      fileTrees = singleton fileTree;
    };
}
