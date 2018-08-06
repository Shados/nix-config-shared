let
  nixpkgs = import <nixpkgs> { };
in
{ stdenv ? nixpkgs.pkgs.stdenv
, runCommand ? nixpkgs.runCommand
, perl ? nixpkgs.perl
}:
runCommand "produce-local-optimization-patchline" rec {
  # This derivation MUST be run on the local system, because it has an
  # **impure** dependency on the current CPU hardware -- that's the whole
  # frelling point.
  allowSubstitutes = false;
  preferLocalBuild = true;
  nativeStdenv = stdenv.override {
    preHook = ''
      # Re-creating the original hooks... sadly.
      commonStripFlags="--enable-deterministic-archives"
      # Allow use of -march=native and friends.
      export NIX_ENFORCE_NO_NATIVE=
      # We should still enforce the *other* purity checks, just in case.
      export NIX_ENFORCE_PURITY="''${NIX_ENFORCE_PURITY-1}"
    '';
  };
  gcc = nativeStdenv.cc;
  inherit perl;
} ''
  # Raw space-separated list of options
  # $gcc/bin/gcc -march=native -E -v - </dev/null 2>&1 | grep cc1 | $perl/bin/perl -pe 's/^.*? - (.*)$/\1/g' > $out

  # Option list in the format used inside the kernel Makefile
  echo -n "\$(call cc-option" > $out
  for opt in $($gcc/bin/gcc -march=native -E -v - </dev/null 2>&1 | grep cc1 | $perl/bin/perl -pe 's/^.*? - (.*)$/\1/g'); do
    echo -n ",$opt" >> $out
  done
  echo -n ")" >> $out
''
