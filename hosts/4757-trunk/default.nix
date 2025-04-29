{ modulesPath, inputs, pkgs, ... }:
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

    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFD6+Ufbd/7QLj5hsAEP7N80gVgaLVsSl+R6m2MhggeV yc@enma"
  ];
  users.users.x11.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFD6+Ufbd/7QLj5hsAEP7N80gVgaLVsSl+R6m2MhggeV yc@enma"
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
      allowedUDPPorts = [ 51200 52200 ];
    };
  };

  # services.xserver.displayManager.gdm = { banner = "Welcome home"; };

  virtualisation.docker.enable = true;

  # services.touchegg.enable = true;

  environment.systemPackages = with pkgs; [
    libinput
    unclutter-xfixes
    wmctrl

    xdotool
    nginx
    ffmpeg

    # Gstreamer
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    gst_all_1.gst-vaapi

    # QT
    qt5.qtbase
    qt5.qttools
    qt5.qtwayland

    # Debug
    tcpdump

    # Misc
    fontconfig
    freetype

    mesa
    libva
    libvdpau
    intel-media-driver
  ];

  # environment.sessionVariables = {
  #   GST_PLUGIN_SYSTEM_PATH_1_0 =
  #     "${pkgs.gst_all_1.gst-plugins-base}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-plugins-good}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-plugins-bad}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-plugins-ugly}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-libav}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-vaapi}/lib/gstreamer-1.0";
  # };

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

  services.xserver.videoDrivers = [ "intel" ];

  systemd.services."rtsp-to-hls-simu" = {
    description = "Middleware RTSP to HLS (Simu)";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /var/www/html/hls/simu";
      ExecStart =
        "${pkgs.ffmpeg}/bin/ffmpeg -fflags nobuffer -flags low_delay -strict experimental -i rtsp://192.168.100.134:8554/vivatech-simu -c:v libx264 -preset ultrafast -tune zerolatency -g 30 -sc_threshold 0 -start_number 0 -f hls -hls_time 2 -hls_list_size 10 -hls_flags delete_segments+append_list+omit_endlist /var/www/html/hls/simu/stream.m3u8";
      Restart = "always";
      RestartSec = "5s";
    };
  };

  systemd.services."rtsp-to-hls-real" = {
    description = "Middleware RTSP to HLS (Real)";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /var/www/html/hls/real";
      ExecStart =
        "${pkgs.ffmpeg}/bin/ffmpeg -fflags nobuffer -flags low_delay -strict experimental -i rtsp://192.168.100.134:8554/vivatech-real -c:v libx264 -preset ultrafast -tune zerolatency -g 30 -sc_threshold 0 -start_number 0 -f hls -hls_time 2 -hls_list_size 10 -hls_flags delete_segments+append_list+omit_endlist /var/www/html/hls/real/stream.m3u8";
      # ExecStart = ''
      #   ${pkgs.gst_all_1.gstreamer}/bin/gst-launch-1.0 -v 
      #         udpsrc multicast-group=239.100.51.20 auto-multicast=true port=51200 caps='application/x-rtp, media=video, encoding-name=H264, payload=96' 
      #         ! rtpjitterbuffer ! rtph264depay ! h264parse ! mpegtsmux 
      #         ! hlssink2 location=/var/www/html/hls/real/segment_%05d.ts playlist-location=/var/www/html/hls/real/stream.m3u8 target-duration=2 max-files=10'';
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
  # services.nginx = {
  #   enable = true;
  #   virtualHosts."localhost" = {
  #     locations."/" = {
  #       root = "/var/www/html";
  #       index = "index.html";
  #     };

  #     locations."/hls/" = {
  #       root = "/var/www/html";
  #       extraConfig = ''
  #         add_header Cache-Control no-cache;
  #         add_header Access-Control-Allow-Origin *;
  #         add_header Access-Control-Allow-Methods 'GET, OPTIONS';
  #         add_header Access-Control-Allow-Headers 'Range';
  #         types {
  #           application/vnd.apple.mpegurl m3u8;
  #           video/mp2t ts;
  #         }
  #         # CORS preflight support
  #         if ($request_method = 'OPTIONS') {
  #           add_header Content-Length 0;
  #           add_header Content-Type text/plain;
  #           return 204;
  #         }
  #       '';
  #     };
  #   };
  # };

  # systemd.services."auto-web-1" = {
  #   description = "Run Firefox with a specific URL";
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     User = "x11";
  #     ExecStart =
  #       # "${pkgs.firefox}/bin/firefox --kiosk --new-instance -P p1 --class firefox-1 http://192.168.100.125:3001/left https://demo.astrautm.com";
  #       "${pkgs.firefox}/bin/firefox --new-instance -P p1 --class firefox-1 http://192.168.100.125:3001/left https://demo.astrautm.com";
  #     Restart = "always";
  #     RestartSec = "5s";
  #     Environment = [ "DISPLAY=:0" "XDG_RUNTIME_DIR=/run/user/1001" ];
  #   };
  # };

  systemd.services."auto-web-2" = {
    description = "Run Firefox with a specific URL";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "x11";
      ExecStart =
        # "${pkgs.firefox}/bin/firefox --kiosk --new-instance -P p2 --class firefox-2 http://192.168.100.125:3001/right";
        "${pkgs.firefox}/bin/firefox  --kiosk --new-instance -P p2 --class firefox-2 http://192.168.100.125:3001/right";
      Restart = "always";
      RestartSec = "5s";
      Environment = [ "DISPLAY=:0" "XDG_RUNTIME_DIR=/run/user/1001" ];
    };
  };

  systemd.services."precision-landing" = {
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
  '';

  # systemd.services."thales-sight" = {
  #   description = "Run Thales App Sight";
  #   wantedBy = [ "multi-user.target" ];
  #   # after = [ "auto-web-2.service" ];
  #   serviceConfig = {
  #     User = "x11";
  #     ExecStart = "${pkgs.bash}/bin/bash /home/x11/start_sight_app.sh";
  #     Restart = "always";
  #     RestartSec = "5s";
  #     Environment = [
  #       "DISPLAY=:0"
  #       "XDG_RUNTIME_DIR=/run/user/1001"
  #       "PATH=${pkgs.docker}/bin:${pkgs.xorg.xhost}/bin:$PATH"
  #     ];
  #   };
  # };
}
