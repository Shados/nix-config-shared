# Fish git prompt
set __fish_git_prompt_showdirtystate 'yes'
set __fish_git_prompt_showstashstate 'yes'
set __fish_git_prompt_showuntrackedfiles 'yes'
set __fish_git_prompt_showupstream 'yes'
set __fish_git_prompt_color_branch bryellow
set __fish_git_prompt_color_upstream_ahead green
set __fish_git_prompt_color_upstream_behind red

# Status Chars
set __fish_git_prompt_char_dirtystate '⚡'
set __fish_git_prompt_char_stagedstate '→'
set __fish_git_prompt_char_untrackedfiles '☡'
set __fish_git_prompt_char_stashstate '↩'
set __fish_git_prompt_char_upstream_ahead '+'
set __fish_git_prompt_char_upstream_behind '-'

# Colors
if not set -q __fish_prompt_normal
  set -g __fish_prompt_normal (set_color $fish_color_normal)
end

function fish_prompt
  # Handle colouring the prompt
  # Color hostname differently if system is being accessed over SSH
  if set -q SSH_TTY
    set -g fish_color_host $fish_color_cwd_root
  else
    set -g fish_color_host normal
  end
  set -g __fish_prompt_hostname (set_color $fish_color_host)$hostname(set_color $fish_color_normal)

  switch $USER
    case root
      if not set -q __fish_prompt_cwd
        if set -q fish_color_cwd_root
          set -g __fish_prompt_cwd (set_color $fish_color_cwd_root)
        else
          set -g __fish_prompt_cwd (set_color $fish_color_cwd)
        end
      end
      if not set -q __fish_prompt_user
        set -g __fish_prompt_user (set_color $fish_color_error)$USER(set_color $fish_color_normal)
      end
      if not set -q __fish_prompt_separator
        set -g __fish_prompt_separator (set_color $fish_color_error)'#'(set_color $fish_color_normal)
      end
    case '*'
      if not set -q __fish_prompt_cwd
        set -g __fish_prompt_cwd (set_color $fish_color_cwd)
      end
      if not set -q __fish_prompt_user
        set -g __fish_prompt_user (set_color $fish_color_command)$USER(set_color $fish_color_normal)
      end
      if not set -q __fish_prompt_separator
        set -g __fish_prompt_separator (set_color $fish_color_normal)' λ'(set_color $fish_color_normal)
      end
  end

  set __fish_prompt_pwd $__fish_prompt_cwd(prompt_pwd)(set_color $fish_color_normal)
  set __fish_prompt_pwd (printf '%s%s' "$__fish_prompt_pwd" (__fish_git_prompt))

  # Args list: username, hostname, current-dir info, prompt char/separator
  # Each is colorised already and resets to 'normal' after their content, so
  # we don't have to worry about colors here
  printf '%s@%s[%s]%s ' \
    "$__fish_prompt_user" \
    "$__fish_prompt_hostname" \
    "$__fish_prompt_pwd" \
    "$__fish_prompt_separator"
end
