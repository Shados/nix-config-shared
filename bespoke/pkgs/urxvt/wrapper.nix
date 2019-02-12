{ stdenv, makePerlPath, symlinkJoin, rxvt_unicode, makeWrapper, plugins }:

let
  rxvt_name = builtins.parseDrvName rxvt_unicode.name;
  extraLibs = builtins.concatLists (map (x: x.extraLibs or []) plugins);
  perlPaths = stdenv.lib.concatStringsSep " " (map (x: makePerlPath [x]) extraLibs);
in
symlinkJoin {
  name = "${rxvt_name.name}-with-plugins-${rxvt_name.version}";

  paths = [ rxvt_unicode ] ++ plugins ++ extraLibs;

  buildInputs = [ makeWrapper ];

  postBuild = ''
    wrapProgram $out/bin/urxvt \
      --suffix-each URXVT_PERL_LIB  ':' "$out/lib/urxvt/perl" \
      --suffix-each PERL5LIB        ':' "${perlPaths}"
    wrapProgram $out/bin/urxvtd \
      --suffix-each URXVT_PERL_LIB  ':' "$out/lib/urxvt/perl" \
      --suffix-each PERL5LIB        ':' "${perlPaths}"
  '';

  passthru.plugins = plugins;
}
