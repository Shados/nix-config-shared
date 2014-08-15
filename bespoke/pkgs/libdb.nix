{ stdenv, fetchurl, pkgconfig }:

# Builds with the C & C++ APIs
stdenv.mkDerivation rec {
  name = "libdb-${version}";
  version = "4.8.30";

  src = fetchurl {
    url = "http://download.oracle.com/berkeley-db/db-${version}.NC.tar.gz";
    # Generate hash with nix-hash --base32 --flat --type sha256 ${file}
    sha256 = "1vv4hdwk4mxqh6iacxjz5v5l43z5rrdpj8gqh9zvv6mzfpgw1v8j";
  };

  preConfigure = ''
    cd build_unix
  '';
  configureScript = "../dist/configure";
  configureFlags = "--enable-cxx";

  meta = {
    description = "High-performance embedded database for key/value data";
    homepage = http://www.oracle.com/technetwork/database/database-technologies/berkeleydb/overview/index.html;
    license = stdenv.lib.licenses.agpl3;
    platforms = stdenv.lib.platforms.unix;
  };
}
