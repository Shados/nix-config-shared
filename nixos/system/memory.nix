{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.sn.memory;
in
{
  options = {
    sn.memory = {
      enableOvercommit = mkOption {
        type = with types; bool;
        default = true;
        description = ''
          Whether or not to enable Linxu virtual memory overcommit.
        '';
      };
    };
  };
  config = mkMerge [
    {
      boot.kernel.sysctl = {
        # Most of my systems have plenty of RAM, so default to less swappy.
        "vm.swappiness" = mkDefault 1;
      };
    }
    (mkIf cfg.enableOvercommit {
      boot.kernel.sysctl = {
        "vm.overcommit_ratio" = mkDefault 100;
        "vm.overcommit_memory" = mkDefault 0;
        # Get kernel debug prints of all tasks' memory state whenever the OOM
        # killer is invoked. Enables manually determining what was responsible
        # for the OOM condition.
        "vm.oom_dump_tasks" = mkDefault 1;
      };
    })
    (mkIf (!cfg.enableOvercommit) {
      boot.kernel.sysctl = {
        # I don't know why the hell NixOS defaults this to 50? Or maybe it's
        # the kernel default..? To enforce space for the page cache or
        # something...?
        "vm.overcommit_ratio" = mkDefault 100;
        # Default to max overcommit of (swap + (real_ram * overcommit_ratio)),
        # in this instance meaning do not allow committing more memory than is
        # actually available. Prevents the OOM killer from ever being invoked,
        # but does mean malloc() may fail. Of course, to a *well-written*
        # program, malloc() failing is not the worst thing that can happen.
        "vm.overcommit_memory" = mkDefault 2;
      };
      # Long explanatory rant ahead:
      # Recent webkit uses uber-large virtual memory allocations as part of a
      # frankly derp hardening measure:
      # https://labs.mwrinfosecurity.com/blog/some-brief-notes-on-webkit-heap-hardening/
      # TL;DR: webkit allocates 3 'gigacages', which are >32GB virtual memory
      # allocations, then uses space within those vmem heaps such that there's
      # always at least 32GB of 'runway' after a block of actual structures.
      # This means that with the 32-bit indices for indexed types in JS,
      # there's no posibility of an OOB access landing outside the gigacage.
      # This is a fucking terrible method of hardening against OOB, and I feel
      # sad.
      # It gets better, because while you can implement giant virtual memory
      # allocations in a way that still works even if overcommit is disabled or
      # limited (as it is on my systems), they've opted not to do that over
      # *speculative* performance concerns, as well as because they'd have to
      # write a segfault handler. Instead, they opted to just have it emit a
      # warning and... not use gigacages.
      # https://bugs.webkit.org/show_bug.cgi?id=183329
      # It still gets better, because if they had done this the right way and
      # also implemented said segfault handler, it would actually provide them
      # a mechanism of logging and tracking any OOB accesses, which as you can
      # imagine would be incredibly helpful for debugging webkit bugs involving
      # them / detecting exploit attempts
      # It *still* gets better, because I found that in practice, the patch to
      # automatically disable gigacage on failure on Linux platforms doesn't
      # actually do that. Instead:
      # - It prints an error complaining that the gigacage is disabled but
      #   shouldn't be, and then crashes webkit.
      # - Most applications that use webkit, including I think all webkit-gtk
      #   applications, then immediately relaunch webkit, entering a crash
      #   loop.
      # - Better yet, it appears that when webkit crashes itself this way, it
      #   does so uncleanly and leaks a little bit of memory, so this crash
      #   loop will then eat all of your RAM after a while.
      # This environment variable `GIGACAGE_ENABLED`, if set to `no` will both
      # disable the gigacage up-front and also disable the check-and-crash
      # routine, but, uh... what the fuck?
      environment.variables.GIGACAGE_ENABLED = "no";
    })
  ];
}
