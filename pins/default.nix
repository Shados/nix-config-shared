{
  nur = let
    rev = "fe3049efdf10d72eea0385c05dfb30fa516346f5";
    sha256 = "0jmw4lrwhajz4a2r0viy2cp3hzv0n4a1f9ydldawl9s57rc3lnv9";
  in builtins.fetchTarball {
    url = "https://github.com/nix-community/NUR/archive/${rev}.tar.gz";
    inherit sha256;
  };
}
