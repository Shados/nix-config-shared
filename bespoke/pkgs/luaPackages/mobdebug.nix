{ stdenv, lua, buildLuaPackage
, luasocket
, fetchFromGitHub
}:
buildLuaPackage rec {
  name = "mobdebug-${version}";
  version = "unstable-2018-06-20";

  src = fetchFromGitHub {
    owner = "pkulchenko"; repo = "MobDebug";
    rev = "7acfc6f9af339e486ae2390e66185367bbf6a0cd";
    sha256 = "0hsq9micb7ic84f8v575drz49vv7w05pc9yrq4i57gyag820p2kl";
  };

  propagatedBuildInputs = [
    luasocket
  ];

  buildPhase = ":";
  installPhase = let
    luaPath = "$out/share/lua/${lua.luaversion}";
  in ''
    mkdir -p ${luaPath}

    cp -r src/mobdebug.lua ${luaPath}/
  '';

  meta = with stdenv.lib; {
    description = "MobDebug is a remote debugger for Lua";
    homepage = https://github.com/pkulchenko/MobDebug;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
    license = with licenses; mit;
  };
}
