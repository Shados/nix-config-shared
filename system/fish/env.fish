# Set up terminal
# sbin doesn't get added to non-root users normally, but fuck that
path_append /run/current-system/sw/sbin

# Locale
# Enable UTF-8 with Australian settings
set -gx LANG "en_AU.UTF-8"

# Keep the default sort order (e.g. files starting with a '.' should appear at the start of a directory listing) 
set -gx LC_COLLATE "C"

# Set the short date to YYYY-MM-DD
set -gx LC_TIME "en_DK.UTF-8"

# Set the fallback locales
set -gx LANGUAGE "en_AU:en_GB:en_US:en"

# Tools
# Ensure less always respects terminal colour codes by default
set -gx LESS ' -R '

# Setup colours
set -gx fish_color_autosuggestion magenta --background=white
set -gx fish_color_command green
set -gx fish_color_comment normal
set -gx fish_color_cwd blue
set -gx fish_color_cwd_root red
set -gx fish_color_end yellow
set -gx fish_color_error red
set -gx fish_color_escape cyan
set -gx fish_color_history_current cyan
set -gx fish_color_host normal
set -gx fish_color_match cyan
set -gx fish_color_normal normal
set -gx fish_color_operator cyan
set -gx fish_color_param blue
set -gx fish_color_quote yellow
set -gx fish_color_redirection normal
set -gx fish_color_search_match --background=white
set -gx fish_color_selection --background=white
set -gx fish_color_status red
set -gx fish_color_user brgreen
set -gx fish_color_valid_path --underline
set -gx fish_pager_color_completion normal
set -gx fish_pager_color_description normal
set -gx fish_pager_color_prefix cyan
set -gx fish_pager_color_progress cyan
