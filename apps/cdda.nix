{ config, lib, pkgs, ... }:
{
  nixpkgs.overlays = [(self: super: with super.lib; {
    cataclysm-dda-git = (super.cataclysm-dda-git.overrideAttrs(oldAttrs: rec {
      version = "2019-02-25";
      name = "cataclysm-dda-git-${version}";
      src = super.fetchgit {
        url = "https://github.com/CleverRaven/Cataclysm-DDA.git";
        rev = "f76242ff62fce4030a6728831e8131f279de89f7";
        sha256 = "0y4q9a545bdlvpdbj7vs4a167vrcbhmfyw9d776cxjf3kk9w94sa";
        leaveDotGit = true;
      };
      makeFlags = oldAttrs.makeFlags ++ [
        "VERSION=git-${version}-${substring 0 8 src.rev}"
      ];
      patches = []; # Disable unnecessary patch (might be needed on Darwin?)
      enableParallelBuilding = true; # Apparently Hydra has issues with building this in parallel

      # Fix Lua support
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ (with super; [
        makeWrapper git
      ]);
      postInstall = ''
        for bin in $out/bin/*; do
          wrapProgram "$bin" \
            --prefix LUA_PATH  ';' "$out/share/cataclysm-dda/lua/?.lua;$LUA_PATH;"   \
            --prefix LUA_CPATH ';' "$LUA_CPATH;"
        done
      '';
    })).override (with super; {
      # Use luajit and clang!
      stdenv = clangStdenv;
      callPackage = newScope (super // {
        lua = lua;
      });
    });
  })];
}
