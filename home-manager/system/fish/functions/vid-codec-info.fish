function vid-codec-info -d "Prints useful video codec info for a given video file"
  if test (count $argv) -lt 1
    echo "Please supply a video to examine"
    return 1
  end

  set -l vid $argv[1]
  ffprobe -show_streams -i "$vid" ^ /dev/null | pipeset raw_info
  echo $raw_info | grep --color=never -E "((bits_per_(raw_)?sample|width|height)=[1-9])|index=0\ncodec_name"
  echo $raw_info | head -n3 | grep --color=never codec_name
end
