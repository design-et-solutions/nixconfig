{ pkgs, ... }: {
  imports = [
    ./firefox.nix # -> Browser
    ./ghostty.nix # -> Terminal emulator
  ];

  home.packages = with pkgs; [
    handlr-regex # ---> Manage your default applications
    pulseaudio # ---> Sound server for POSIX and Win32 systems -- WIP
  ];

  xsession.enable = true;

  xsession.windowManager.i3 = {
    enable = true;
    extraConfig = ''
      # Disable the i3 bar
      bar {
        mode hide
      }

      # Define workspaces
      workspace 1 output HDMI1
      workspace 2 output HDMI2

      # Assign Firefox instances to specific workspaces
      assign [class="firefox-1"] 1
      assign [class="firefox-2"] 2
      assign [class="SightCohoma"] 1

      # Set Firefox instances to fullscreen on startup
      for_window [class="firefox-1"] fullscreen enable
      for_window [class="SightCohoma"] fullscreen enable
      for_window [class="firefox-2"] fullscreen enable

      bindsym Tab focus left; fullscreen disable; focus left; fullscreen enable 
      bindsym Shift+Tab focus right; fullscreen disable; focus right; fullscreen enable
    '';
    config.startup = [
      {
        command =
          "xrandr --output HDMI1 --primary --auto --output HDMI2 --right-of HDMI1 --auto";
        always = true;
      }
      {
        command = "/home/x11/map_touchscreens.sh";
        always = true;
      }
      {
        command = "unclutter --timeout 0 --jitter 0 --hide-on-touch";
        always = true;
      }
      {
        command = "touchegg";
        always = true;
      }
      {
        command = "picom --backend xrender";
        always = true;
      }
    ];
  };

  home.file."toggle_sight.sh" = {
    text = ''
      export DISPLAY=:0
      #!/bin/sh

      xdotool key Tab
    '';
    executable = true;
  };

  home.file.".config/touchegg/touchegg.conf".text = ''
    <touchégg>
      <settings>
        <property name="composed_gestures_time">200</property>
      </settings>
      <application name="All">
        <gesture type="PINCH" fingers="2" direction="IN">
          <action type="RUN_COMMAND">
            <repeat>true</repeat>
            <command>xdotool click 4</command>
            <decreaseCommand>xdotool click 5</decreaseCommand>
          </action>
        </gesture>
         
        <gesture type="PINCH" fingers="2" direction="OUT">
          <action type="RUN_COMMAND">
            <repeat>true</repeat>
            <command>xdotool click 5</command>
            <decreaseCommand>xdotool click 4</decreaseCommand>
          </action>
        </gesture>

        <gesture type="TAP" fingers="1" direction="">
          <action type="MOUSE_CLICK">BUTTON=1</action>
        </gesture>
      </application>

      <application name="firefox-1">
        <gesture type="SWIPE" fingers="3" direction="RIGHT">
          <action type="RUN_COMMAND">
            <command>xdotool key Tab</command>
          </action>
        </gesture>
        <gesture type="SWIPE" fingers="3" direction="LEFT">
          <action type="RUN_COMMAND">
            <command>xdotool key Tab</command>
          </action>
        </gesture>
      </application>

      <application name="SightCohoma">
        <gesture type="SWIPE" fingers="3" direction="RIGHT">
          <action type="RUN_COMMAND">
            <command>xdotool key Tab</command>
          </action>
        </gesture>
        <gesture type="SWIPE" fingers="3" direction="LEFT">
          <action type="RUN_COMMAND">
            <command>xdotool key Tab</command>
          </action>
        </gesture>
      </application>
    </touchégg>
  '';
  # <gesture type="PINCH" fingers="2" direction="IN">
  #   <action type="RUN_COMMAND">
  #     <repeat>true</repeat>
  #     <command>xdotool click 4</command>
  #     <decreaseCommand>xdotool click 5</decreaseCommand>
  #   </action>
  # </gesture>

  # <gesture type="PINCH" fingers="2" direction="OUT">
  #   <action type="RUN_COMMAND">
  #     <repeat>true</repeat>
  #     <command>xdotool click 5</command>
  #     <decreaseCommand>xdotool click 4</decreaseCommand>
  #   </action>
  # </gesture>

  home.file."start_precision_landing.sh" = {
    text = ''
      xhost +local:docker

      docker stop parrot-anafi-olympe
      docker container rm parrot-anafi-olympe
      docker run --rm -p 8000:8000 --net=host parrot-anafi-olympe
    '';
    executable = true;
  };

  home.file."start_sight_app.sh" = {
    text = ''
      export DISPLAY=:0
      xhost +local:docker

      docker stop sight-container
      docker container rm sight-container
      docker run \
        --network host \
        -e DISPLAY=$DISPLAY \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        --device /dev/dri:/dev/dri \
        --name sight-container sight-image
    '';
    executable = true;
  };

  home.file."change_tabs.sh" = {
    text = ''
      export DISPLAY=:0
      #!/bin/sh

      # Check if an argument is provided
      if [ -z "$1" ]; then
        echo "Usage: $0 <next|previous|number>"
        exit 1
      fi

      ACTION=$1

      # Get the window ID of the Firefox instance
      WINDOW_ID=$(wmctrl -lx | grep 'firefox-1' | awk '{print $1}')

      # Activate the window
      wmctrl -ia $WINDOW_ID

      # Perform the action based on the argument
      case $ACTION in
        next)
          # Switch to the next tab (Ctrl+Tab)
          xdotool key --window $WINDOW_ID Control+Tab
          ;;
        previous)
          # Switch to the previous tab (Ctrl+Shift+Tab)
          xdotool key --window $WINDOW_ID Control+Shift+Tab
          ;;
        *)
          # Switch to the next tab (Ctrl+number)
          xdotool key --window $WINDOW_ID Control+$ACTION
          ;;
      esac
    '';
    executable = true;
  };

  home.file."map_touchscreens.sh" = {
    source = ./map_touchscreens.sh;
    executable = true;
  };
}
