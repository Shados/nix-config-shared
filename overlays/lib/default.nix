{ config, lib, ... }:
lib.mkMerge [
  { nixpkgs.overlays = lib.mkBefore [
      # Lua cross-version overlay support
      (import ./lua-overrides.nix)
    ];
  }
]
