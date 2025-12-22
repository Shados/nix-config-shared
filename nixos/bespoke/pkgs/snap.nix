{
  stdenv,
  lib,
  writeScriptBin,
  writers,
  fish,
  maim,
  xdotool,
  libnotify,
  pastebin,
}:

let
  screenshot_dir = "$HOME/technotheca/artifacts/media/images/screenshots";
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
            ${mkSnapLine args} $ss_path && ${bin.notify} -t 3000 "Screenshot saved to $ss_path"
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
    (writers.writeBashBin "snapscreen" ''
      ss_path="${screenshot_dir}/$(hostname)-$(date +%F-%T).png"
      MONITORS=$(xrandr | grep -o '[0-9]*x[0-9]*[+-][0-9]*[+-][0-9]*')
      # Get the location of the mouse
      XMOUSE=$(xdotool getmouselocation | awk -F "[: ]" '{print $2}')
      YMOUSE=$(xdotool getmouselocation | awk -F "[: ]" '{print $4}')

      for mon in ''${MONITORS}; do
        # Parse the geometry of the monitor
        MONW=$(echo ''${mon} | awk -F "[x+]" '{print $1}')
        MONH=$(echo ''${mon} | awk -F "[x+]" '{print $2}')
        MONX=$(echo ''${mon} | awk -F "[x+]" '{print $3}')
        MONY=$(echo ''${mon} | awk -F "[x+]" '{print $4}')
        # Use a simple collision check
        if (( ''${XMOUSE} >= ''${MONX} )); then
          if (( ''${XMOUSE} <= ''${MONX}+''${MONW} )); then
            if (( ''${YMOUSE} >= ''${MONY} )); then
              if (( ''${YMOUSE} <= ''${MONY}+''${MONH} )); then
                # We have found our monitor!
                ${bin.maim} -g "''${MONW}x''${MONH}+''${MONX}+''${MONY}" "$ss_path" && ${bin.notify} -t 3000 "Screenshot saved to $ss_path"
                exit 0
              fi
            fi
          fi
        fi
      done
    '')
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
