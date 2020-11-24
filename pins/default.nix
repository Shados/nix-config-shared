{
  nur = let
    rev = "b817b02b78c8355f68905a7b0b2f67a017eedec3";
    sha256 = "1yic6775nsy4x997rdq34dr5n3rm7h83xlyw5q7a9mcns1rbdycf";
  in builtins.fetchTarball {
    url = "https://github.com/nix-community/NUR/archive/${rev}.tar.gz";
    inherit sha256;
  };
}
