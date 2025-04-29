{ pkgs, ... }: {
  services = {
    displayManager = {
      autoLogin.enable = true;
      autoLogin.user = "x11";
      defaultSession = "none+i3";
    };
    xserver = {
      desktopManager.xterm.enable = false; # Disable default terminal
      displayManager = {
        lightdm.enable = true;
        gdm.enable = false;
      };
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
    ratbagd.enable = true;
    dbus.enable = true;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  environment.systemPackages = with pkgs; [
    xorg.libX11
    xorg.libxcb
    xorg.libXi
    xorg.libXfixes
    xorg.libXcomposite
    xorg.libXtst
    xorg.libXext
    xorg.libXrender

    xorg.xrandr
    xorg.xinput
    xorg.xmodmap
    xorg.xwininfo
    xorg.xhost
    xorg.xinit

    xorg.xprop
  ];
}
