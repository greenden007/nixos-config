{ config, pkgs, ... }:

{
  # ── NVIDIA RTX 5080 ───────────────────────────────────────────────────────
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;      # desktop — no need
    powerManagement.finegrained = false;
    open = false;                        # use proprietary driver (better CUDA support)
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;                  # needed for Steam / 32-bit games
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
    ];
  };

  # ── CUDA ──────────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    cudatoolkit
    libva-utils
    nvtopPackages.nvidia
    vulkan-tools
  ];

  # Allow unfree packages (NVIDIA driver + CUDA are unfree)
  nixpkgs.config.allowUnfree = true;

  # ── Environment variables for Wayland + NVIDIA ────────────────────────────
  environment.sessionVariables = {
    # Tell Hyprland to use the NVIDIA DRM
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
    XDG_SESSION_TYPE = "wayland";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";      # fixes invisible cursor on NVIDIA
    # JetBrains: force XWayland rendering
    JETBRAINS_CLIENT_WAYLAND = "0";
  };
}
