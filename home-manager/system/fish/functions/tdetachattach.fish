function tdetachattach
  set -l session_number $argv[1]

  tmux detach-client -s $session_number; and tmux attach-session -t $session_number
end

