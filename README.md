# NixOS Config

Hyprland · Catppuccin Mocha · JetBrains · Bash · RTX 5080 / CUDA

---

## File structure

```
nixos-config/
├── flake.nix                  # Root flake: NixOS + Home Manager inputs
├── configuration.nix          # System-level config (boot, NVIDIA, users)
├── hardware-configuration.nix # Auto-generated — do not edit by hand
├── home.nix                   # Home Manager entry point
├── modules/
│   ├── nvidia.nix             # RTX 5080 driver + CUDA + env vars
│   ├── hyprland.nix           # System-level Hyprland + greetd login
│   └── keyd.nix               # Mac keyboard layout remapping
└── home/
    ├── default.nix            # Imports all phase modules
    ├── phase2-hyprland.nix    # Hyprland dotfile, Waybar, Mako, rofi, etc.
    ├── phase3-shell.nix       # Ghostty, Bash, Starship, fzf, zoxide, bat, eza
    ├── phase4-dev.nix         # JetBrains, Neovim/LazyVim, Supermaven, Git
    ├── phase5-apps.nix        # LibreWolf, Zathura, btop, nvtop, utilities
    └── phase6-theming.nix     # Catppuccin, fonts, cursors, GTK/Qt theming
```

---

## Deployment

### 1. Boot the NixOS minimal ISO and install

```bash
# Partition your disk (example — adjust device names with lsblk)
fdisk /dev/nvme0n1

# Format
mkfs.fat -F32 /dev/nvme0n1p1   # EFI (skip if Windows already created it)
mkfs.ext4 /dev/nvme0n1p3       # NixOS root
mkswap /dev/nvme0n1p2          # Swap (optional — 16GB recommended)

# Mount
mount /dev/nvme0n1p3 /mnt
mkdir /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot

# Generate base config
nixos-generate-config --root /mnt
```

### 2. Place this config

```bash
# Copy this repo into place (or clone from GitHub)
cp -r nixos-config/* /mnt/etc/nixos/

# Keep the generated hardware-configuration.nix
# (nixos-generate-config already wrote it to /mnt/etc/nixos/)
```

### 3. Install

```bash
nixos-install --flake /mnt/etc/nixos#ro
reboot
```

### 4. Post-boot: activate Home Manager and rebuild

```bash
sudo nixos-rebuild switch --flake /etc/nixos#ro
```

### 5. Install Flatpak apps

```bash
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.discordapp.Discord
flatpak install flathub com.spotify.Client
```

---

## Common commands

| Alias | What it does |
|-------|-------------|
| `nrs` | nixos-rebuild switch (apply config changes) |
| `nrt` | nixos-rebuild test (test without making boot default) |
| `nrb` | nixos-rebuild boot (apply on next boot only) |
| `nup` | Update flake inputs + rebuild |
| `ngc` | Garbage collect old generations |
| `nixedit <file>` | Open a file in /etc/nixos with nvim |
| `lg` | lazygit |

---

## Phase rollout order

Deploy one phase at a time, running `nrs` between each to confirm stability:

1. **Phase 1** — base install (done during nixos-install)
2. **Phase 2** — Hyprland desktop
3. **Phase 3** — shell (Ghostty, Bash, Starship)
4. **Phase 4** — dev (JetBrains, Neovim, Supermaven)
5. **Phase 5** — apps (browser, viewers, profiling)
6. **Phase 6** — theming (Catppuccin, fonts, cursors)

To deploy only through Phase 3 initially, comment out Phase 4–6 imports in `home/default.nix`.

---

## Things to personalise before first build

- `configuration.nix` → `networking.hostName`
- `modules/nvidia.nix` → confirm `nvidiaPackages.stable` matches your driver
- `home/phase2-hyprland.nix` → `monitor` line: adjust resolution/refresh to your panel
- `home/phase4-dev.nix` → `programs.git.userEmail`
- `home/phase6-theming.nix` → Catppuccin bat theme `sha256` (verify on first build)
# nixos-config
