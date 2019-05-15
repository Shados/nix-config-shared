{ config, lib, pkgs, ... }:
{
  nixpkgs.overlays = [(self: super: with super.lib; {
    cataclysm-dda-git = (super.cataclysm-dda-git.overrideAttrs(oldAttrs: rec {
      version = "2019-03-05"; # jenkinks build #8566 https://ci.narc.ro/job/Cataclysm-Multijob/8566/
      name = "cataclysm-dda-git-${version}";
      src = super.fetchgit {
        url = "https://github.com/CleverRaven/Cataclysm-DDA.git";
        rev = "d5cafd3e5a785f43164e3ff3e1cb60dd7fefde94";
        sha256 = "10kvf9q3wx1nava18y4qw5qd13sv5msf05jg0x9x0jpqzaafrpyj";
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
