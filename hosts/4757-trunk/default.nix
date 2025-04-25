{ inputs, pkgs, ... }:
let hostname = "4757-trunk";
in {
  imports = [
    # Includes the Disko module from the disko input in NixOS configuration
    inputs.disko.nixosModules.disko

    ./hardware-configuration.nix
    ./disko-configuration.nix

    ../../nixos/common
    ../../nixos/users/x11

    ../../nixos/feat/desktop_x11
  ];

  time.timeZone = "Europe/Paris";

  networking = {
    hostName = "${hostname}";
    hosts = { "192.100.1.1" = [ "cdp.thales" ]; };
    networkmanager = { enable = true; };
    firewall = {
      enable = true;
      logRefusedConnections = true;
      allowedTCPPorts = [ 80 443 8080 ];
    };
  };

  services.xserver.displayManager.gdm = { banner = "Welcome home"; };

  virtualisation.docker.enable = true;

  services.touchegg.enable = true;

  environment.systemPackages = with pkgs; [
    xdotool
    libinput-gestures
    touchegg
    wmctrl
    unclutter-xfixes
    nginx
    ffmpeg
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    gst_all_1.gst-vaapi
    qt5.qtbase
    qt5.qttools
  ];

  services.picom = {
    enable = true;
    backend = "xrender";
    fade = true;
    shadow = true;
    settings = {
      corner-radius = 5;
      blur-background = true;
      blur-kern = "7x7box";
    };
  };

  systemd.services."rtsp-to-hls" = {
    # enable = false;
    description = "Middleware RTSP to HLS";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /var/www/html/hls";
      # ExecStart = "${pkgs.ffmpeg}/bin/ffmpeg -fflags nobuffer -flags low_delay -strict experimental -i rtsp://192.168.100.134:8554/vivatech-simu -c:v libx264 -preset ultrafast -tune zerolatency -x264-params keyint=20:min-keyint=20:scenecut=0 -g 20 -sc_threshold 0 -start_number 0 -an -f hls -hls_time 2 -hls_list_size 10 -hls_flags delete_segments+append_list+omit_endlist -hls_delete_threshold 2 /var/www/html/hls/stream.m3u8";
      ExecStart =
        "${pkgs.ffmpeg}/bin/ffmpeg -fflags nobuffer -flags low_delay -strict experimental -i rtsp://192.168.100.134:8554/vivatech-simu -c:v libx264 -preset ultrafast -tune zerolatency -g 30 -sc_threshold 0 -start_number 0 -f hls -hls_time 2 -hls_list_size 10 -hls_flags delete_segments+append_list+omit_endlist /var/www/html/hls/stream.m3u8";
      # ExecStart = "${pkgs.ffmpeg}/bin/ffmpeg -i rtsp://192.168.100.134:8554/vivatech-simu -c:v on -preset -g 30 -sc_threshold 0 -start_number 0 -f hls -hls_time 2 -hls_list_size 7 -hls_flags delete_segments+append_list+omit_endlist /var/www/html/hls/stream.m3u8";
      Restart = "always";
      RestartSec = "5s";
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts."localhost" = {
      locations."/" = {
        root = "/var/www/html";
        index = "index.html";
      };
      locations."/hls/" = {
        root = "/var/www/html";
        extraConfig = ''
          add_header Cache-Control no-cache;
          add_header Access-Control-Allow-Origin *;
          types {
            application/vnd.apple.mpegurl m3u8;
            video/mp2t ts;
          }
        '';
      };
    };
  };

  systemd.services."auto-web-1" = {
    description = "Run Firefox with a specific URL";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "x11";
      ExecStart =
        # "${pkgs.firefox}/bin/firefox --kiosk --new-instance -P p1 --class firefox-1 http://192.168.100.125:3001/left https://demo.astrautm.com";
        "${pkgs.firefox}/bin/firefox --new-instance -P p1 --class firefox-1 http://192.168.100.125:3001/left https://demo.astrautm.com";
      Restart = "always";
      RestartSec = "5s";
      Environment = [ "DISPLAY=:0" "XDG_RUNTIME_DIR=/run/user/1001" ];
    };
  };

  systemd.services."auto-web-2" = {
    description = "Run Firefox with a specific URL";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "x11";
      ExecStart =
        # "${pkgs.firefox}/bin/firefox --kiosk --new-instance -P p2 --class firefox-2 http://192.168.100.125:3001/right";
        "${pkgs.firefox}/bin/firefox --new-instance -P p2 --class firefox-2 http://192.168.100.125:3001/right";
      Restart = "always";
      RestartSec = "5s";
      Environment = [ "DISPLAY=:0" "XDG_RUNTIME_DIR=/run/user/1001" ];
    };
  };

  systemd.services."precision-landing" = {
    enable = false;
    description = "Run precision landing";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "x11";
      ExecStart = "${pkgs.bash}/bin/bash /home/x11/start_precision_landing.sh";
      Restart = "always";
      RestartSec = "5s";
      Environment = [ "PATH=${pkgs.docker}/bin:${pkgs.xorg.xhost}/bin:$PATH" ];
    };
  };

  services.xserver.windowManager.i3.extraSessionCommands = ''
    # Disable screensaver
    xset s off
    # Disable screen blanking
    xset -dpms
    xset s noblank

    # > xinput list
    xinput map-to-output 10 HDMI-1
    xinput map-to-output 11 HDMI-2
  '';

  systemd.services."thales-sight" = {
    description = "Run Thales App Sight";
    wantedBy = [ "multi-user.target" ];
    after = [ "auto-web-2.service" ];
    serviceConfig = {
      User = "x11";
      ExecStart = "${pkgs.bash}/bin/bash /home/x11/start_sight_app.sh";
      Restart = "always";
      RestartSec = "5s";
      Environment = [
        "DISPLAY=:0"
        "XDG_RUNTIME_DIR=/run/user/1001"
        "PATH=${pkgs.docker}/bin:${pkgs.xorg.xhost}/bin:$PATH"
      ];
    };
  };
}
