{
  shados-nur = let
    rev = "1f8e6e08d202d9ae57aa75e440185157944505f8";
    sha256 = "165905mjgf2kp24gjd6yqg8kh9x08gjjkkymh1jk0w6sq3mhvld8";
  in builtins.fetchTarball {
    url = "https://github.com/Shados/nur-packages/archive/${rev}.tar.gz";
    inherit sha256;
  };
}
