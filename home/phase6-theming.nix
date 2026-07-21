{ config, lib, pkgs, ... }:

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

    [templates.rofi_hyde_colors]
    input_path = "${config.home.homeDirectory}/.config/matugen/templates/rofi-hyde-colors.rasi"
    output_path = "${config.home.homeDirectory}/.config/rofi/theme.rasi"

    [templates.waybar]
    input_path = "${config.home.homeDirectory}/.config/matugen/templates/waybar.css"
    output_path = "${config.home.homeDirectory}/.config/waybar/colors.css"

    [templates.mako]
    input_path = "${config.home.homeDirectory}/.config/matugen/templates/mako"
    output_path = "${config.home.homeDirectory}/.config/mako/mako-colors"

    [templates.wlogout]
    input_path = "${config.home.homeDirectory}/.config/matugen/templates/wlogout.css"
    output_path = "${config.home.homeDirectory}/.config/wlogout/colors.css"

    [templates.discord]
    input_path = "${config.home.homeDirectory}/.config/matugen/templates/discord.css"
    output_path = "${config.home.homeDirectory}/.config/vesktop/themes/matugen.css"

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

  # ── Rofi matugen template — liquid-glass backdrop ─────────────────────────
  # The window uses transparency = "real" so the Hyprland compositor handles
  # the actual blur (windowrulev2 blur / blurls = rofi in hyprland.conf).
  # Inside the window we add a dedicated `glass-pane` box that sits *behind*
  # the mainbox in the children list. It is:
  #   • slightly larger than mainbox (negative margin / expand)
  #   • filled with a semi-transparent version of the primary accent so the
  #     frosted hue peeks through around the edges
  #   • given a stronger border and higher border-radius than the inner panel
  #   • uses a linear-gradient background-image to fake the specular sheen
  #     that makes Apple's liquid-glass look three-dimensional
  # The mainbox floats on top with a slightly opaque bg so the content is
  # readable even when the compositor blur is mild.
  home.file.".config/matugen/templates/rofi.rasi".text = ''
    * {
      bg-col:           {{colors.surface.default.hex}};
      bg-col-alt:       {{colors.surface_container.default.hex}};
      border-col:       {{colors.primary.default.hex}};
      selected-col:     {{colors.primary.default.hex}};
      fg-col:           {{colors.on_surface.default.hex}};
      fg-col2:          {{colors.on_primary.default.hex}};
      grey:             {{colors.outline.default.hex}};

      /* Liquid-glass tint: primary at ~18 % opacity */
      glass-tint:       {{colors.primary.default.hex}}2e;
      /* Specular highlight: near-white at ~12 % — top edge gleam */
      glass-sheen:      #ffffff1f;
      /* Outer glow: primary at ~30 % — the halo behind the pane */
      glass-glow:       {{colors.primary.default.hex}}4d;
    }

    /* ── Outer window — fully transparent, compositor does the blur ───────── */
    window {
      width:            924px;          /* slightly wider than mainbox */
      height:           600px;          /* slightly taller than mainbox */
      border:           0px;
      background-color: transparent;
      transparency:     "real";
    }

    /* ── Root box stacks glass-pane BEHIND mainbox ─────────────────────────
       rofi draws children in declaration order, so glass-pane renders first
       (underneath) and mainbox renders on top.                               */
    rootbox {
      orientation:      vertical;
      children:         [ glass-pane, mainbox ];
      background-color: transparent;
      /* Overlap the two children by making glass-pane use negative spacing */
      spacing:          0px;
    }

    /* ── Liquid-glass pane ──────────────────────────────────────────────────
       Positioned absolutely behind the mainbox via expand + negative margin.
       The background-image gradient fakes the top-edge specular sheen.       */
    glass-pane {
      expand:           true;
      /* Push it out past the mainbox edges on all sides for the halo effect */
      margin:           -18px;
      padding:          0px;
      border-radius:    36px;
      border:           1.5px;
      border-color:     @glass-sheen;

      /* Base: semi-transparent primary tint so the wallpaper color bleeds in */
      background-color: @glass-tint;

      /* Specular sheen: a subtle top-to-bottom gradient — bright at top,
         transparent in the middle, faint accent glow at the bottom edge.
         This is the key trick that gives liquid-glass its depth.             */
      background-image: linear-gradient(
        to bottom,
        @glass-sheen 0%,
        transparent  38%,
        transparent  62%,
        @glass-glow  100%
      );

      /* Outer drop-shadow for the floating-above-desktop feel */
      box-shadow:
        0 8px 32px  @glass-glow,
        0 2px  8px  @glass-tint,
        inset 0 1px 0 @glass-sheen;
    }

    /* ── Main panel — slightly opaque so content is readable ─────────────── */
    mainbox {
      children:         [ inputbar, listview ];
      background-color: @bg-col;
      /* bg-col is already the surface hex; add opacity via the fallback below
         — matugen hex output doesn't include alpha, so we overlay a slight
         transparency by using a box that is NOT fully opaque.
         Practical opacity: ~88 % — keeps content crisp, lets glass peek through. */
      /* Reuse bg-col with alpha appended in the static fallback. */
      opacity:          0.88;
      padding:          22px;
      spacing:          18px;
      border-radius:    28px;
      border:           1.5px;
      border-color:     @border-col;
    }

    inputbar {
      children:         [ prompt, entry ];
      background-color: @bg-col-alt;
      border-radius:    14px;
      padding:          10px 16px;
      spacing:          10px;
    }
    prompt {
      background-color: transparent;
      text-color:       @grey;
    }
    entry {
      background-color: transparent;
      text-color:       @fg-col;
      placeholder:      "Search apps…";
      placeholder-color: @grey;
    }
    listview {
      columns:          6;
      lines:            4;
      spacing:          14px;
      background-color: @bg-col;
      border:           0px;
      fixed-height:     false;
    }
    element {
      orientation:      vertical;
      padding:          12px 6px;
      border-radius:    16px;
      background-color: @bg-col;
    }
    element-icon {
      size:             52px;
      horizontal-align: 0.5;
    }
    element-text {
      horizontal-align: 0.5;
      text-color:       @fg-col;
      margin:           6px 0px 0px 0px;
    }
    element selected {
      background-color: @selected-col;
    }
    element selected element-text {
      text-color: @fg-col2;
    }
    mode-switcher { spacing: 0; }
    button {
      padding:          10px;
      background-color: @bg-col-alt;
      text-color:       @grey;
      vertical-align:   0.5;
      horizontal-align: 0.5;
    }
    button selected {
      background-color: @bg-col;
      text-color:       @border-col;
    }
  '';

  home.file.".config/matugen/templates/rofi-hyde-colors.rasi".text = ''
    * {
      main-bg: {{colors.surface.default.hex}};
      main-fg: {{colors.on_surface.default.hex}};
      main-br: {{colors.primary.default.hex}};
      select-bg: {{colors.primary.default.hex}};
      select-fg: {{colors.on_primary.default.hex}};
    }
  '';

  # ── HyDE style_12 (\"GradientView\") launcher, ported verbatim ───────────────
  # https://github.com/HyDE-Project/HyDE/blob/master/Configs/.local/share/hyde/rofi/themes/style_12.rasi
  # Two changes from upstream: paths made absolute (rofi doesn't reliably
  # expand ~ the way HyDE's own launcher wrapper script does for it), and
  # icon-theme swapped to Papirus-Dark since Tela-circle-dracula isn't
  # installed here.
  home.file.".local/share/rofi/themes/style_12.rasi".text = ''
    /**
    * ROFI Layout
    *
    * Style 12: Sidebar with a gradient effect and modes.
    * Attribute: rofilaunch,launcher
    * User: The HyDE Project [ GradientView ]
    * Copyright: https://github.com/prasanthrangan/hyprdots/
    * Ported into this flake with matugen-driven colors.
    */

    configuration {
      modi: "drun,filebrowser,window,run";
      show-icons: true;
      display-drun: "";
      display-run: "";
      display-filebrowser: "";
      display-window: "";
      drun-display-format: "{name}";
      window-format: "{w}{t}";
      font: "JetBrainsMono Nerd Font 10";
      icon-theme: "Papirus-Dark";
    }

    @theme "${config.home.homeDirectory}/.config/rofi/theme.rasi"

    window {
      height: 30em;
      width: 60em;
      transparency: "real";
      fullscreen: false;
      enabled: true;
      cursor: "default";
      spacing: 0em;
      padding: 0em;
      border-color: transparent;
      background-color: transparent;
    }

    mainbox {
      enabled: true;
      spacing: 0em;
      padding: 0em;
      orientation: horizontal;
      children: [ "listbox", "inputbar" ];
      background-color: transparent;
    }

    inputbar {
      enabled: true;
      width: 30em;
      spacing: 0em;
      padding: 0em;
      children: [ "entry" ];
      expand: false;
      background-color: transparent;
      background-image: url("${config.home.homeDirectory}/.cache/hyde/wall.quad", width);
    }

    entry {
      enabled: false;
    }

    listbox {
      spacing: 0em;
      padding: 0em;
      children: [ "dummy", "listview", "dummy" ];
      background-color: @main-bg;
      expand: false;
      width: 27em;
    }

    listview {
      enabled: true;
      spacing: 0em;
      padding: 1em 2em 1em 2em;
      columns: 1;
      lines: 8;
      cycle: true;
      dynamic: true;
      scrollbar: false;
      layout: vertical;
      reverse: false;
      expand: false;
      fixed-height: true;
      fixed-columns: true;
      cursor: "default";
      background-color: transparent;
      text-color: @main-fg;
    }

    dummy {
      background-color: transparent;
      expand: true;
    }

    element {
      enabled: true;
      spacing: 1em;
      padding: 0.5em;
      cursor: pointer;
      background-color: transparent;
      text-color: @main-fg;
    }

    element selected.normal {
      background-color: @select-bg;
      text-color: @select-fg;
    }

    element-icon {
      size: 2.2em;
      cursor: inherit;
      background-color: transparent;
      text-color: inherit;
    }

    element-text {
      vertical-align: 0.5;
      horizontal-align: 0.0;
      cursor: inherit;
      background-color: transparent;
      text-color: inherit;
    }

    error-message {
      text-color: @main-fg;
      background-color: @main-bg;
      text-transform: capitalize;
      children: [ "textbox" ];
    }

    textbox {
      text-color: inherit;
      background-color: inherit;
      vertical-align: 0.5;
      horizontal-align: 0.5;
    }
  '';

  # ── HyDE style_11 (\"DiagonalSplit\") launcher, ported verbatim ───────────────
  # https://github.com/HyDE-Project/HyDE/blob/master/Configs/.local/share/hyde/rofi/themes/style_11.rasi
  # Same two edits as style_12: absolute paths instead of ~, and icon-theme
  # swapped to Papirus-Dark. Note the layout is mirrored vs style_12 —
  # mainbox children are [ \"inputbar\", \"listbox\" ] instead of the other way
  # round, so the wallpaper panel sits on the LEFT here. That means the
  # wall.quad gradient direction in wallpaper-picker must fade opposite of
  # style_12's (opaque on the left, transparent on the right, toward the
  # seam with the list) for the two themes to be interchangeable.
  home.file.".local/share/rofi/themes/style_11.rasi".text = ''
    /**
    * ROFI Layout
    *
    * Style 11: Diagonal background split with modes or a list.
    * Attribute: rofilaunch,launcher
    * User: The HyDE Project [ DiagonalSplit ]
    * Copyright: https://github.com/prasanthrangan/hyprdots/
    * Ported into this flake with matugen-driven colors.
    */

    configuration {
      modi: "drun,filebrowser,window,run";
      show-icons: true;
      display-drun: "";
      display-run: "";
      display-filebrowser: "";
      display-window: "";
      drun-display-format: "{name}";
      window-format: "{w}{t}";
      font: "JetBrainsMono Nerd Font 10";
      icon-theme: "Papirus-Dark";
    }

    @theme "${config.home.homeDirectory}/.config/rofi/theme.rasi"

    window {
      height: 30em;
      width: 58em;
      transparency: "real";
      fullscreen: false;
      enabled: true;
      cursor: "default";
      spacing: 0em;
      padding: 0em;
      border-color: @main-br;
      background-color: transparent;
    }

    mainbox {
      enabled: true;
      spacing: 0em;
      padding: 0.8em;
      orientation: horizontal;
      children: [ "inputbar", "listbox" ];
      background-color: #00000003;
    }

    inputbar {
      enabled: true;
      width: 28.5em;
      spacing: 0em;
      padding: 0em;
      children: [ "entry" ];
      expand: false;
      background-color: @main-bg;
      background-image: url("${config.home.homeDirectory}/.cache/hyde/wall.quad", width);
      border-radius: 1em 0em 0em 1em;
    }

    entry {
      enabled: false;
    }

    listbox {
      spacing: 0em;
      padding: 0em;
      children: [ "dummy", "listview", "dummy" ];
      background-color: @main-bg;
      border-radius: 0em 1em 1em 0em;
    }

    listview {
      enabled: true;
      spacing: 0em;
      padding: 1em 2em 1em 2em;
      columns: 1;
      lines: 8;
      cycle: true;
      dynamic: true;
      scrollbar: false;
      layout: vertical;
      reverse: false;
      expand: false;
      fixed-height: true;
      fixed-columns: true;
      cursor: "default";
      background-color: transparent;
      text-color: @main-fg;
    }

    dummy {
      background-color: transparent;
    }

    element {
      enabled: true;
      spacing: 1em;
      padding: 0.5em 0.5em 0.5em 1.5em;
      cursor: pointer;
      background-color: transparent;
      text-color: @main-fg;
    }

    element selected.normal {
      background-color: @select-bg;
      text-color: @select-fg;
    }

    element-icon {
      size: 2.2em;
      cursor: inherit;
      background-color: transparent;
      text-color: inherit;
    }

    element-text {
      vertical-align: 0.5;
      horizontal-align: 0.0;
      cursor: inherit;
      background-color: transparent;
      text-color: inherit;
    }

    error-message {
      text-color: @main-fg;
      background-color: @main-bg;
      text-transform: capitalize;
      children: [ "textbox" ];
    }

    textbox {
      text-color: inherit;
      background-color: inherit;
      vertical-align: 0.5;
      horizontal-align: 0.5;
    }
  '';

  home.activation.ensureRofiMatugenTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    theme="$HOME/.local/share/rofi/themes/matugen.rasi"
    if [ -L "$theme" ]; then
      rm "$theme"
    fi
    write_theme=false
    if [ ! -e "$theme" ]; then
      write_theme=true
    elif ${pkgs.gnugrep}/bin/grep -q '{{colors' "$theme"; then
      write_theme=true
    elif ! ${pkgs.gnugrep}/bin/grep -q 'columns:' "$theme"; then
      # Old compact-list fallback from before the grid redesign — replace it.
      write_theme=true
    elif ! ${pkgs.gnugrep}/bin/grep -q 'glass-pane' "$theme"; then
      # Pre-liquid-glass fallback — replace it.
      write_theme=true
    fi
    if [ "$write_theme" = true ]; then
      mkdir -p "$(dirname "$theme")"
      cat > "$theme" <<'EOF'
