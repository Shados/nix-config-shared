{ stdenv, lua, buildLuaPackage
, fetchurl, unzip
}:
buildLuaPackage rec {
  name = "luasystem-${version}";
  version = "0.2.1-0";

  src = fetchurl {
    url = "https://luarocks.org/manifests/olim/${name}.src.rock";
    sha256 = "091xmp8cijgj0yzfsjrn7vljwznjnjn278ay7z9pjwpwiva0diyi";
  };

  unpackPhase = ''
    ${unzip}/bin/unzip $src
    ls -la
    tar xvf v0.2.1.tar.gz
    cd luasystem-0.2.1/
  '';

  makeFlags = [
    "LUA_VERSION=${lua.luaversion}"
    "LUAINC_linux_base=$(out)/include"
    "LUAPREFIX_linux=$(out)"
  ];

  postInstall = let
    luaPath = "$out/share/lua/${lua.luaversion}";
  in ''
    install -d ${luaPath}/system/
    install -m 0444 system/init.lua ${luaPath}/system/
  '';

  meta = with stdenv.lib; {
    description = "Adds a Lua API for making platform independent system calls.";
    homepage = https://luarocks.org/modules/olim/luasystem;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
    license = licenses.mit;
  };
}
