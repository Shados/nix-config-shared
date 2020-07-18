{
  nur = let
    rev = "b824ad0cbc68e2eb1e25031fc7b29af19a59cc1b";
    sha256 = "179dw1lciq4ihlxgz1d5b3b41hzz9vldya2m3ampv9wc1a3aqai9";
  in builtins.fetchTarball {
    url = "https://github.com/nix-community/NUR/archive/${rev}.tar.gz";
    inherit sha256;
  };
}