* {
  bg-col: #1e1e2e;
  bg-col-alt: #313244;
  border-col: #cba6f7;
  selected-col: #89b4fa;
  fg-col: #cdd6f4;
  fg-col2: #1e1e2e;
  grey: #6c7086;

  glass-tint:  #cba6f72e;
  glass-sheen: #ffffff1f;
  glass-glow:  #cba6f74d;
}
window {
  width: 924px;
  height: 600px;
  border: 0px;
  background-color: transparent;
  transparency: "real";
}
rootbox {
  orientation: vertical;
  children: [ glass-pane, mainbox ];
  background-color: transparent;
  spacing: 0px;
}
glass-pane {
  expand: true;
  margin: -18px;
  padding: 0px;
  border-radius: 36px;
  border: 1px;
  border-color: @glass-sheen;
  background-color: @glass-tint;
  background-image: linear-gradient(
    to bottom,
    @glass-sheen 0%,
    transparent  38%,
    transparent  62%,
    @glass-glow  100%
  );
  box-shadow:
    0 8px 32px @glass-glow,
    0 2px  8px @glass-tint,
    inset 0 1px 0 @glass-sheen;
}
mainbox {
  children: [inputbar, listview];
  background-color: #1e1e2ee0;
  opacity: 0.88;
  padding: 22px;
  spacing: 18px;
  border-radius: 28px;
  border: 1px;
  border-color: #cba6f7;
}
inputbar {
  children: [prompt, entry];
  background-color: @bg-col-alt;
  border-radius: 14px;
  padding: 10px 16px;
  spacing: 10px;
}
prompt {
  background-color: transparent;
  text-color: @grey;
}
entry {
  background-color: transparent;
  text-color: @fg-col;
  placeholder: "Search apps…";
  placeholder-color: @grey;
}
listview {
  columns: 6;
  lines: 4;
  spacing: 14px;
  background-color: @bg-col;
  border: 0px;
  fixed-height: false;
}
element {
  orientation: vertical;
  padding: 12px 6px;
  border-radius: 16px;
  background-color: @bg-col;
}
element-icon { size: 52px; horizontal-align: 0.5; }
element-text {
  horizontal-align: 0.5;
  text-color: @fg-col;
  margin: 6px 0px 0px 0px;
}
element selected { background-color: @selected-col; }
element selected element-text { text-color: @fg-col2; }
EOF
    fi
  '';

  # ── Wallpaper-picker grid theme (thumbnails, not app icons) ────────────────
  # Not matugen-templated on purpose: it needs to render *before* matugen has
  # ever run (you use it to pick the very first wallpaper), so it ships with
  # a fixed dark palette that's restyled to match on the next theme-refresh.
  home.file.".local/share/rofi/themes/wallpaper-grid.rasi".text = ''
    * {
      bg-col: #1e1e2e;
      bg-col-alt: #313244;
      border-col: #cba6f7;
      selected-col: #89b4fa;
      fg-col: #cdd6f4;
      grey: #6c7086;
    }
    window {
      width: 1000px;
      height: 720px;
      border: 2px;
      border-color: @border-col;
      border-radius: 24px;
      background-color: @bg-col;
    }
    mainbox {
      children: [inputbar, listview];
      background-color: @bg-col;
      padding: 22px;
      spacing: 18px;
    }
    inputbar {
      children: [prompt, entry];
      background-color: @bg-col-alt;
      border-radius: 14px;
      padding: 10px 16px;
      spacing: 10px;
    }
    prompt { background-color: transparent; text-color: @grey; }
    entry {
      background-color: transparent;
      text-color: @fg-col;
      placeholder: "Search wallpapers…";
      placeholder-color: @grey;
    }
    listview {
      columns: 4;
      lines: 2;
      spacing: 16px;
      background-color: @bg-col;
      border: 0px;
      fixed-height: false;
    }
    element {
      orientation: vertical;
      padding: 8px;
      border-radius: 18px;
      background-color: @bg-col-alt;
    }
    element-icon { size: 220px; horizontal-align: 0.5; }
    element-text {
      horizontal-align: 0.5;
      text-color: @fg-col;
      margin: 6px 0px 0px 0px;
    }
    element selected { background-color: @selected-col; border-color: @selected-col; }
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

  home.file.".config/matugen/templates/wlogout.css".text = ''
    @define-color background {{colors.surface.default.hex}};
    @define-color background-alt {{colors.surface_container.default.hex}};
    @define-color foreground {{colors.on_surface.default.hex}};
    @define-color accent {{colors.primary.default.hex}};
    @define-color border {{colors.outline.default.hex}};
  '';

  # ── Discord (Vesktop/Vencord) ────────────────────────────────────────────
  # GTK/Kvantum theming never reaches Discord — it's Electron and draws its
  # own UI. Vesktop bundles Vencord, which supports loading arbitrary CSS
  # from ~/.config/vesktop/themes/. We layer a small set of variable
  # overrides (surfaces, text, accent, borders — the properties that read as
  # "the theme" at a glance) on top of the community Catppuccin Mocha base,
  # so it keeps every other polish detail (badges, syntax highlighting,
  # status colors) while the backgrounds/accent follow your wallpaper.
  programs.vesktop = {
    enable = true;
    vencord.settings = {
      enabledThemes = [ "matugen.css" ];
      useQuickCss = true;
    };
  };

  home.file.".config/matugen/templates/discord.css".text = ''
    @import url("https://catppuccin.github.io/discord/dist/catppuccin-mocha.theme.css");

    :root {
      /* Layered backgrounds */
      --background-base-lowest: {{colors.surface_container_lowest.default.hex}} !important;
      --background-base-lower: {{colors.surface_container_low.default.hex}} !important;
      --background-base-low: {{colors.surface_container.default.hex}} !important;
      --background-surface-high: {{colors.surface.default.hex}} !important;
      --background-surface-higher: {{colors.surface_container_high.default.hex}} !important;
      --background-surface-highest: {{colors.surface_container_highest.default.hex}} !important;
      --home-background: {{colors.surface.default.hex}} !important;
      --chat-background: {{colors.surface.default.hex}} !important;
      --chat-background-default: {{colors.surface.default.hex}} !important;
      --channeltextarea-background: {{colors.surface_container.default.hex}} !important;
      --modal-background: {{colors.surface_container.default.hex}} !important;
      --modal-footer-background: {{colors.surface_container.default.hex}} !important;
      --background-accent: {{colors.surface_container_high.default.hex}} !important;
      --card-background-default: {{colors.surface_container_high.default.hex}} !important;

      /* Text and icons */
      --text-default: {{colors.on_surface.default.hex}} !important;
      --text-strong: {{colors.on_surface.default.hex}} !important;
      --text-muted: {{colors.on_surface_variant.default.hex}} !important;
      --text-subtle: {{colors.on_surface_variant.default.hex}} !important;
      --interactive-text-default: {{colors.on_surface.default.hex}} !important;
      --interactive-icon-default: {{colors.on_surface.default.hex}} !important;
      --icon-default: {{colors.on_surface.default.hex}} !important;
      --icon-strong: {{colors.on_surface.default.hex}} !important;
      --channels-default: {{colors.on_surface_variant.default.hex}} !important;
      --channel-icon: {{colors.on_surface_variant.default.hex}} !important;

      /* Accent — the wallpaper's primary color */
      --brand-500: {{colors.primary.default.hex}} !important;
      --brand-530: color-mix(in srgb, {{colors.primary.default.hex}} 88%, black);
      --brand-560: color-mix(in srgb, {{colors.primary.default.hex}} 76%, black);
      --brand-600: color-mix(in srgb, {{colors.primary.default.hex}} 64%, black);
      --text-link: {{colors.primary.default.hex}} !important;
      --text-brand: {{colors.primary.default.hex}};
      --control-brand-foreground: {{colors.primary.default.hex}};
      --control-primary-background-default: {{colors.primary.default.hex}} !important;
      --control-primary-background-hover: color-mix(in srgb, {{colors.primary.default.hex}} 88%, black);
      --control-primary-background-active: color-mix(in srgb, {{colors.primary.default.hex}} 76%, black);
      --scrollbar-thin-thumb: {{colors.primary.default.hex}};
      --scrollbar-auto-thumb: {{colors.primary.default.hex}};
      --mention-foreground: {{colors.primary.default.hex}};

      /* Borders */
      --border-muted: {{colors.outline_variant.default.hex}} !important;
      --border-normal: {{colors.outline_variant.default.hex}} !important;
      --border-strong: {{colors.outline.default.hex}} !important;
    }
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

  home.file.".config/waybar/style.css".text = ''
    @import "colors.css";

    * {
      font-family: "JetBrainsMono Nerd Font", monospace;
      font-size: 13px;
      border: none;
      border-radius: 8px;
      min-height: 0;
    }
    window#waybar {
      background-color: alpha(@background, 0.72);
      color: @foreground;
    }

    /* App-menu button — leftmost, opens the rofi grid launcher */
    #custom-appmenu {
      margin: 5px 4px 5px 8px;
      padding: 0 14px;
      color: @background;
      background: @accent;
      font-size: 15px;
      font-weight: 700;
    }
    #custom-appmenu:hover {
      background: shade(@accent, 1.1);
    }

    /* Dot-style workspace indicators */
    #workspaces {
      margin: 5px 2px;
      padding: 0 4px;
      background: alpha(@background-alt, 0.45);
    }
    #workspaces button {
      margin: 0 3px;
      padding: 0;
      min-width: 10px;
      min-height: 10px;
      border-radius: 999px;
      color: transparent;
      background: shade(@foreground, 0.45);
    }
    #workspaces button.active {
      min-width: 22px;
      background: @accent;
    }
    #workspaces button:hover {
      background: alpha(@accent, 0.7);
    }

    #clock,
    #cpu,
    #memory,
    #temperature,
    #network,
    #pulseaudio,
    #battery,
    #tray,
    #custom-theme,
    #custom-ml-status,
    #custom-peripheral-battery {
      margin: 5px 3px;
      padding: 0 10px;
      color: @foreground;
      background: alpha(@background-alt, 0.62);
      border: 1px solid alpha(@border, 0.35);
    }
    #clock {
      color: @background;
      background: @accent;
      border-color: @accent;
      font-weight: 700;
    }
    #cpu:hover,
    #memory:hover,
    #temperature:hover,
    #network:hover,
    #pulseaudio:hover,
    #battery:hover,
    #custom-theme:hover,
    #custom-ml-status:hover,
    #custom-peripheral-battery:hover {
      background: alpha(@accent, 0.34);
      border-color: @accent;
    }
    #custom-theme {
      color: @background;
      background: alpha(@accent, 0.88);
      border-color: @accent;
      font-weight: 700;
    }
    #custom-ml-status.training {
      color: @background;
      background: @accent;
      border-color: @accent;
      font-weight: 700;
    }
    #custom-peripheral-battery.warning,
    #battery.warning {
      color: @background;
      background: @accent-2;
    }
    #custom-peripheral-battery.critical,
    #battery.critical,
    #temperature.critical {
      color: @background;
      background: @urgent;
      border-color: @urgent;
    }
    #custom-power {
      margin: 5px 8px 5px 3px;
      padding: 0 12px;
      color: @foreground;
      background: alpha(@background-alt, 0.62);
      border: 1px solid alpha(@border, 0.35);
      font-size: 14px;
    }
    #custom-power:hover {
      color: @background;
      background: @urgent;
      border-color: @urgent;
    }
  '';

  home.file.".config/mako/config".text = ''
    include=~/.config/mako/mako-colors
  '';

  # ── First-boot color fallbacks ───────────────────────────────────────────
  # waybar/style.css, mako/config, and wlogout's style all @import a
  # matugen-generated colors file. Those don't exist until you run
  # wallpaper-picker/theme-refresh at least once, so seed them with the
  # same static Catppuccin Mocha palette used as the rofi fallback above.
  # Never overwrites a real matugen output.
  home.activation.ensureMatugenColorFallbacks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ensure_file() {
      local path="$1"
      if [ ! -e "$path" ]; then
        mkdir -p "$(dirname "$path")"
        cat > "$path"
      else
        cat >/dev/null
      fi
    }

    ensure_file "$HOME/.config/waybar/colors.css" <<'EOF'
