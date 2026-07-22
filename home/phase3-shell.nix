{ config, pkgs, ... }:

{
  # ── Ghostty terminal ──────────────────────────────────────────────────────
  programs.ghostty = {
    enable = true;
    settings = {
      background = "1e1e2e";
      foreground = "cdd6f4";
      cursor-color = "f5e0dc";
      selection-background = "45475a";
      selection-foreground = "cdd6f4";
      font-family = "JetBrainsMono Nerd Font";
      font-size = 13;
      cursor-style = "bar";
      cursor-style-blink = true;
      window-padding-x = 12;
      window-padding-y = 8;
      window-decoration = false;    # Hyprland handles borders
      background-opacity = 0.88;
      gtk-single-instance = false;
      confirm-close-surface = false;
      copy-on-select = true;

      # Shell integration
      shell-integration = "bash";
    };
  };

  # ── Pre-generated shell init scripts ─────────────────────────────────────
  xdg.configFile = {
    "bash/fzf-init.bash".text =
      builtins.readFile (pkgs.runCommand "fzf-init" {} ''
        ${pkgs.fzf}/bin/fzf --bash > $out
      '');

    "bash/zoxide-init.bash".text =
      builtins.readFile (pkgs.runCommand "zoxide-init" {} ''
        ${pkgs.zoxide}/bin/zoxide init bash --cmd cd > $out
      '');

    "bash/starship-init.bash".text =
      builtins.readFile (pkgs.runCommand "starship-init" {} ''
        ${pkgs.starship}/bin/starship init bash > $out
      '');
  };

  # ── Bash ──────────────────────────────────────────────────────────────────
  programs.bash = {
    enable = true;

    # History settings
    historySize = 100000;
    historyFileSize = 200000;
    historyControl = [ "ignoredups" "ignorespace" "erasedups" ];

    shellOptions = [
      "autocd"        # cd by typing directory name
      "checkwinsize"  # update LINES/COLUMNS after each command
      "globstar"      # ** glob works recursively
      "histappend"    # append to history, don't overwrite
    ];

    shellAliases = {
      # ── Navigation ──────────────────────────────────────────────────────
      ".."   = "cd ..";
      "..."  = "cd ../..";
      "...." = "cd ../../..";

      # ── eza (modern ls) ─────────────────────────────────────────────────
      ls   = "eza --icons --group-directories-first";
      ll   = "eza -la --icons --group-directories-first --git";
      lt   = "eza --tree --icons --level=2";
      llt  = "eza --tree --icons --level=3 -la";

      # ── bat (modern cat) ────────────────────────────────────────────────
      cat  = "bat --style=plain";
      catn = "bat";

      # ── Git shortcuts ───────────────────────────────────────────────────
      g    = "git";
      gs   = "git status";
      ga   = "git add";
      gc   = "git commit";
      gp   = "git push";
      gl   = "git pull";
      gd   = "git diff";
      lg   = "lazygit";

      # ── NixOS shortcuts ─────────────────────────────────────────────────
      nrs  = "sudo nixos-rebuild switch --flake /etc/nixos#ro";
      nrt  = "sudo nixos-rebuild test --flake /etc/nixos#ro";
      nrb  = "sudo nixos-rebuild boot --flake /etc/nixos#ro";
      ngc  = "sudo nix-collect-garbage -d";
      nup  = "sudo nix flake update /etc/nixos && sudo nixos-rebuild switch --flake /etc/nixos#ro";

      # ── System ──────────────────────────────────────────────────────────
      grep  = "grep --color=auto";
      df    = "df -h";
      du    = "du -sh";
      free  = "free -h";
      cp    = "cp -iv";
      mv    = "mv -iv";
      rm    = "rm -iv";
      mkdir = "mkdir -pv";
    };

    initExtra = ''
      # Only pay shell init costs for interactive shells.
      case $- in
        *i*) ;;
        *) return ;;
      esac

      # ── Pre-generated integrations ──────────────────────────────────────
      source "${config.xdg.configHome}/bash/fzf-init.bash"
      source "${config.xdg.configHome}/bash/zoxide-init.bash"
      source "${config.xdg.configHome}/bash/starship-init.bash"

      # ── fzf options ──────────────────────────────────────────────────────
      export FZF_DEFAULT_OPTS="
        --height=40%
        --layout=reverse
        --border=rounded
        --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
        --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
        --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
      export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
      export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
      export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"

      # ── bat theme ────────────────────────────────────────────────────────
      export BAT_THEME="Catppuccin Mocha"

      # ── History: share across terminals without reloading the full file ───
      if [[ -n "$PROMPT_COMMAND" ]]; then
        PROMPT_COMMAND="history -a; history -n; $PROMPT_COMMAND"
      else
        PROMPT_COMMAND="history -a; history -n"
      fi

      # ── Quick edit nixos config ───────────────────────────────────────────
      nixedit() {
        nvim /etc/nixos/"$@"
      }
    '';
  };

  # ── Starship prompt ───────────────────────────────────────────────────────
  programs.starship = {
    enable = true;
    settings = {
      format = "$directory$git_branch$git_status$python$rust$c$cmd_duration$line_break$character";

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol   = "[❯](bold red)";
      };

      directory = {
        style = "bold lavender";
        truncation_length = 3;
        truncate_to_repo = true;
      };

      git_branch = {
        symbol = " ";
        style  = "bold mauve";
      };

      git_status = {
        style = "bold red";
      };

      python = {
        symbol = " ";
        style  = "bold yellow";
        format = "[$symbol($version )(\\($virtualenv\\) )]($style)";
      };

      rust = {
        symbol = " ";
        style  = "bold peach";
      };

      c = {
        symbol = " ";
        style  = "bold blue";
      };

      cmd_duration = {
        min_time = 2000;
        format   = "[ $duration]($style) ";
        style    = "bold yellow";
      };

      # Catppuccin Mocha palette
      palette = "catppuccin_mocha";
      palettes.catppuccin_mocha = {
        rosewater = "#f5e0dc";
        flamingo  = "#f2cdcd";
        pink      = "#f5c2e7";
        mauve     = "#cba6f7";
        red       = "#f38ba8";
        maroon    = "#eba0ac";
        peach     = "#fab387";
        yellow    = "#f9e2af";
        green     = "#a6e3a1";
        teal      = "#94e2d5";
        sky       = "#89dceb";
        sapphire  = "#74c7ec";
        blue      = "#89b4fa";
        lavender  = "#b4befe";
        text      = "#cdd6f4";
        subtext1  = "#bac2de";
        subtext0  = "#a6adc8";
        overlay2  = "#9399b2";
        overlay1  = "#7f849c";
        overlay0  = "#6c7086";
        surface2  = "#585b70";
        surface1  = "#45475a";
        surface0  = "#313244";
        base      = "#1e1e2e";
        mantle    = "#181825";
        crust     = "#11111b";
      };
    };
  };

  # ── Shell tool packages ───────────────────────────────────────────────────
  home.packages = with pkgs; [
    fzf
    zoxide
    bat
    eza
    fd           # fast find, used by fzf
    ripgrep      # fast grep, essential for Neovim and general use
    tree
    jq           # JSON processing in scripts
    htop
    sysstat
  ];
}