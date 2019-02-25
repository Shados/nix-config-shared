{ stdenv, lua, buildLuaPackage
, fetchFromGitHub
, pkgconfig, inotify-tools
}:
buildLuaPackage rec {
  name = "linotify-${version}";
  version = "0.5";

  src = fetchFromGitHub {
    owner = "hoelzro"; repo = "linotify";
    rev = version;
    sha256 = "19i23fqxrdybirxkk9qdy22apiiyag1k43gqvs8v7kbmdin8jlr2";
  };

  nativeBuildInputs = [
    pkgconfig
  ];
  buildInputs = [
    inotify-tools
  ];

  installFlags = [
    "INSTALL_PATH=$(out)/lib/lua/${lua.luaversion}"
    "NAK=nak"
  ];

  # buildPhase = ":";
  # installPhase = let
  #   luaPath = "$out/share/lua/${lua.luaversion}";
  # in ''
  #   install -d ${luaPath}
  #   install -m 0444 inspect.lua ${luaPath}/
  # '';

  meta = with stdenv.lib; {
    description = "Inotify bindings for Lua.";
    homepage = https://github.com/hoelzro/linotify;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
  };
}