@define-color background #1e1e2e;
@define-color background-alt #313244;
@define-color foreground #cdd6f4;
@define-color accent #cba6f7;
@define-color accent-2 #89b4fa;
@define-color border #6c7086;
@define-color urgent #f38ba8;
EOF

    ensure_file "$HOME/.config/wlogout/colors.css" <<'EOF'
@define-color background #1e1e2e;
@define-color background-alt #313244;
@define-color foreground #cdd6f4;
@define-color accent #cba6f7;
@define-color border #6c7086;
EOF

    ensure_file "$HOME/.config/mako/mako-colors" <<'EOF'
background-color=#1e1e2e
text-color=#cdd6f4
border-color=#cba6f7
EOF

    ensure_file "$HOME/.config/vesktop/themes/matugen.css" <<'EOF'
@import url("https://catppuccin.github.io/discord/dist/catppuccin-mocha.theme.css");

:root {
  --background-base-lowest: #11111b !important;
  --background-base-lower: #181825 !important;
  --background-base-low: #1e1e2e !important;
  --background-surface-high: #1e1e2e !important;
  --background-surface-higher: #313244 !important;
  --background-surface-highest: #45475a !important;
  --home-background: #1e1e2e !important;
  --chat-background: #1e1e2e !important;
  --chat-background-default: #1e1e2e !important;
  --channeltextarea-background: #181825 !important;
  --modal-background: #1e1e2e !important;
  --modal-footer-background: #1e1e2e !important;
  --background-accent: #313244 !important;
  --card-background-default: #313244 !important;
  --text-default: #cdd6f4 !important;
  --text-strong: #cdd6f4 !important;
  --text-muted: #a6adc8 !important;
  --text-subtle: #a6adc8 !important;
  --interactive-text-default: #cdd6f4 !important;
  --interactive-icon-default: #cdd6f4 !important;
  --icon-default: #cdd6f4 !important;
  --icon-strong: #cdd6f4 !important;
  --channels-default: #a6adc8 !important;
  --channel-icon: #a6adc8 !important;
  --brand-500: #cba6f7 !important;
  --brand-530: color-mix(in srgb, #cba6f7 88%, black);
  --brand-560: color-mix(in srgb, #cba6f7 76%, black);
  --brand-600: color-mix(in srgb, #cba6f7 64%, black);
  --text-link: #cba6f7 !important;
  --text-brand: #cba6f7;
  --control-brand-foreground: #cba6f7;
  --control-primary-background-default: #cba6f7 !important;
  --control-primary-background-hover: color-mix(in srgb, #cba6f7 88%, black);
  --control-primary-background-active: color-mix(in srgb, #cba6f7 76%, black);
  --scrollbar-thin-thumb: #cba6f7;
  --scrollbar-auto-thumb: #cba6f7;
  --mention-foreground: #cba6f7;
  --border-muted: #585b70 !important;
  --border-normal: #585b70 !important;
  --border-strong: #6c7086 !important;
}
EOF

    ensure_file "$HOME/.config/rofi/theme.rasi" <<'EOF'
* {
  main-bg: #1e1e2e;
  main-fg: #cdd6f4;
  main-br: #cba6f7;
  select-bg: #cba6f7;
  select-fg: #1e1e2e;
}
EOF

    if [ ! -e "$HOME/.cache/hyde/wall.quad" ]; then
      mkdir -p "$HOME/.cache/hyde"
      ${pkgs.imagemagick}/bin/magick -size 800x800 xc:'#1e1e2e' -alpha set \
        \( -size 800x800 gradient:black-white -rotate 90 \) \
        -compose CopyOpacity -composite "png:$HOME/.cache/hyde/wall.quad"
    fi
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
