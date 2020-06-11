{
  nur = let
    rev = "74a76c41be4606f1f79acf556625927374863d4c";
    sha256 = "17z3njzk1vyfwm1512yy799i97vcfrxj4d8jf3865wja87ins2zk";
  in builtins.fetchTarball {
    url = "https://github.com/nix-community/NUR/archive/${rev}.tar.gz";
    inherit sha256;
  };
}
