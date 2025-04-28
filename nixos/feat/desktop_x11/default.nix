{ pkgs, ... }: {
  services = {
    displayManager = {
      autoLogin.enable = true;
      autoLogin.user = "x11";
      defaultSession = "none+i3";
    };
    xserver = {
      desktopManager.xterm.enable = false; # Disable default terminal
      displayManager = { lightdm.enable = true; };
      enable = true;
      windowManager.i3 = {
        enable = true;
        extraPackages = with pkgs; [
          dmenu # Application launcher
          i3status # Status bar
          i3lock # Screen locker
          i3blocks # Alternative status bar (optional)
        ];
      };
    };
  };
}
