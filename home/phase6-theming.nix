{ config, pkgs, ... }:

{
  # ── Fonts ─────────────────────────────────────────────────────────────────
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    # Primary coding font
    nerd-fonts.jetbrains-mono

    # Wallpaper-driven theming
    matugen

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

  # ── Matugen templates and config ─────────────────────────────────────────
  home.file.".config/matugen/config.toml".text = ''
    [config]
    color_mode = "dark"

    [templates.gtk3]
    input_path = "${config.home.homeDirectory}/.config/matugen/templates/gtk.css"
    output_path = "${config.home.homeDirectory}/.config/gtk-3.0/colors.css"

    [templates.gtk4]
    input_path = "${config.home.homeDirectory}/.config/matugen/templates/gtk.css"
    output_path = "${config.home.homeDirectory}/.config/gtk-4.0/colors.css"

    [templates.rofi]
    input_path = "${config.home.homeDirectory}/.config/matugen/templates/rofi.rasi"
    output_path = "${config.home.homeDirectory}/.local/share/rofi/themes/matugen.rasi"

    [templates.waybar]
    input_path = "${config.home.homeDirectory}/.config/matugen/templates/waybar.css"
    output_path = "${config.home.homeDirectory}/.config/waybar/colors.css"

    [templates.mako]
    input_path = "${config.home.homeDirectory}/.config/matugen/templates/mako"
    output_path = "${config.home.homeDirectory}/.config/mako/mako-colors"

    [templates.kvantum_kvconfig]
    input_path = "${config.home.homeDirectory}/.config/matugen/templates/kvantum.kvconfig"
    output_path = "${config.home.homeDirectory}/.config/Kvantum/matugen/matugen.kvconfig"

    [templates.kvantum_svg]
    input_path = "${config.home.homeDirectory}/.config/matugen/templates/kvantum.svg"
    output_path = "${config.home.homeDirectory}/.config/Kvantum/matugen/matugen.svg"
  '';

  home.file.".config/matugen/templates/gtk.css".text = ''
    @define-color matugen_background {{colors.surface.default.hex}};
    @define-color matugen_foreground {{colors.on_surface.default.hex}};
    @define-color matugen_primary {{colors.primary.default.hex}};
    @define-color matugen_secondary {{colors.secondary.default.hex}};
    @define-color matugen_tertiary {{colors.tertiary.default.hex}};
    @define-color matugen_surface {{colors.surface_container.default.hex}};
    @define-color matugen_surface_high {{colors.surface_container_high.default.hex}};
    @define-color matugen_border {{colors.outline.default.hex}};
    @define-color matugen_error {{colors.error.default.hex}};
  '';

  home.file.".config/matugen/templates/rofi.rasi".text = ''
    * {
      bg-col:           {{colors.surface.default.hex}};
      bg-col-light:     {{colors.surface_container.default.hex}};
      border-col:       {{colors.primary.default.hex}};
      selected-col:     {{colors.surface_container_high.default.hex}};
      blue:             {{colors.primary.default.hex}};
      fg-col:           {{colors.on_surface.default.hex}};
      fg-col2:          {{colors.on_primary.default.hex}};
      grey:             {{colors.outline.default.hex}};
      width:            600;
    }
  '';

  home.file.".config/matugen/templates/waybar.css".text = ''
    @define-color background {{colors.surface.default.hex}};
    @define-color background-alt {{colors.surface_container.default.hex}};
    @define-color foreground {{colors.on_surface.default.hex}};
    @define-color accent {{colors.primary.default.hex}};
    @define-color accent-2 {{colors.secondary.default.hex}};
    @define-color border {{colors.outline.default.hex}};
    @define-color urgent {{colors.error.default.hex}};
  '';

  home.file.".config/matugen/templates/mako".text = ''
    background-color={{colors.surface.default.hex}}
    text-color={{colors.on_surface.default.hex}}
    border-color={{colors.primary.default.hex}}
  '';

  home.file.".config/matugen/templates/kvantum.kvconfig".text = ''
    [%General]
    window.color={{colors.surface.default.hex}}
    base.color={{colors.surface_container_highest.default.hex}}
    alt.base.color={{colors.surface_container_low.default.hex}}
    button.color={{colors.surface_bright.default.hex}}
    light.color={{colors.surface_bright.default.hex}}
    mid.light.color={{colors.surface_variant.default.hex}}
    dark.color={{colors.surface.default.hex}}
    mid.color={{colors.surface_container_low.default.hex}}
    highlight.color={{colors.primary.default.hex}}
    inactive.highlight.color={{colors.primary_fixed_dim.default.hex}}
    text.color={{colors.on_surface.default.hex}}
    window.text.color={{colors.on_surface.default.hex}}
    button.text.color={{colors.on_surface.default.hex}}
    disabled.text.color={{colors.inverse_on_surface.default.hex}}
    tooltip.text.color={{colors.on_surface.default.hex}}
    highlight.text.color={{colors.on_surface.default.hex}}
    link.color={{colors.primary.default.hex}}
    link.visited.color={{colors.tertiary_fixed_dim.default.hex}}
  '';

  home.file.".config/matugen/templates/kvantum.svg".text = ''
    <svg xmlns="http://www.w3.org/2000/svg" width="1" height="1">
      <rect width="1" height="1" fill="{{colors.primary.default.hex}}"/>
    </svg>
  '';

  home.file.".config/Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=matugen
  '';

  home.file.".local/share/rofi/themes/matugen.rasi".text = ''
    * {
      font: "JetBrainsMono Nerd Font 12";
      text-color: {{colors.on_surface.default.hex}};
    }
    window {
      height: 360px;
      border: 2px;
      border-color: {{colors.primary.default.hex}};
      border-radius: 8px;
      background-color: {{colors.surface.default.hex}};
    }
    mainbox { background-color: {{colors.surface.default.hex}}; }
    inputbar {
      children: [prompt, entry];
      background-color: {{colors.surface.default.hex}};
      border-radius: 5px;
      padding: 2px;
    }
    prompt {
      background-color: {{colors.primary.default.hex}};
      padding: 6px;
      text-color: {{colors.on_primary.default.hex}};
      border-radius: 3px;
      margin: 20px 0px 0px 20px;
    }
    entry {
      padding: 6px;
      margin: 20px 0px 0px 10px;
      text-color: {{colors.on_surface.default.hex}};
      background-color: {{colors.surface.default.hex}};
    }
    listview {
      border: 0px 0px 0px;
      padding: 6px 0px 0px;
      margin: 10px 0px 0px 20px;
      columns: 2;
      background-color: {{colors.surface.default.hex}};
    }
    element {
      padding: 5px;
      background-color: {{colors.surface.default.hex}};
      text-color: {{colors.on_surface.default.hex}};
    }
    element-icon { size: 25px; }
    element selected {
      background-color: {{colors.surface_container_high.default.hex}};
      text-color: {{colors.on_primary.default.hex}};
    }
    mode-switcher { spacing: 0; }
    button {
      padding: 10px;
      background-color: {{colors.surface_container.default.hex}};
      text-color: {{colors.outline.default.hex}};
      vertical-align: 0.5;
      horizontal-align: 0.5;
    }
    button selected {
      background-color: {{colors.surface.default.hex}};
      text-color: {{colors.primary.default.hex}};
    }
  '';

  home.file.".config/waybar/style.css".text = ''
    @import "colors.css";

    * {
      font-family: "JetBrainsMono Nerd Font", monospace;
      font-size: 13px;
      border: none;
      border-radius: 0;
    }
    window#waybar {
      background-color: alpha(@background, 0.92);
      color: @foreground;
    }
    #workspaces button {
      padding: 0 8px;
      color: shade(@foreground, 0.55);
      background: transparent;
    }
    #workspaces button.active {
      color: @accent;
      border-bottom: 2px solid @accent;
    }
    #clock, #cpu, #memory, #temperature, #network, #pulseaudio, #tray {
      padding: 0 10px;
      color: @foreground;
    }
    #temperature.critical { color: @urgent; }
  '';

  home.file.".config/mako/config".text = ''
    include=~/.config/mako/mako-colors
  '';

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
      sha256 = "sha256-OVVm8IzrMBuTa5HAd2kO+U9662UbEhVT8gHJnCvUqnc=";
    };

  # GTK is kept on the existing theme engine; rofi now uses matugen output.
}
