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
  };

  environment.systemPackages = with pkgs; [
    xorg.libX11
    xorg.libX11.dev
    xorg.libxcb
    xorg.libxcb.dev
    xorg.libXi
    xorg.libXi.dev
    xorg.libXfixes
    xorg.libXfixes.dev
    xorg.libXcomposite
    xorg.libXcomposite.dev
    xorg.libXtst
    xorg.libXext
    xorg.libXext.dev
    xorg.libXrender
    xorg.libXrender.dev

    xorg.xrandr
    xorg.xinput
    xorg.xmodmap
    xorg.xwininfo
    xorg.xhost
    xorg.xinit

    xorg.xprop
  ];
}
