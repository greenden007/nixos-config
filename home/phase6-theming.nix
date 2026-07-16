{ config, pkgs, ... }:

{
  # ── Fonts ─────────────────────────────────────────────────────────────────
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    # Primary coding font
    nerd-fonts.jetbrains-mono

    # UI fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    inter             # clean sans-serif for GTK apps

    # Theming packages
    catppuccin-gtk    # GTK 3/4 theme
    catppuccin-kvantum  # Qt theme via Kvantum
    papirus-icon-theme
    bibata-cursors

    # GTK theming tool (replaces gnome-tweaks for non-GNOME setups)
    nwg-look
    qt6Packages.qt6ct             # Qt6 theme configurator
    pkgs.kdePackages.qtstyleplugin-kvantum           # Qt theme engine
  ];

  # ── GTK theme ─────────────────────────────────────────────────────────────
  gtk = {
    enable = true;

    theme = {
      name = "catppuccin-mocha-mauve-standard+default";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "mauve" ];
        variant = "mocha";
      };
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
    };

    font = {
      name = "Inter";
      size = 11;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  # ── Qt theme (matches GTK via Kvantum) ────────────────────────────────────
  qt = {
    enable = true;
    platformTheme.name = "kvantum";
    style = {
      name = "kvantum";
      package = pkgs.catppuccin-kvantum;
    };
  };

  # ── Cursor for X11/XWayland (JetBrains runs here) ─────────────────────────
  home.pointerCursor = {
    name    = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size    = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # ── Catppuccin bat theme ───────────────────────────────────────────────────
  # bat picks this up via BAT_THEME env var set in phase3-shell.nix
  home.file.".config/bat/themes/Catppuccin Mocha.tmTheme".source =
    pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/catppuccin/bat/main/themes/Catppuccin%20Mocha.tmTheme";
      sha256 = "sha256-0xxashmrrj81y99ia4hvcpmplkzr1rlpgh4idf9inc7bikq6cm9r=";
    };

  # ── Catppuccin rofi theme ─────────────────────────────────────────────────
  home.file.".local/share/rofi/themes/catppuccin-mocha.rasi".text = ''
    * {
      bg-col:           #1e1e2e;
      bg-col-light:     #313244;
      border-col:       #cba6f7;
      selected-col:     #313244;
      blue:             #89b4fa;
      fg-col:           #cdd6f4;
      fg-col2:          #f38ba8;
      grey:             #6c7086;
      width:            600;
    }
    element-text, element-icon , mode-switcher {
      background-color: inherit;
      text-color:       inherit;
    }
    window {
      height:           360px;
      border:           2px;
      border-color:     @border-col;
      border-radius:    8px;
      background-color: @bg-col;
    }
    mainbox { background-color: @bg-col; }
    inputbar {
      children:         [prompt, entry];
      background-color: @bg-col;
      border-radius:    5px;
      padding:          2px;
    }
    prompt {
      background-color: @blue;
      padding:          6px;
      text-color:       @bg-col;
      border-radius:    3px;
      margin:           20px 0px 0px 20px;
    }
    entry {
      padding:          6px;
      margin:           20px 0px 0px 10px;
      text-color:       @fg-col;
      background-color: @bg-col;
    }
    listview {
      border:           0px 0px 0px;
      padding:          6px 0px 0px;
      margin:           10px 0px 0px 20px;
      columns:          2;
      background-color: @bg-col;
    }
    element {
      padding:          5px;
      background-color: @bg-col;
      text-color:       @fg-col;
    }
    element-icon { size: 25px; }
    element selected {
      background-color: @selected-col;
      text-color:       @fg-col2;
    }
    mode-switcher {
      spacing:          0;
    }
    button {
      padding:          10px;
      background-color: @bg-col-light;
      text-color:       @grey;
      vertical-align:   0.5;
      horizontal-align: 0.5;
    }
    button selected {
      background-color: @bg-col;
      text-color:       @blue;
    }
  '';
}
