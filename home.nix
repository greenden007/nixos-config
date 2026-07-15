{ config, pkgs, inputs, ... }:

{
  imports = [
    ./home                    # loads home/default.nix which imports phases
  ];

  home.username = "lockie";
  home.homeDirectory = "/home/lockie";
  home.stateVersion = "24.11";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
