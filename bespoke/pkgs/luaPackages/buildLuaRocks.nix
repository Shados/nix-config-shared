{ stdenv, coreutils, makeWrapper, lua, luarocks }:
let
  lr = luarocks.override { inherit lua; };
  inherit (stdenv) lib;
in
{ rockspec ? "", luadeps ? [] , buildInputs ? []
, preBuild ? "" , postInstall ? ""
, runtimeDeps ? [] ,  ... }@args :
let
  luadeps_ =
    luadeps ++
    (lib.concatMap (d : if d ? luadeps then d.luadeps else []) luadeps);

  runtimeDeps_ =
    runtimeDeps ++
    (lib.concatMap (d : if d ? runtimeDeps then d.runtimeDeps else []) luadeps) ++
    [ lua coreutils ];

  mkcfg = ''
    export LUAROCKS_CONFIG=config.lua
    cat >config.lua <<EOF
      rocks_trees = {
           { name = [[system]], root = [[${lr}]] }
         ${lib.concatImapStrings (i : dep :  ", { name = [[dep${toString i}]], root = [[${dep}]] }") luadeps_}
      };

      variables = {
        LUA_BINDIR = "$out/bin";
        LUA_INCDIR = "$out/include";
        LUA_LIBDIR = "$out/lib/lua/${lua.luaversion}";
      };
    EOF
  '';

in
stdenv.mkDerivation (args // {

  name = "${args.name}-${lua.luaversion}";

  inherit preBuild postInstall;

  inherit luadeps runtimeDeps;

  phases = [ "unpackPhase" "patchPhase" "buildPhase"];

  buildInputs = runtimeDeps ++ buildInputs ++ [ makeWrapper lua ];

  buildPhase = ''
    eval "$preBuild"
    ${mkcfg}
    eval "`${lr}/bin/luarocks --deps-mode=all --tree=$out path`"
    ${lr}/bin/luarocks make --deps-mode=all --tree=$out ${rockspec}

    for p in $out/bin/*; do
      wrapProgram $p \
        --suffix LD_LIBRARY_PATH ';' "${lib.makeLibraryPath runtimeDeps_}" \
        --suffix PATH ';' "${lib.makeBinPath runtimeDeps_}" \
        --suffix LUA_PATH ';' "\"$LUA_PATH\"" \
        --suffix LUA_PATH ';' "\"$out/share/lua/${lua.luaversion}/?.lua;$out/share/lua/${lua.luaversion}/?/init.lua\"" \
        --suffix LUA_CPATH ';' "\"$LUA_CPATH\"" \
        --suffix LUA_CPATH ';' "\"$out/lib/lua/${lua.luaversion}/?.so;$out/lib/lua/${lua.luaversion}/?/init.so\""
    done

    eval "$postInstall"
  '';
})
