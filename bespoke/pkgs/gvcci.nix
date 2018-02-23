{ stdenv, fetchFromGitHub, python3Packages
, bash
}:

stdenv.mkDerivation rec {
  name = "gvcci";

  src = fetchFromGitHub {
    owner           = "FabriceCastel";
    repo            = "gvcci";
    rev             = "87a4a1f235d0aa1fd250f9f0af8c1bfd9b38d469";
    sha256          = "0yld0h938xd44z2vjvlkdgcz0ii8sdkkwnfvrxrjvrga4iy0dz8b";
    fetchSubmodules = true;
  };

  propagatedBuildInputs = with python3Packages; [
    numpy scikitlearn scikitimage pystache cython dask
    hasel
    python3Packages.python
  ];

  buildInputs = [
    python3Packages.wrapPython
  ];

  #format = "other";

  installPhase = with stdenv.lib; ''
    mkdir -p $out/lib
    cp -r src/* $out/lib/
    cp -r resources $out/lib/
    cp -r templates $out/lib/

    mkdir -p $out/bin/

    # cat > $out/bin/gvcci <<EOF
    # #!/usr/bin/env python
    # import sys
    # import os
    # import subprocess
    # import inspect
    # from pathlib import Path
    #
    # def get_script_dir(follow_symlinks=True):
    #     if getattr(sys, 'frozen', False): # py2exe, PyInstaller, cx_Freeze
    #         path = os.path.abspath(sys.executable)
    #     else:
    #         path = inspect.getabsfile(get_script_dir)
    #     if follow_symlinks:
    #         path = os.path.realpath(path)
    #     return os.path.dirname(path)
    #
    # ex = Path(get_script_dir()) / '../lib/extract'
    # print("Calling {} with arguments:\n{}".format(str(ex.resolve()), sys.argv[1:]))
    # subprocess.call([ex.resolve()] + sys.argv[1:], shell=True)
    # EOF
    cat > $out/bin/gvcci <<EOF
    #!${bash}/bin/bash

    # Full path of this script
    THIS=\`readlink -f "\''${BASH_SOURCE[0]}" 2>/dev/null||echo \$0\`

    # This directory path
    DIR=\`dirname "\''${THIS}"\`

    \$DIR/../lib/extract "\$@"
    EOF

    chmod +x $out/bin/gvcci
    mv $out/lib/extract.py $out/lib/extract
    chmod +x $out/lib/extract
  '';

  postFixup = ''
    wrapPythonProgramsIn "$out/lib" "$out"
  '';


  meta = with stdenv.lib; {
    description     = "A tool to extract/generate colorschemes from images.";
    homepage        = "https://github.com/FabriceCastel/gvcci";
    maintainers     = [ maintainers.arobyn ];
    platforms       = platforms.all;
    license         = licenses.mit;
  };
}
