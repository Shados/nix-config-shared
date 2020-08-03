{
  nur = let
    rev = "a35bcadb2c9eabd9f4f84f0c5b50c3ee9b89962b";
    sha256 = "150m3nl8klmx0xzrrwn0xnh2ahigvd6f8793d9hw51z6anccpp52";
  in builtins.fetchTarball {
    url = "https://github.com/nix-community/NUR/archive/${rev}.tar.gz";
    inherit sha256;
  };
}
