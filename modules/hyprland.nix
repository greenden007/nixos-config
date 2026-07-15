{ config, pkgs, inputs, ... }:

{
  # ── Hyprland ──────────────────────────────────────────────────────────────
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    xwayland.enable = true;   # needed for JetBrains + any X11 apps
  };

  # ── XDG desktop portal (screen sharing, file pickers) ─────────────────────
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  # ── Display manager: greetd + tuigreet (minimal, Wayland-native) ──────────
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  # ── System packages needed at the system level for Hyprland ───────────────
  environment.systemPackages = with pkgs; [
    xwayland
    wayland-utils
    wl-clipboard
    libnotify       # for notify-send used by scripts
  ];
}
