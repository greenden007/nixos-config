{ config, pkgs, ... }:

{
  # ── NVIDIA RTX 5080 ───────────────────────────────────────────────────────
  services.xserver.videoDrivers = [ "nvidia" ];
  boot.kernelParams = [
    "nvidia_drm.modeset=1"
    "nvidia_drm.fbdev=1"
  ];

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
    __GL_VRR_ALLOWED = "1";
    AQ_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0";
    WLR_NO_HARDWARE_CURSORS = "1";      # kept for older wlroots-based tools
    # JetBrains: force XWayland rendering
    JETBRAINS_CLIENT_WAYLAND = "0";
  };
}
