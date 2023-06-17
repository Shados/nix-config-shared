# To-Do List
- stop urxvt restarts on daemon upgrade (just reload?)
- pidgin + plugins
- texlive? Might be better project-specific? but nvim plugin...
- gtk & qt theming settings
- network-manager-applet
- migrate existing static dotfiles to this
- define systemd user services
- more xresources stuff?
- other stuff from my nixos graphical settings?
- xsession?
- migrate fonts/mimeapps/etc. config to be only enabled on graphical systems
- mimeapps in base config
- 'rebuild boot' equivalent by hooking into systemd-user and triggering off
  session-start as the "boot"?

## New Modules

## Neovim Config
- [ ] Figure out how to do an alternative fold marking that is
  "open-by-default" instead of "closed-by-default" (possibly just # {{ # }}?).
  Having both would be nice.
- [x] Split off a minimal/general subset of my config to include at the
  global-nixos-config level (stuff I would want even as root)
- [x] Split off the subset of things I only want on "dev" machines
- [ ] Create per-project/mkShell versions that layer on top of these, for my
  current projects
    - [ ] Especially, do this for Rust projects using pinned mozilla rust overlay
    versions of things?
- [ ] Embedded syntax (e.g. embed shell in Nix file)
    - [ ] May need to wait on https://github.com/neovim/neovim/pull/9219 to do
      this *correctly*+sanely, otherwise we'll probably need to write a Nix
      syntax/highlighter file from scratch for it (attempts at minimally
      modifying the existing one did not go well...)
    - Other related stuff:
        - https://www.reddit.com/r/vim/comments/7a05sw/dealing_with_embedded_languages/
        - https://stackoverflow.com/questions/519753/embedded-syntax-highligting-in-vim
