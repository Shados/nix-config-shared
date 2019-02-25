{ stdenv, buildLuarocksPackage, fetchFromGitHub
, lua
, makeWrapper
, lpeg, luafilesystem, argparse
, busted, loadkit # check-phase inputs; not propagated
}:
# buildLuaPackage rec {
#   name = "moonscript-${version}";
#   version = "unstable-2018-06-08";
#   src = fetchFromGitHub {
#     owner = "Shados"; repo = "moonscript";
#     rev = "dfb6fbe76505521e32970046b04d5f6a9ec1b067";
#     sha256 = "1frdqljgw4mk5h7nq8bak8axx6nn6fl0jhhxk93g1dnkr9grfbqi";
#   };

#   inherit (lua) luaversion;

#   buildInputs = [
#     lua luarocks
#     makeWrapper
#     # busted loadkit
#   ];

#   propagatedBuildInputs = luaDeps;

#   luaDeps = [
#     lpeg luafilesystem argparse
#   ];

#   preBuild = ''
#     # Avoid Luarocks warnings
#     export HOME=$(pwd)
#     export USER=$(id -un)

#     # Compile using the local moonc, as we don't have a system one available
#     make compile $makeFlags
#   '';
#   buildPhase = ''
#     make $makeFlags
#   '';

#   makeFlags = [
#     "LUA=${lua}/bin/lua"
#     "LUAROCKS=luarocks"
#   ];

#   installPhase = let
#     luaPath = "$out/share/lua/${luaversion}";
#   in ''
#     install -d $out/bin
#     install -m 0555 bin/moon $out/bin/
#     install -m 0555 bin/moonc $out/bin/

#     install -d ${luaPath}/
#     cp -rv moon moonscript ${luaPath}/

#     for prog in $out/bin/*; do
#       wrapProgram $prog                                       \
#         --prefix LUA_PATH  ';' "${luaPath}/?.lua;$LUA_PATH"   \
#         --prefix LUA_CPATH ';' "$LUA_CPATH"
#     done
#   '';

#   doCheck = true;

#   meta = with stdenv.lib; {
#     homepage = https://moonscript.org/;
#     description = "A language that compiles to Lua";
#     maintainers = with maintainers; [ arobyn ];
#     license = with licenses; mit;
#     hydraPlatforms = platforms.linux;
#   };
# }

buildLuarocksPackage {
  pname = "moonscript";
  version = "unstable-2018-02-18";

  src = fetchFromGitHub {
    owner = "Shados"; repo = "moonscript";
    rev = "623bb0fc5d0d23c05caf0c8ffded6ef751baf366";
    sha256 = "05kpl9l1311lgjrfghnqnh6m3zkwp09gww056bf30fbvhlfc8iyw";
  };
  # disabled = ( luaOlder "5.1");
  buildInputs = [
    makeWrapper
  ];
  propagatedBuildInputs = [
    lua lpeg luafilesystem argparse
  ];

  doCheck = true;
  checkInputs = [
    busted loadkit
  ];
  checkPhase = ''
    make test $makeFlags
  '';

  knownRockspec = "moonscript-dev-1.rockspec";

  preBuild = ''
    export HOME=$(pwd)
    export USER=$(id -un)
  '';

  buildType = "builtin";

  inherit (lua) luaversion;

  meta = with stdenv.lib; {
    homepage = https://moonscript.org/;
    description = "A language that compiles to Lua";
    maintainers = with maintainers; [ arobyn ];
    license = with licenses; mit;
    hydraPlatforms = platforms.linux;
  };
}
