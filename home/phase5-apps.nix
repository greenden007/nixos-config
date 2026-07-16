{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # ── Browser ─────────────────────────────────────────────────────────────
    librewolf

    # ── Wallpaper theming ───────────────────────────────────────────────────
    matugen
    (writeShellApplication {
      name = "wallpaper-picker";
      runtimeInputs = [ findutils rofi coreutils matugen systemd ];
      text = ''
        set -euo pipefail

        wallpaper_dir="''${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
        target_dir="$HOME/.config/hypr"
        target="$target_dir/wallpaper.jpg"

        mkdir -p "$target_dir"

        selection="$(${findutils}/bin/find "$wallpaper_dir" -type f \
          \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
          | sort | ${rofi}/bin/rofi -dmenu -i -p Wallpaper)"

        [[ -n "$selection" ]] || exit 0

        cp "$selection" "$target"

        matugen image "$selection" >/dev/null

        systemctl --user try-restart hyprpaper.service >/dev/null 2>&1 || true
      '';
    })

    # ── Document / media viewers ────────────────────────────────────────────
    nautilus      # file manager used by the Hyprland Super+E binding
    zathura       # keyboard-driven PDF viewer
    imv           # lightweight Wayland image viewer

    # ── System profiling ─────────────────────────────────────────────────────
    btop          # beautiful TUI system monitor (CPU, mem, disk, net)
    nvtopPackages.nvidia  # GPU / CUDA monitor
    sysstat       # iostat, mpstat, pidstat
    perf-tools    # Linux perf for CPU profiling

    # ── Audio ────────────────────────────────────────────────────────────────
    pavucontrol   # PulseAudio/PipeWire volume control GUI

    # ── Wayland utilities ────────────────────────────────────────────────────
    wl-clipboard
    cliphist
    hyprshot

    # ── Misc utilities ───────────────────────────────────────────────────────
    unzip
    p7zip
    file
    which
    nmap
  ];

  # ── Zathura config ────────────────────────────────────────────────────────
  programs.zathura = {
    enable = true;
    options = {
      # Catppuccin Mocha colours
      default-bg           = "#1e1e2e";
      default-fg           = "#cdd6f4";
      statusbar-bg         = "#181825";
      statusbar-fg         = "#cdd6f4";
      inputbar-bg          = "#1e1e2e";
      inputbar-fg          = "#cdd6f4";
      notification-bg      = "#1e1e2e";
      notification-fg      = "#cdd6f4";
      notification-error-bg   = "#1e1e2e";
      notification-error-fg   = "#f38ba8";
      notification-warning-bg = "#1e1e2e";
      notification-warning-fg = "#fab387";
      highlight-color      = "#f9e2af";
      highlight-active-color = "#cba6f7";
      completion-bg        = "#313244";
      completion-fg        = "#cdd6f4";
      completion-highlight-bg = "#585b70";
      completion-highlight-fg = "#cdd6f4";
      recolor              = true;
      recolor-lightcolor   = "#1e1e2e";
      recolor-darkcolor    = "#cdd6f4";

      # Behaviour
      selection-clipboard  = "clipboard";
      adjust-open          = "best-fit";
      pages-per-row        = 1;
      scroll-step          = 80;
      zoom-min             = 10;
      render-loading       = true;
    };
  };

  # ── btop config ───────────────────────────────────────────────────────────
  programs.btop = {
    enable = true;
    settings = {
      color_theme     = "catppuccin_mocha";
      theme_background = false;
      vim_keys        = true;
      update_ms       = 1000;
      proc_sorting    = "cpu direct";
      proc_reversed   = true;
      show_gpu_info   = "Auto";
    };
  };

  # Discord and Spotify are installed via Flatpak (done post-boot):
  # flatpak install flathub com.discordapp.Discord
  # flatpak install flathub com.spotify.Client
  #
  # Managed outside Nix because their update cadence is faster than nixpkgs
  # and the Flatpak sandboxing handles Wayland compat automatically.
}
