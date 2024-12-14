{ lib, mkPoetryApplication }:
{ python, src, doCheck ? true }:
with lib;
let
  metadata = (builtins.fromTOML (builtins.readFile "${src}/pyproject.toml")).tool.poetry;
in
mkPoetryApplication rec {
  inherit src python doCheck;
  pyproject = "${src}/pyproject.toml";
  poetrylock = "${src}/poetry.lock";

  meta = {
    maintainers = metadata.maintainers or metadata.authors;
    description = metadata.description;
  } // optionalAttrs (metadata ? repository) { downloadPage = metadata.repository; };
}
