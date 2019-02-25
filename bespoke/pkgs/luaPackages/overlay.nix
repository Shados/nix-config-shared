# TODO sanitize buildLuaPackage and buildLuaRocks, then use them consistently
# as appropriate
self: super: super.sn.defineLuaPackageOverrides super (luaself: luasuper: {
  # alt-getopt = super.callPackage ./alt-getopt.nix { inherit (super.luaPackages) buildLuaPackage; };

  argparse = super.callPackage ./argparse.nix {
    inherit (luasuper) lua buildLuaPackage;
  };
  busted = super.callPackage ./busted.nix {
    inherit (luasuper) lua buildLuaPackage;
    inherit (luaself) lua-ev copas lua-cliargs luasystem dkjson say luassert lua-term penlight mediator_lua;
  };
  cmark-lua = super.callPackage ./cmark-lua.nix {
    inherit (luasuper) lua buildLuarocksPackage;
    inherit (super) cmark;
  };
  copas = super.callPackage ./copas.nix {
    inherit (luasuper) lua buildLuaPackage luasocket;
  };
  dkjson = super.callPackage ./dkjson.nix {
    inherit (luasuper) lua buildLuaPackage;
  };
  effil = super.callPackage ./effil.nix {
    inherit (luasuper) lua buildLuaPackage;
  };
  # etlua = super.callPackage ./etlua.nix {
  #   inherit (luasuper) lua buildLuaPackage luarocks;
  #   inherit (luaself) shim-getpw;
  # };
  ldoc = super.callPackage ./ldoc.nix {
    inherit (luasuper) lua buildLuaPackage;
    inherit (luaself) penlight cmark-lua;
    inherit (super) makeWrapper;
  };
  linotify = super.callPackage ./linotify.nix {
    inherit (luasuper) lua buildLuaPackage;
  };
  loadkit = super.callPackage ./loadkit.nix {
    inherit (luasuper) buildLuarocksPackage;
  };
  luassert = super.callPackage ./luassert.nix {
    inherit (luasuper) lua buildLuaPackage;
    inherit (luaself) say;
  };
  luasystem = super.callPackage ./luasystem.nix {
    inherit (luasuper) lua buildLuaPackage;
  };
  lua-cliargs = super.callPackage ./lua-cliargs.nix {
    inherit (luasuper) lua buildLuaPackage;
  };
  # lua-discount = super.callPackage ./lua-discount.nix {
  #   inherit (luasuper) lua buildLuaPackage luarocks;
  #   inherit (super) discount;
  #   inherit (luaself) shim-getpw;
  # };
  lua-ev = super.callPackage ./lua-ev.nix {
    inherit (luasuper) lua buildLuaPackage;
    inherit (super) cmake;
  };
  lua-inspect = super.callPackage ./lua-inspect.nix {
    inherit (luasuper) lua buildLuaPackage;
  };
  lua-linenoise = super.callPackage ./lua-linenoise.nix {
    inherit (luasuper) lua buildLuaPackage;
  };
  lua-repl = super.callPackage ./lua-repl.nix {
    inherit (luasuper) lua buildLuaPackage;
    inherit (luaself) lua-linenoise;
  };
  lua-term = super.callPackage ./lua-term.nix {
    inherit (luasuper) lua buildLuaPackage;
  };
  # lunadoc = super.callPackage ./lunadoc.nix {
  #   inherit (luasuper) lua buildLuaPackage luarocks luafilesystem;
  #   inherit (luaself) moonscript lua-discount etlua loadkit shim-getpw;
  #   inherit (super) writeText;
  # };
  mediator_lua = super.callPackage ./mediator_lua.nix {
    inherit (luasuper) lua buildLuaPackage;
  };
  mobdebug = super.callPackage ./mobdebug.nix {
    inherit (luasuper) lua buildLuaPackage luasocket;
  };
  moonpick = super.callPackage ./moonpick.nix {
    inherit (luasuper) buildLuaPackage;
    inherit (luaself) moonscript;
  };
  moonscript = super.callPackage ./moonscript.nix rec {
    inherit (luasuper) lua buildLuarocksPackage lpeg luafilesystem;
    inherit (luaself) argparse busted loadkit;
  };
  moor = super.callPackage ./moor.nix {
    inherit (luasuper) buildLuaPackage;
    inherit (luaself) moonscript lua-linenoise lua-inspect;
  };
  penlight = super.callPackage ./penlight.nix {
    inherit (luasuper) lua buildLuaPackage luafilesystem;
  };
  say = super.callPackage ./say.nix {
    inherit (luasuper) lua buildLuaPackage;
  };
})
