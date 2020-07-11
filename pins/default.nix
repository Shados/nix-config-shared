{
  nur = let
    rev = "d64835bf14e6c0c8947d7d00a94b7f6604cefe20";
    sha256 = "1b8y2fjkvv1bhbgglkvp0rbl6dn7794rajn8pxkj644s7bl33rym";
  in builtins.fetchTarball {
    url = "https://github.com/nix-community/NUR/archive/${rev}.tar.gz";
    inherit sha256;
  };
}
