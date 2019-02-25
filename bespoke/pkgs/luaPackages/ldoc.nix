{ stdenv, lua, buildLuaPackage
, penlight, cmark-lua
, fetchFromGitHub, makeWrapper
}:
buildLuaPackage rec {
  name = "${pname}-${version}";
  pname = "LDoc";
  version = "unstable-2018-02-20";

  # src = fetchFromGitHub {
  #   owner = "stevedonovan"; repo = "LDoc";
  #   rev = "f91c3182cf0b3ac29a8f677491aa32493067b5e1";
  #   sha256 = "0gmgj8pd6h79r72a9jxd6fmj148hvs76yw0x6sz0fj1iwdf3lfjm";
  # };
  # src = ~/technotheca/media/software/source/LDoc;
  # My fork has commonmark support + more
  src = fetchFromGitHub {
    owner = "Shados"; repo = "LDoc";
    rev = "50d268a2387597c813fea6b060c5d08742dcf58a";
    sha256 = "1ji85nqjgdzr2p00a7hkxwg1bckixaqrsxxc3rq76giwaf8s16q9";
  };

  nativeBuildInputs = [
    makeWrapper
  ];
  propagatedBuildInputs = [
    penlight cmark-lua
  ];

  buildPhase = ":";
  installPhase = let
    luaPath = "$out/share/lua/${lua.luaversion}";
  in ''
    lvl=1; msg="  -> Lua modules"; echo "@nix { \"action\": \"msg\", \"level\": $lvl, \"msg\": \"$msg\" }" >&$NIX_LOG_FD
    mkdir -p ${luaPath}/
    cp -r ldoc ${luaPath}/

    lvl=1; msg="  -> Binaries"; echo "@nix { \"action\": \"msg\", \"level\": $lvl, \"msg\": \"$msg\" }" >&$NIX_LOG_FD
    mkdir -p $out/bin
    install -m 0555 ldoc.lua $out/bin/ldoc

    lvl=1; msg="  -> Wrapping binaries"; echo "@nix { \"action\": \"msg\", \"level\": $lvl, \"msg\": \"$msg\" }" >&$NIX_LOG_FD
    for bin in $out/bin/*; do
      wrapProgram $bin \
        --prefix LUA_PATH  ';' "${luaPath}/?/init.lua;${luaPath}/?.lua;$LUA_PATH;" \
        --prefix LUA_CPATH ';' "$LUA_CPATH;"
    done
  '';

  meta = with stdenv.lib; {
    description = "A Lua Documentation Tool";
    homepage = http://stevedonovan.github.com/ldoc;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
    license = licenses.mit;
  };
}

