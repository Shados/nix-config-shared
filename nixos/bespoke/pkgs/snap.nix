{
  stdenv,
  lib,
  writeScriptBin,
  fish,
  maim,
  xdotool,
  libnotify,
  pastebin,
}:

let
  screenshot_dir = "~/technotheca/artifacts/media/images/screenshots";
  bin = {
    maim = "${maim}/bin/maim";
    pb = "${pastebin}/bin/pastebin";
    xdot = "${xdotool}/bin/xdotool";
    notify = "${libnotify}/bin/notify-send";
  };

  mkSnapScript =
    name: args:
    writeScriptBin name (
      let
        mapAttrsToStringSep =
          sep: mapFn: attrs:
          lib.concatStringsSep sep (lib.mapAttrsToList mapFn attrs);
        mkArgFlag = argname: argval: "-${argname}${if (!isNull argval) then " ${argval}" else ""}";
        mkSnapLine = args: "${bin.maim} ${mapAttrsToStringSep " " mkArgFlag args}";
      in
      ''
        #!${fish}/bin/fish

        if test (count $argv) -gt 0
          if test $argv[1] = "-l"
            set -l ss_path ${screenshot_dir}/(hostname)-(date +%F-%T).png
            ${mkSnapLine args} $ss_path | ${bin.notify} -t 3000 "Screenshot saved to $ss_path"
          else
            echo "Unrecognized argument $argv[1]"
          end
        else
          ${mkSnapLine args} | ${bin.pb}
        end
      ''
    );

  scripts = [
    (mkSnapScript "snap" { i = "(${bin.xdot} getactivewindow)"; })
    (mkSnapScript "snapregion" { s = null; })
  ];
in
stdenv.mkDerivation rec {
  name = "snap-utils";

  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out/bin/
    ${lib.concatMapStringsSep "\n" (script: ''
      cp -r ${script}/bin/* $out/bin/
    '') scripts}
    chmod +x $out/bin/*
  '';
}
