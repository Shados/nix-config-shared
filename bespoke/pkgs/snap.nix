{ writeScriptBin, fish, maim, xdotool, pastebin }:

writeScriptBin "snap" ''
#!${fish}/bin/fish

${maim}/bin/maim -i (${xdotool}/bin/xdotool getactivewindow) | ${pastebin}/bin/pastebin
''
