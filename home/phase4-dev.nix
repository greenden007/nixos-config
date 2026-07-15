{ config, pkgs, ... }:

{
  # ── JetBrains IDEs ────────────────────────────────────────────────────────
  # Installed via nixpkgs jetbrains set; nix-ld in configuration.nix
  # provides the FHS shims they need to run on NixOS.
  home.packages = with pkgs; [
    jetbrains.pycharm-professional   # Python / ML
    jetbrains.clion                  # Rust / C / C++

    # ── Rust toolchain ──────────────────────────────────────────────────────
    rustup        # manages stable/nightly, rustfmt, clippy, rust-analyzer

    # ── C/C++ toolchain ─────────────────────────────────────────────────────
    gcc
    clang
    clang-tools   # includes clangd LSP + clang-format
    cmake
    gnumake
    ninja

    # ── Python toolchain ────────────────────────────────────────────────────
    python313
    python313Packages.pip
    python313Packages.virtualenv
    uv            # fast pip/venv replacement, great for ML projects

    # ── Dev utilities ────────────────────────────────────────────────────────
    lazygit
    git-delta     # beautiful git diffs
    gh            # GitHub CLI
    httpie        # human-friendly curl
    docker-compose

    # ── LSP / language servers used outside JetBrains (Neovim) ─────────────
    pyright
    nodePackages.typescript-language-server
    lua-language-server
    nixd          # Nix LSP — essential for editing your own config
    nil           # alternative Nix LSP
  ];

  # ── Neovim (terminal editing + quick config edits) ────────────────────────
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias  = true;
    vimAlias = true;

    # LazyVim handles plugin management — we just need the base config file.
    # LazyVim is bootstrapped on first launch; no plugin declarations here.
    extraPackages = with pkgs; [
      # Tools Neovim plugins shell out to
      ripgrep
      fd
      tree-sitter
      nodejs   # required by some LSP installers
    ];

    # Minimal init.lua that bootstraps LazyVim
    extraLuaConfig = ''
      -- Bootstrap lazy.nvim
      local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
      if not vim.loop.fs_stat(lazypath) then
        vim.fn.system({
          "git", "clone", "--filter=blob:none",
          "https://github.com/folke/lazy.nvim.git",
          "--branch=stable", lazypath,
        })
      end
      vim.opt.rtp:prepend(lazypath)

      -- Bootstrap LazyVim
      require("lazy").setup({
        spec = {
          { "LazyVim/LazyVim", import = "lazyvim.plugins" },
          -- Enable language extras
          { import = "lazyvim.plugins.extras.lang.python" },
          { import = "lazyvim.plugins.extras.lang.rust" },
          { import = "lazyvim.plugins.extras.lang.clangd" },
          -- Catppuccin colorscheme
          {
            "catppuccin/nvim",
            name = "catppuccin",
            priority = 1000,
            opts = { flavour = "mocha" },
          },
          -- Supermaven autocomplete
          {
            "supermaven-inc/supermaven-nvim",
            opts = {
              keymaps = {
                accept_suggestion = "<Tab>",
                clear_suggestion  = "<C-]>",
                accept_word       = "<C-j>",
              },
              ignore_filetypes = { "TelescopePrompt" },
              color = {
                suggestion_color = "#6c7086",
                cterm = 244,
              },
            },
          },
        },
        defaults = {
          lazy = false,
          version = false,
        },
        install = {
          colorscheme = { "catppuccin" },
        },
        checker = {
          enabled = true,
          notify  = false,
        },
      })

      -- Set colorscheme
      vim.cmd.colorscheme("catppuccin-mocha")
    '';
  };

  # ── Git configuration ─────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    userName  = "lockie";
    userEmail = "your@email.com";   # replace with your email

    delta = {
      enable = true;
      options = {
        navigate    = true;
        side-by-side = true;
        line-numbers = true;
        syntax-theme = "Catppuccin Mocha";
      };
    };

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core = {
        editor    = "nvim";
        autocrlf  = "input";
      };
      diff.colorMoved = "default";
    };

    aliases = {
      lg  = "log --oneline --graph --decorate --all";
      undo = "reset HEAD~1 --mixed";
      amend = "commit --amend --no-edit";
    };
  };
}
