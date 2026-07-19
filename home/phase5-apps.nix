{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    # ── Browser ─────────────────────────────────────────────────────────────
    librewolf
    firefox-bin

    # ── Communication / notes / AI tools ────────────────────────────────────
    claude-code
    discord
    obsidian

    # ── Gaming / emulation ─────────────────────────────────────────────────
    prismlauncher  # Minecraft launcher; pkgs.minecraft is removed upstream
    gamescope
    mangohud
    (writeShellApplication {
      name = "modrinth";
      runtimeInputs = [ flatpak libnotify ];
      text = ''
        set -euo pipefail

        if flatpak info com.modrinth.ModrinthApp >/dev/null 2>&1; then
          exec flatpak run com.modrinth.ModrinthApp "$@"
        fi

        notify-send "Modrinth" "Install once with: flatpak install flathub com.modrinth.ModrinthApp"
        exit 1
      '';
    })
    azahar         # Citra-derived Nintendo 3DS emulator
    desmume        # Nintendo DS emulator

    # ── Writing / publishing ───────────────────────────────────────────────
    texliveFull

    # ── Wallpaper theming ───────────────────────────────────────────────────
    matugen
    (writeShellApplication {
      name = "wallpaper-picker";
      runtimeInputs = [ findutils rofi coreutils matugen systemd libnotify imagemagick hyprland ];
      text = ''
        set -euo pipefail

        wallpaper_dir="''${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
        target_dir="$HOME/.config/hypr"
        target="$target_dir/wallpaper.png"
        theme="$HOME/.local/share/rofi/themes/wallpaper-grid.rasi"

        mkdir -p "$target_dir"

        if [[ ! -d "$wallpaper_dir" ]]; then
          mkdir -p "$wallpaper_dir"
          notify-send "Wallpaper picker" "Add images to $wallpaper_dir"
          exit 1
        fi

        images="$(${findutils}/bin/find "$wallpaper_dir" -type f \
          \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
          | sort)"

        if [[ -z "$images" ]]; then
          notify-send "Wallpaper picker" "No images found in $wallpaper_dir"
          exit 1
        fi

        # rofi's icon-dmenu protocol: "Label\0icon\x1f/path/to/thumbnail"
        # renders each entry as a full-size thumbnail in the grid theme.
        # Label is the filename (with extension) so matching back is exact.
        entries="$(printf '%s\n' "$images" | while IFS= read -r img; do
          printf '%s\0icon\x1f%s\n' "$(basename "$img")" "$img"
        done)"

        selection_name="$(printf '%s\n' "$entries" \
          | ${rofi}/bin/rofi -dmenu -show-icons -i -p "Wallpaper" -theme "$theme" || true)"

        [[ -n "$selection_name" ]] || exit 0

        selection=""
        while IFS= read -r img; do
          if [[ "$(basename "$img")" == "$selection_name" ]]; then
            selection="$img"
            break
          fi
        done <<< "$images"
        [[ -n "$selection" ]] || exit 0

        tmp="$target.tmp"
        magick "$selection" "$tmp"
        mv "$tmp" "$target"
        printf '%s\n' "$selection" > "$target_dir/wallpaper-current"

        matugen image "$target" >/dev/null

        systemctl --user start hyprpaper.service >/dev/null 2>&1 || true

        if command -v hyprctl >/dev/null 2>&1; then
          hyprctl hyprpaper wallpaper ", $target, cover" >/dev/null 2>&1 || \
            hyprctl hyprpaper wallpaper ",$target,cover" >/dev/null 2>&1 || \
            hyprctl hyprpaper wallpaper ",$target" >/dev/null 2>&1 || true
        fi

        systemctl --user try-restart waybar.service mako.service >/dev/null 2>&1 || true
        notify-send "Wallpaper" "$(basename "$selection")"
      '';
    })
    (writeShellApplication {
      name = "waybar-theme-status";
      runtimeInputs = [ coreutils gnused ];
      text = ''
        set -euo pipefail

        current_file="$HOME/.config/hypr/wallpaper-current"
        wallpaper="$HOME/.config/hypr/wallpaper.png"

        if [[ -s "$current_file" ]]; then
          current="$(basename "$(cat "$current_file")")"
        elif [[ -e "$wallpaper" ]]; then
          current="wallpaper.png"
        else
          current="choose wallpaper"
        fi

        tooltip="Left click: choose wallpaper/theme\nRight click: regenerate theme"
        current="$(printf '%s' "$current" | sed 's/\\/\\\\/g; s/"/\\"/g')"
        tooltip="$(printf '%b' "$tooltip" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}')"
        printf '{"text":"BG %s","tooltip":"%s","class":"theme"}\n' "$current" "$tooltip"
      '';
    })
    (writeShellApplication {
      name = "theme-refresh";
      runtimeInputs = [ coreutils matugen systemd libnotify ];
      text = ''
        set -euo pipefail

        wallpaper="$HOME/.config/hypr/wallpaper.png"
        if [[ ! -e "$wallpaper" ]]; then
          notify-send "Theme refresh" "No wallpaper found at $wallpaper"
          exit 1
        fi

        matugen image "$wallpaper" >/dev/null
        systemctl --user try-restart waybar.service mako.service >/dev/null 2>&1 || true
        notify-send "Theme refresh" "Regenerated colors from current wallpaper"
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
    lm_sensors
    networkmanagerapplet
    upower
    (writeShellApplication {
      name = "waybar-ml-status";
      runtimeInputs = [ coreutils findutils gnugrep gnused gawk procps ];
      text = ''
        set -euo pipefail

        if ! command -v nvidia-smi >/dev/null 2>&1; then
          printf '{"text":"GPU n/a","tooltip":"nvidia-smi is not available","class":"idle"}\n'
          exit 0
        fi

        stats="$(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw --format=csv,noheader,nounits 2>/dev/null | head -n1 || true)"
        if [[ -z "$stats" ]]; then
          printf '{"text":"GPU off","tooltip":"No NVIDIA GPU data available","class":"idle"}\n'
          exit 0
        fi

        IFS=',' read -r gpu_util mem_used mem_total temp power <<< "$stats"
        gpu_util="$(printf '%s' "$gpu_util" | xargs)"
        mem_used="$(printf '%s' "$mem_used" | xargs)"
        mem_total="$(printf '%s' "$mem_total" | xargs)"
        temp="$(printf '%s' "$temp" | xargs)"
        power="$(printf '%s' "$power" | xargs)"

        procs="$(nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv,noheader,nounits 2>/dev/null || true)"
        if [[ -n "$procs" ]]; then
          class="training"
          tooltip="$(printf 'GPU %s%% | %s/%s MiB | %sC | %sW\n\n%s' "$gpu_util" "$mem_used" "$mem_total" "$temp" "$power" "$procs")"
        else
          class="idle"
          tooltip="$(printf 'GPU %s%% | %s/%s MiB | %sC | %sW\nNo active CUDA training processes' "$gpu_util" "$mem_used" "$mem_total" "$temp" "$power")"
        fi

        tooltip="$(printf '%s' "$tooltip" | sed 's/\\/\\\\/g; s/"/\\"/g')"
        printf '{"text":"GPU %s%% %sC %s/%sG","tooltip":"%s","class":"%s"}\n' \
          "$gpu_util" "$temp" "$((mem_used / 1024))" "$((mem_total / 1024))" "$tooltip" "$class"
      '';
    })
    (writeShellApplication {
      name = "waybar-peripheral-battery";
      runtimeInputs = [ upower coreutils gnugrep gnused gawk ];
      text = ''
        set -euo pipefail

        devices="$(upower -e 2>/dev/null | grep -E 'mouse|keyboard|headset|gaming_input|bluetooth' || true)"
        if [[ -z "$devices" ]]; then
          printf '{"text":"󰂯 --","tooltip":"No peripheral batteries reported by UPower","class":"idle"}\n'
          exit 0
        fi

        summary=""
        lowest=101
        while IFS= read -r dev; do
          info="$(upower -i "$dev" 2>/dev/null || true)"
          name="$(printf '%s\n' "$info" | awk -F: '/model|native-path/ {gsub(/^ +/, "", $2); print $2; exit}')"
          pct="$(printf '%s\n' "$info" | awk '/percentage:/ {gsub(/%/, "", $2); print int($2); exit}')"
          [[ -n "$pct" ]] || continue
          [[ -n "$name" ]] || name="$(basename "$dev")"
          summary="$summary$name: $pct%\n"
          if (( pct < lowest )); then lowest="$pct"; fi
        done <<< "$devices"

        if [[ -z "$summary" ]]; then
          printf '{"text":"󰂯 --","tooltip":"No peripheral battery percentages reported","class":"idle"}\n'
          exit 0
        fi

        class="ok"
        if (( lowest <= 20 )); then class="critical"; elif (( lowest <= 40 )); then class="warning"; fi
        tooltip="$(printf '%b' "$summary" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}')"
        printf '{"text":"󰂯 %s%%","tooltip":"%s","class":"%s"}\n' "$lowest" "$tooltip" "$class"
      '';
    })
    (writeShellApplication {
      name = "ml-training-dashboard";
      runtimeInputs = [ findutils coreutils ghostty libnotify python313Packages.tensorboard ];
      text = ''
        set -euo pipefail

        logdir="''${TENSORBOARD_LOGDIR:-}"
        if [[ -z "$logdir" ]]; then
          logdir="$(find "$HOME" -maxdepth 5 -type f -name 'events.out.tfevents.*' -printf '%h\n' 2>/dev/null | sort -u | paste -sd, -)"
        fi

        if [[ -z "$logdir" ]]; then
          notify-send "TensorBoard" "No event files found. Set TENSORBOARD_LOGDIR to your training log directory."
          exit 1
        fi

        ghostty -e bash -lc "tensorboard --logdir '$logdir' --host 127.0.0.1 --port 6006"
      '';
    })

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

  home.activation.ensureHyprWallpaperPng = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="$HOME/.config/hypr/wallpaper.png"
    fallback="$HOME/.config/hypr/wallpaper.jpg"
    if [ ! -e "$target" ] && [ -e "$fallback" ]; then
      mkdir -p "$(dirname "$target")"
      ${pkgs.imagemagick}/bin/magick "$fallback" "$target"
    fi
  '';

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
