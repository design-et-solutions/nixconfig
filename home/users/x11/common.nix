{ lib, config, pkgs, inputs, outputs, ... }:
let username = "x11";
in {
  imports = [
    (import ../../common { inherit username lib config pkgs outputs inputs; })
    ../../feat/desktop_x11
  ];

  fontProfiles = {
    enable = true;
    monospace = {
      name = "0xProto Nerd Font Mono";
      package = pkgs.nerd-fonts.fira-mono;
    };
    regular = {
      name = "0xProto Sans";
      package = pkgs.nerd-fonts.fira-code;
    };
  };

  programs.firefox.profiles = {
    "x11" = {
      id = 0;
      name = "x11";
      extensions.packages =
        with inputs.firefox-addons.packages.${pkgs.system}; [
          ublock-origin # ----> Content blocker
          browserpass # ------> Password manager
          vimium # -----------> Keyboard shortcuts
          privacy-badger # ---> Block invisible trackers
          new-tab-override # -> Set the page that shows whenever you open a new tab
        ];
    };
    p1 = {
      id = 1;
      name = "p1";
    };
    p2 = {
      id = 2;
      name = "p2";
    };
  };
}
