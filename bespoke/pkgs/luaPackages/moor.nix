{ stdenv, moonscript, buildLuaPackage
, fetchFromGitHub, makeWrapper, writeText
, lua-linenoise, lua-inspect
}:

let
  moor-bin = writeText "moor" ''
    #!/usr/bin/env moon

    print("Package.path:")
    print(package.path)

    if (require'moor.opts') {}, {k, v for k, v in pairs arg}
      moor = require'moor'

      L = require'linenoise'
      histfile = os.getenv"HOME" .. "/.moor_history"

      unless L.historyload histfile
        moor.printerr "failed to load commandline history"

      moor()

      unless L.historysave histfile
        moor.printerr "failed to save commandline history"

      os.exit env.MOOR_EXITCODE
  '';
in

buildLuaPackage rec {
  name = "moor-${version}";
  version = "v5.0";

  src = fetchFromGitHub {
    owner = "Nymphium"; repo = "moor";
    rev = version;
    sha256 = "0m4yynl07l4r0d27a1d7689f4bwi6a794xz87mijqnpf4irk9rvj";
  };

  buildPhase = ":";
  buildInputs = [
    makeWrapper
  ];
  propagatedBuildInputs = [
    moonscript
    lua-linenoise
    lua-inspect
  ];
  installPhase = let
    luaPath = "$out/share/lua/${moonscript.luaversion}";
  in ''
    install -d $out/bin
    install -d ${luaPath}/moor

    for f in moor/*; do
      moonc $f
    done
    for f in moor/*; do
      install -m 0444 $f ${luaPath}/moor/
    done

    install -m 0555 bin/moor.moon $out/bin/moor
    # install -m 0555 ${moor-bin} $out/bin/moor
    install -m 0444 moor/init.moon ${luaPath}/moor.moon
    install -m 0444 moor/init.lua ${luaPath}/moor.lua

    wrapProgram $out/bin/moor \
      --prefix LUA_PATH  ';' "${luaPath}/?/init.lua;${luaPath}/?.lua;$LUA_PATH;"   \
      --prefix LUA_CPATH ';' "$LUA_CPATH;"
  '';

  meta = with stdenv.lib; {
    description = "MoonScript REPL";
    homepage = https://github.com/Nymphium/moor;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
  };
}
