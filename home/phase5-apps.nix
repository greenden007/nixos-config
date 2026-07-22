{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    # ── Browser ─────────────────────────────────────────────────────────────
    librewolf
    firefox-bin

    # ── Communication / notes / AI tools ────────────────────────────────────
    claude-code
    # discord replaced by programs.vesktop (phase6-theming.nix) — Vencord-bundled
    # client, needed so Discord can actually load custom/matugen-driven CSS.
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
      runtimeInputs = [ findutils rofi coreutils matugen systemd libnotify imagemagick hyprland jq gawk ];
      text = ''
        set -euo pipefail

        wallpaper_dir="''${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
        target_dir="$HOME/.config/hypr"
        target="$target_dir/wallpaper.png"
        theme="$HOME/.local/share/rofi/themes/wallpaper-grid.rasi"
        thumb_dir="$HOME/.cache/hyde/thumbs"
        current_file="$target_dir/wallpaper-current"

        mkdir -p "$target_dir" "$thumb_dir"

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

        # Ported from HyDE's wallpaper/select.sh + core.sh (Wall_Json/Wall_Select):
        # each wallpaper gets a persistent square thumbnail cached by a hash of
        # its path, so repeat launches don't re-decode full-resolution photos.
        # rofi entries carry "name:::path:::thumb" — only the name is displayed
        # (-display-columns 1), the rest is recovered after selection.
        #
        # Entries are written straight to a file, not a bash variable: each
        # entry embeds a NUL byte (rofi's icon-dmenu separator), and bash
        # silently drops NUL bytes when a command substitution result is
        # captured into a variable, which would corrupt the icon markers.
        entries_file="$(mktemp)"
        trap 'rm -f "$entries_file"' EXIT

        while IFS= read -r img; do
          hash="$(printf '%s' "$img" | sha1sum | cut -d' ' -f1)"
          thumb="$thumb_dir/$hash.sqre"
          if [[ ! -e "$thumb" ]]; then
            thumb_tmp="$thumb.tmp"
            magick "$img" -resize 400x400^ -gravity center -extent 400x400 "png:$thumb_tmp"
            mv "$thumb_tmp" "$thumb"
          fi
          printf '%s:::%s:::%s\0icon\x1f%s\n' "$(basename "$img")" "$img" "$thumb" "$thumb" >> "$entries_file"
        done <<< "$images"

        # Column count and rounding follow your actual monitor width and
        # Hyprland border radius, same formula HyDE's picker uses, so the
        # grid always fills the screen sensibly instead of a fixed count.
        font_scale=10
        elem_border=24
        col_count=3
        if [[ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl >/dev/null 2>&1; then
          mon_x_res="$(hyprctl -j monitors 2>/dev/null \
            | jq '[.[] | select(.focused==true)] | .[0] | if (.transform % 2 == 0) then .width else .height end' 2>/dev/null || echo 1920)"
          mon_scale="$(hyprctl -j monitors 2>/dev/null \
            | jq -r '[.[] | select(.focused==true)] | .[0].scale' 2>/dev/null | tr -d '.' || echo 100)"
          [[ "$mon_x_res" =~ ^[0-9]+$ ]] || mon_x_res=1920
          [[ "$mon_scale" =~ ^[0-9]+$ ]] || mon_scale=100
          mon_x_res=$((mon_x_res * 100 / mon_scale))
          elm_width=$(((28 + 8 + 5) * font_scale))
          max_avail=$((mon_x_res - (4 * font_scale)))
          col_count=$((max_avail / elm_width))
          [[ $col_count -ge 1 ]] || col_count=3
          hypr_round="$(hyprctl getoption decoration:rounding -j 2>/dev/null | jq -r '.int' 2>/dev/null || echo 8)"
          [[ "$hypr_round" =~ ^[0-9]+$ ]] || hypr_round=8
          elem_border=$((hypr_round * 3))
        fi
        grid_override="window{width:100%;} listview{columns:''${col_count};spacing:5em;} element{border-radius:''${elem_border}px;orientation:vertical;} element-icon{size:28em;border-radius:0em;} element-text{padding:1em;}"

        select_args=()
        if [[ -e "$current_file" ]]; then
          select_args=(-select "$(basename "$(cat "$current_file")")")
        fi

        entry="$(${rofi}/bin/rofi -dmenu -show-icons -i -p "Wallpaper" -theme "$theme" \
              -display-column-separator ":::" -display-columns 1 \
              -theme-str "$grid_override" \
              "''${select_args[@]}" < "$entries_file" || true)"

        [[ -n "$entry" ]] || exit 0
        selection="$(awk -F ':::' '{print $2}' <<< "$entry")"
        [[ -n "$selection" ]] && [[ -e "$selection" ]] || exit 0

        tmp="$target.tmp"
        magick "$selection" "png:$tmp"
        mv "$tmp" "$target"
        printf '%s\n' "$selection" > "$current_file"

        # HyDE's style_11 rofi launcher shows a wallpaper crop in its sidebar
        # panel, faded from fully opaque (left) to transparent (right,
        # blending into the listbox) — style_11's image panel sits on the
        # LEFT (unlike style_12, where it's on the right), so the fade runs
        # the opposite direction here.
        quad_dir="$HOME/.cache/hyde"
        quad_tmp="$quad_dir/wall.quad.tmp"
        mkdir -p "$quad_dir"
        magick "$target" -resize 800x800^ -gravity center -extent 800x800 -alpha set \
          \( -size 800x800 gradient:black-white -rotate 90 \) \
          -compose CopyOpacity -composite "png:$quad_tmp"
        mv "$quad_tmp" "$quad_dir/wall.quad"

        matugen image "$target" >/dev/null

        systemctl --user start hyprpaper.service >/dev/null 2>&1 || true

        if command -v hyprctl >/dev/null 2>&1; then
          # hyprpaper caches by path, not content — since $target is always
          # the same filename, plain preload/wallpaper won't pick up new
          # bytes on disk. `reload` is hyprpaper's dedicated command for
          # exactly this case: it unloads the old copy, preloads the fresh
          # file, and sets it, atomically.
          hyprctl hyprpaper reload ",$target" >/dev/null 2>&1 || true
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
