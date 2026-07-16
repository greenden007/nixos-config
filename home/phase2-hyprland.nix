{ config, pkgs, inputs, ... }:

{
  # ── Hyprland dotfile ───────────────────────────────────────────────────────
  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;

    settings = {
      # ── Monitor layout ──────────────────────────────────────────────────
      # Adjust to your actual monitor setup.
      # Format: name, resolution@hz, position, scale
      monitor = [
        "DP-1,3840x2160@240,0x0,1.5"   # MPG 321URX QD-OLED
        ",preferred,auto,1"              # fallback for any other monitor
      ];

      # ── General ─────────────────────────────────────────────────────────
      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
        "col.active_border" = "rgba(cba6f7ff) rgba(89b4faff) 45deg";
        "col.inactive_border" = "rgba(585b70ff)";
        layout = "dwindle";
      };

      # ── Decoration ──────────────────────────────────────────────────────
      decoration = {
        rounding = 8;
        blur = {
          enabled = true;
          size = 6;
          passes = 2;
          vibrancy = 0.2;
        };
        shadow = {
          enabled = true;
          range = 12;
          color = "rgba(1a1a2ecc)";
        };
      };

      # ── Animations ──────────────────────────────────────────────────────
      animations = {
        enabled = true;
        bezier = [
          "easeOut,0.16,1,0.3,1"
          "easeIn,0.7,0,0.84,0"
        ];
        animation = [
          "windows,1,4,easeOut,popin 85%"
          "windowsOut,1,3,easeIn,popin 85%"
          "fade,1,4,easeOut"
          "workspaces,1,4,easeOut,slide"
        ];
      };

      # ── Input ───────────────────────────────────────────────────────────
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
        };
      };

      # ── Layout: dwindle (binary space partitioning) ──────────────────
      dwindle = {
        preserve_split = true;
      };

      # ── Startup apps ────────────────────────────────────────────────────
      exec-once = [
        "waybar"
        "hypridle"
        "mako"
        "wl-paste --watch cliphist store"  # clipboard history daemon
      ];

      # ── Environment variables ────────────────────────────────────────────
      env = [
        "XCURSOR_SIZE,24"
        "XCURSOR_THEME,Bibata-Modern-Classic"
        "GTK_THEME,catppuccin-mocha-mauve-standard+default"
      ];

      # ── Keybindings ($mainMod = Super, which keyd maps to your ⌘ key) ──
      "$mainMod" = "SUPER";

      bind = [
        # Core WM
        "$mainMod,Return,exec,ghostty"
        "$mainMod,Q,killactive"
        "$mainMod,M,exit"
        "$mainMod,E,exec,nautilus"
        "$mainMod,V,togglefloating"
        "$mainMod,Space,exec,rofi -show drun"
        "$mainMod,Tab,exec,rofi -show window"
        "$mainMod,W,exec,wallpaper-picker"
        "$mainMod,F,fullscreen"

        # Move focus with mainMod + arrow keys
        "$mainMod,left,movefocus,l"
        "$mainMod,right,movefocus,r"
        "$mainMod,up,movefocus,u"
        "$mainMod,down,movefocus,d"

        # Workspaces
        "$mainMod,1,workspace,1"
        "$mainMod,2,workspace,2"
        "$mainMod,3,workspace,3"
        "$mainMod,4,workspace,4"
        "$mainMod,5,workspace,5"

        # Move window to workspace
        "$mainMod SHIFT,1,movetoworkspace,1"
        "$mainMod SHIFT,2,movetoworkspace,2"
        "$mainMod SHIFT,3,movetoworkspace,3"
        "$mainMod SHIFT,4,movetoworkspace,4"
        "$mainMod SHIFT,5,movetoworkspace,5"

        # Clipboard history via rofi
        "$mainMod,C,exec,cliphist list | rofi -dmenu | cliphist decode | wl-copy"

        # Screenshot
        ",Print,exec,hyprshot"
        "$mainMod,Print,exec,hyprshot --region"

        # Logout menu
        "$mainMod SHIFT,E,exec,wlogout"
      ];

      # Resize windows with mouse
      bindm = [
        "$mainMod,mouse:272,movewindow"
        "$mainMod,mouse:273,resizewindow"
      ];

      # Window rules
      windowrule = [
        # Steam/Proton game windows usually expose class steam_app_<appid>.
        "fullscreen on, match:class ^(steam_app_.*)$"
        "sync_fullscreen on, match:class ^(steam_app_.*)$"
        "immediate on, match:class ^(steam_app_.*)$"
        "no_max_size on, match:class ^(steam_app_.*)$"
        "fullscreen on, match:class ^(gamescope)$"
        "sync_fullscreen on, match:class ^(gamescope)$"
        "immediate on, match:class ^(gamescope)$"

        # JetBrains (XWayland)
        "center on, match:class ^(jetbrains-.*)$"
        "size 1800 1100, match:class ^(jetbrains-.*)$"
        "float on, match:class ^(jetbrains-.*)$, match:title ^(splash)$"
      ];
    };
  };

  # ── Hyprpaper ─────────────────────────────────────────────────────────────
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    ipc = true
    splash = false

    wallpaper {
      monitor =
      path = ~/.config/hypr/wallpaper.png
      fit_mode = cover
    }
  '';

  systemd.user.services.hyprpaper = {
    Unit = {
      Description = "Hyprland wallpaper daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.hyprpaper}/bin/hyprpaper";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # ── Hyprlock ──────────────────────────────────────────────────────────────
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor = true;
      };
      background = [{
        monitor = "";
        path = "~/.config/hypr/wallpaper.png";
        blur_passes = 4;
        blur_size = 10;
      }];
      label = [
        {
          monitor = "";
          text = "$TIME";
          color = "rgb(cdd6f4)";
          font_size = 84;
          font_family = "SF Pro Display";
          position = "0, 126";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "$DAYSUN $DAY, $MONTH $DAY_NUMBER";
          color = "rgba(205, 214, 244, 0.78)";
          font_size = 20;
          font_family = "SF Pro Text";
          position = "0, 64";
          halign = "center";
          valign = "center";
        }
      ];
      input-field = [{
        monitor = "";
        size = "360, 54";
        position = "0, -12";
        halign = "center";
        valign = "center";
        outer_color = "rgba(255, 255, 255, 0.16)";
        inner_color = "rgba(255, 255, 255, 0.08)";
        font_color = "rgb(cdd6f4)";
        outline_thickness = 1;
        dots_size = 0.28;
        dots_spacing = 0.35;
        dots_center = true;
        fade_on_empty = false;
        placeholder_text = "Password";
        hide_input = false;
        rounding = 20;
      }];
    };
  };

  # ── Hypridle ──────────────────────────────────────────────────────────────
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        after_sleep_cmd = "hyprctl dispatch dpms on";
        before_sleep_cmd = "hyprlock";
        lock_cmd = "hyprlock";
      };
      listener = [
        { timeout = 300;  on-timeout = "hyprlock"; }
        { timeout = 600;  on-timeout = "hyprctl dispatch dpms off";
                          on-resume  = "hyprctl dispatch dpms on"; }
      ];
    };
  };

  # ── Mako (notifications) ──────────────────────────────────────────────────
  services.mako = {
    enable = true;
  };

  # ── Waybar ────────────────────────────────────────────────────────────────
  programs.waybar = {
    enable = true;
    settings = [{
      layer = "top";
      position = "top";
      height = 36;
      spacing = 4;
      modules-left  = [ "hyprland/workspaces" "hyprland/window" "custom/theme" ];
      modules-center = [ "clock" ];
      modules-right = [
        "custom/ml-status"
        "cpu" "memory" "temperature"
        "pulseaudio" "network"
        "custom/peripheral-battery" "battery" "tray"
      ];

      "hyprland/workspaces" = {
        format = "{id}";
        on-click = "activate";
      };

      clock = {
        format = "{:%a %b %d  %H:%M}";
        tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
      };

      cpu = {
        format = "CPU {usage}%";
        interval = 2;
        on-click = "ghostty -e btop";
      };

      memory = {
        format = "RAM {used:0.1f}G";
        interval = 5;
        on-click = "ghostty -e btop";
      };

      temperature = {
        format = "TEMP {temperatureC}°C";
        critical-threshold = 90;
        on-click = "ghostty -e btop";
      };

      network = {
        format-wifi = "NET {essid}";
        format-ethernet = "󰈀 {ipaddr}";
        format-disconnected = "󰖪 Off";
        tooltip-format = "{ifname}: {ipaddr}/{cidr}";
        on-click = "nm-connection-editor";
        on-click-right = "ghostty -e nmtui";
      };

      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = "󰝟 muted";
        format-icons = { default = [ "󰕿" "󰖀" "󰕾" ]; };
        on-click = "pavucontrol";
      };

      "custom/ml-status" = {
        exec = "waybar-ml-status";
        return-type = "json";
        interval = 2;
        tooltip = true;
        on-click = "ghostty -e nvtop";
        on-click-right = "ml-training-dashboard";
      };

      "custom/peripheral-battery" = {
        exec = "waybar-peripheral-battery";
        return-type = "json";
        interval = 30;
        tooltip = true;
        on-click = "ghostty -e bash -lc 'upower -d; exec bash'";
      };

      "custom/theme" = {
        exec = "waybar-theme-status";
        return-type = "json";
        interval = 10;
        tooltip = true;
        on-click = "wallpaper-picker";
        on-click-right = "theme-refresh";
      };

      tray = { spacing = 8; };
    }];

  };

  # ── Rofi ──────────────────────────────────────────────────────────────────
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    terminal = "${pkgs.ghostty}/bin/ghostty";
    theme = "~/.local/share/rofi/themes/matugen.rasi";
    extraConfig = {
      modi = "drun,window,run";
      show-icons = true;
      icon-theme = "Papirus-Dark";
      drun-display-format = "{name}";
      disable-history = false;
      sidebar-mode = false;
    };
  };

  # ── wlogout ───────────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    wlogout
    cliphist
    wl-clipboard
    hyprshot
    libnotify
  ];
}
