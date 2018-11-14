{ stdenv, buildLuaPackage, fetchFromGitHub
, lua, luarocks
, makeWrapper
, lpeg, luafilesystem, argparse #,  linotify
}:
buildLuaPackage rec {
  name = "moonscript-${version}";
  version = "unstable-2018-06-08";
  src = fetchFromGitHub {
    owner = "leafo"; repo = "moonscript";
    rev = "dd2d041b5e35ac89bee450e84ed5f58dfd6dbe39";
    sha256 = "13ilhvhbq4phfmz0fs0ba4lrzza7dfn6q7vzvaz3fl7ylbfkwwj2";
  };

  inherit (lua) luaversion;

  buildInputs = [
    lua luarocks
    makeWrapper
  ];

  propagatedBuildInputs = luaDeps;

  luaDeps = [
    lpeg luafilesystem argparse
  ];

  makeFlags = [
    "LUA=${lua}/bin/lua"
  ];

  patchPhase = ''
    sed -s -i -e 's|.PHONY: test local|.PHONY: local|g' Makefile
    sed -s -i -e 's|^test:$||g' Makefile
    sed -s -i -e 's|^	busted$||g' Makefile
  '';

  installPhase = let
    luaPath = "$out/share/lua/${luaversion}";
  in ''
    install -d $out/bin
    install -m 0555 bin/moon $out/bin/
    install -m 0555 bin/moonc $out/bin/

    install -d ${luaPath}/
    cp -rv moon moonscript ${luaPath}/

    for prog in $out/bin/*; do
      wrapProgram $prog                                       \
        --prefix LUA_PATH  ';' "${luaPath}/?.lua;$LUA_PATH"   \
        --prefix LUA_CPATH ';' "$LUA_CPATH"
    done
  '';

  doCheck = false;

  meta = with stdenv.lib; {
    homepage = https://moonscript.org/;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
  };
}
