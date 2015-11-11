{ stdenv, fetchurl, openssh, rsync }:

stdenv.mkDerivation rec {
  name = "rssh-${version}";
  version = "2.3.4";

  src = fetchurl {
    url = "mirror://sourceforge/rssh/rssh/${version}/${name}.tar.gz";
    sha256 = "f30c6a760918a0ed39cf9e49a49a76cb309d7ef1c25a66e77a41e2b1d0b40cd9";
  };

  patches = [
    ./0001-fail-logging.patch
    ./0002-info-to-debug.patch
    ./0003-man-page-spelling.patch
    ./0004-mkchroot.patch
    ./0005-mkchroot-arch.patch
    ./0006-mkchroot-symlink.patch
    ./0007-destdir.patch
    ./0008-rsync-protocol.patch
    ./fix-config-path.patch
  ];

  buildInputs = [ openssh rsync ];

  configureFlags = [
    "--with-sftp-server=${openssh}/libexec/sftp-server"
    "--with-scp=${openssh}/bin/scp"
    "--with-rsync=${rsync}/bin/rsync"
  ];


  meta = with stdenv.lib; {
    description = "rssh is a restricted shell for use with OpenSSH, allowing only scp and/or sftp.";
    longDescription = ''
      It also includes support for rdist, rsync, and cvs. For example, if you have a server which you only want to allow users to copy files off of via scp, without providing shell access, you can use rssh to do that.
    '';
    homepage = "http://www.pizzashack.org/rssh/";
    license = licenses.bsd2;
    platforms = platforms.unix;
    maintainers = with maintainers; [ arobyn ];
  };
}
