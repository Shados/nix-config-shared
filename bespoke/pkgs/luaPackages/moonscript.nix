{ stdenv, buildLuarocksPackage, fetchFromGitHub
, lua
, makeWrapper
, lpeg, luafilesystem, argparse
, busted, loadkit # check-phase inputs; not propagated
}:

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
