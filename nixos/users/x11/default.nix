{ pkgs, config, inputs, ... }:
let
  username = "x11";
  ifTheyExist = groups:
    builtins.filter (group: builtins.hasAttr group config.users.groups) groups;

in {
  imports = [
    # Includes the Home Manager module from the home-manager input in NixOS configuration
    inputs.home-manager.nixosModules.home-manager
  ];

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = ifTheyExist [
      "wheel"
      "video"
      "audio"
      "docker"
      "git"
      "i2c"
      "network"
      "plugdev"
    ];
    password = "x11";
    shell = pkgs.fish;
    packages = [ pkgs.home-manager ];
  };

  home-manager.users.${username} =
    import ../../../home/users/${username}/common.nix;

  security.pam.services = { swaylock = { }; };
}
