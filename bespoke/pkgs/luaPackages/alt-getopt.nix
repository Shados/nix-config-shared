{ stdenv, buildLuaPackage, fetchurl
, writeText
}:
buildLuaPackage rec {
  name = "alt-getopt-${version}";
  version = "0.7.0";
  src = fetchurl {
    url = "http://files.luaforge.net/releases/alt-getopt/alt-getopt/alt-getopt-${version}/lua-alt-getopt-${version}.tar.gz";
    sha256 = "0khhhwrzyw3j67k3fdk8dl020yzkl6kcs2lm8fvh7gsny2vgvmf0";
  };

  makeFile = writeText "Makefile" ''
    install: alt_getopt.lua
    	install -d $(LUA_LIBDIR)
    	install -m 444 alt_getopt.lua $(LUA_LIBDIR)
  '';
  doCheck = true;
  configurePhase = ''
    cp $makeFile Makefile
  '';
  # buildPhase = ":";
  # installPhase = ":";

  meta = with stdenv.lib; {
    homepage = http://luaforge.net/projects/alt-getopt/;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
  };
}
