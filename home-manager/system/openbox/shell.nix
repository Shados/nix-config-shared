{
  nixpkgs ? import <nixpkgs> { },
}:
with nixpkgs;
mkShell {
  buildInputs = [
    libxslt
    libxml2
    saxonb_9_1
  ];
}
