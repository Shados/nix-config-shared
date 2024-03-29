#!/usr/bin/fish

# TODO migrate some of this back to NixOS-level config? Set if not set logic here?

# Files will be created with permissions rw--- and directories with rwx--
umask 022

# This will only prepend them to PATH if they're not already present
fish_add_path --path $HOME/technotheca/artifacts/packages/bin $HOME/technotheca/packages/bin

# Nix's Include path
begin
  set -l NIX_DEFEXPR "$HOME/.nix-defexpr/includes"
  if test -L "$NIX_DEFEXPR"; set -gx NIX_PATH "$NIX_PATH:$NIX_DEFEXPR"; end
end

# Tool-specific stuff
# tmuxinator stuff
set TMUXINATOR_COMPLETION $HOME/.tmuxinator/scripts/tmuxinator.fish
if begin; test -e $TMUXINATOR_COMPLETION; and test -f $TMUXINATOR_COMPLETION; end
  eval $TMUXINATOR_COMPLETION
end
#. /usr/local/bin/tmuxinator_completion # tab completion

# Nix on non-NixOS
if test -f /nix/etc/fish-profile.d/nix.fish; source /nix/etc/fish-profile.d/nix.fish; end
