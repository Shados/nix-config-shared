{ stdenv, makeWrapper, writeScript, llvmPackages }:

let
  clang = llvmPackages.clang-unwrapped;
  version = stdenv.lib.getVersion clang;
in

stdenv.mkDerivation {
  name = "clangd-${version}";
  builder = writeScript "builder" ''
    source $stdenv/setup
    makeWrapper $clang/bin/clangd $out/bin/clangd --argv0 clangd
  '';
  buildInputs = [ makeWrapper ];
  inherit clang;
  meta = clang.meta // {
    description = "An implementation of the Language Server Protocol leveraging Clang.";
    maintainers = with stdenv.lib.maintainers; [ arobyn ];
  };
}
