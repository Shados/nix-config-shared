{
  nur = let
    rev = "4740d551cab6fc938b9b2a5bc507673c39a44514";
    sha256 = "1gks9myszs5wb72rxyks85azw90y9ndpfzzqcf2g27azc9vlqkzb";
  in builtins.fetchTarball {
    url = "https://github.com/nix-community/NUR/archive/${rev}.tar.gz";
    inherit sha256;
  };
}
