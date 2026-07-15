{ config, pkgs, ... }:

{
  # ── keyd: Mac-style keyboard layout ───────────────────────────────────────
  # Physical Mac layout:  Control | Option (Alt) | Command (Meta/Super)
  # This config makes a standard PC keyboard feel like a Mac keyboard by
  # swapping Alt and Meta, then mapping Meta+key to common Mac shortcuts.

  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "*" ];   # apply to all keyboards
        settings = {
          main = {
            # Swap Alt and Meta so the physical positions match Mac
            alt = "meta";
            meta = "alt";

            # Mac-style shortcuts via the (now-remapped) Meta key
            # These fire system-wide before apps see the keypress
            "meta+c" = "C-c";       # copy
            "meta+v" = "C-v";       # paste
            "meta+x" = "C-x";       # cut
            "meta+z" = "C-z";       # undo
            "meta+shift+z" = "C-y"; # redo
            "meta+a" = "C-a";       # select all
            "meta+s" = "C-s";       # save
            "meta+w" = "C-w";       # close tab
            "meta+t" = "C-t";       # new tab
            "meta+q" = "C-q";       # quit
            "meta+f" = "C-f";       # find
            "meta+l" = "C-l";       # address bar (browser)
            "meta+r" = "C-r";       # reload
            "meta+left" = "home";   # beginning of line
            "meta+right" = "end";   # end of line
          };
        };
      };
    };
  };
}
