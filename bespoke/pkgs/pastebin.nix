{ writeScriptBin, fish, curl, xclip, libnotify }:

writeScriptBin "pastebin" ''
#!${fish}/bin/fish
${curl}/bin/curl -F"file=@/dev/stdin" https://0x0.st | ${xclip}/bin/xclip -selection clipboard; and ${libnotify}/bin/notify-send -t 3000 "0x0 paste link ready for copying"
''
