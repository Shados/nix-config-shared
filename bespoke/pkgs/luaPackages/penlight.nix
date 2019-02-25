{ stdenv, lua, buildLuaPackage
, luafilesystem
, fetchFromGitHub
}:
buildLuaPackage rec {
  name = "${pname}-${version}";
  pname = "penlight";
  version = "unstable-2019-01-08";

  src = fetchFromGitHub {
    owner = "stevedonovan"; repo = "Penlight";
    rev = "f9f06de79e87f64a839bc01cb2d80201b53e3047";
    sha256 = "0dydidx0fi23d75p89hiqbw9jxnknjbz8yh0smcsqq4pprfb4dr8";
  };

  propagatedBuildInputs = [
    luafilesystem
  ];

  buildPhase = ":";
  installPhase = let
    luaPath = "$out/share/lua/${lua.luaversion}";
  in ''
    install -d ${luaPath}/
    cp -r lua/pl ${luaPath}/
  '';

  meta = with stdenv.lib; {
    description = "Lua utility libraries loosely based on the Python standard libraries";
    homepage = https://github.com/stevedonovan/Penlight;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
    license = licenses.mit;
  };
}
