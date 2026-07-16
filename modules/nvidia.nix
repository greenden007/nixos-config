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
    open = true;                         # newer RTX cards prefer the open kernel module
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
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

  # ── Environment variables for Wayland + NVIDIA ────────────────────────────
  environment.sessionVariables = {
    # Tell Hyprland to use the NVIDIA DRM
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
    XDG_SESSION_TYPE = "wayland";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    __GL_VRR_ALLOWED = "1";
    WLR_NO_HARDWARE_CURSORS = "1";      # kept for older wlroots-based tools
    # JetBrains: force XWayland rendering
    JETBRAINS_CLIENT_WAYLAND = "0";
  };
}
