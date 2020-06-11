{
  nur = let
    rev = "c31c1ebffd12a04db46869751b5e957df177ae95";
    sha256 = "0kwd9i49ggd0cqlpl5h9pcjwpm6xkcl86cx1g1spg9g9vljmjr85";
  in builtins.fetchTarball {
    url = "https://github.com/nix-community/NUR/archive/${rev}.tar.gz";
    inherit sha256;
  };
}
