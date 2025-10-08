{ ... }:
{
  imports = [
    ../modules/common.nix
    ../modules/shell.nix
    ../modules/homebrew.nix
  ];

  system.primaryUser = "kolen";
  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
