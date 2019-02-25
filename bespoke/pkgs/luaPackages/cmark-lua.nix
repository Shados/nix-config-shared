{ stdenv, lua, buildLuarocksPackage
, fetchFromGitHub
, cmark
}:
# buildLuaPackage rec {
#   name = "${pname}-${version}";
#   pname = "cmark-lua";
#   version = "0.28.3";

#   src = fetchFromGitHub {
#     owner = "jgm"; repo = "cmark-lua";
#     rev = version;
#     sha256 = "0qhrgl96jpi1c8l331dxnjn81x721lb748vb86mv9n2kgf8maz70";
#   };

#   nativeBuildInputs = [
#     luarocks
#   ];
#   buildInputs = [
#     cmark
#   ];

#   preBuild = let
#     getpw-preload = "${shim-getpw}/lib/libshim-getpw.so";
#   in ''
#     # Configure shim-getpw to prevent spurious luarocks warning, and point it to
#     # the right home directory
#     export LD_PRELOAD="${getpw-preload}''${LD_PRELOAD:+ ''${LD_PRELOAD}}"
#     export HOME=$(pwd)
#     export SHIM_HOME=$HOME
#     export USER=$(id -un)
#     export SHIM_USER=$USER
#     export SHIM_UID=$UID

#     # Tell luarocks to install to $out
#     substituteInPlace Makefile --replace 'luarocks --local make' 'luarocks --tree $(out) make'
#   '';
#   installPhase = ":";

#   meta = with stdenv.lib; {
#     description = "Lua wrapper for libcmark, CommonMark Markdown parsing
# and rendering library";
#     homepage = https://github.com/jgm/cmark-lua;
#     hydraPlatforms = platforms.linux;
#     maintainers = with maintainers; [ arobyn ];
#     license = licenses.bsd2;
#   };
# }

buildLuarocksPackage rec {
  pname = "cmark-lua";
  version = "0.28.3";
  revision = "1";

  src = fetchFromGitHub {
    owner = "jgm"; repo = "cmark-lua";
    rev = version;
    sha256 = "0qhrgl96jpi1c8l331dxnjn81x721lb748vb86mv9n2kgf8maz70";
  };

  buildInputs = [
    cmark
  ];

  knownRockspec = "cmark-${version}-${revision}.rockspec";
  preConfigure = ''
    export HOME=$(pwd)
    export USER=$(id -un)
    # For some reason make needs "" around the version, even though the
    # resultant file name does not include literal "s
    make 'cmark-"${version}"-${revision}.rockspec' $makeFlags
  '';

  meta = with stdenv.lib; {
    description = "Lua wrapper for libcmark, CommonMark Markdown parsing
and rendering library";
    homepage = https://github.com/jgm/cmark-lua;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
    license = licenses.bsd2;
  };
}

