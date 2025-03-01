# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let
  # XXX: Using unpinned builtins.fetchTarball will only cache the download for
  #      1 hour by default, so one needs internet access almost every time the
  #      system is rebuilt.
  home-manager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/release-24.11.tar.gz";
    # XXX: get new tarball hash via `nix-prefetch-url --unpack <URL_TO_TARBALL>`
    sha256 = "0c07xj74vsj37d3a8f98i9rhhhr99ckwlp45n40f0qkmigm3pk8s"; # 2025-02-27
  };

  username = "feni";
in
  {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      (import "${home-manager}/nixos")
    ];

  # blacklist internal microphone
  boot.blacklistedKernelModules = [ "snd_soc_dmic" ];

  # We deal with an LUKS encrypted partition
  boot.initrd.luks.devices = {
    root = {
      device = "/dev/nvme0n1p2";
      preLVM = true;
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable the Flakes feature and the accompanying new nix command-line tool
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  systemd.services.disable-sound-leds = rec {
    # $ man 7 systemd.special:
    # [...]
    # This target is started automatically as soon as a sound card is plugged in or becomes available at boot.
    wantedBy = [ "sound.target" ];
    after = wantedBy;
    serviceConfig.Type = "oneshot";
    script = ''
      echo off > /sys/class/sound/ctl-led/mic/mode
      echo off > /sys/class/sound/ctl-led/speaker/mode # follow-route pending https://discourse.nixos.org/t/20480
      '';
  };

  systemd.services.reenable-connected-internal-display = {
    description = "Re-enabling a disabled internal display if needed.";
    wantedBy = [ "post-resume.target" ];
    after = [ "post-resume.target" ];
    environment = {
      DISPLAY = ":0";
      XAUTHORITY = "/home/${username}/.Xauthority";
    };
    script = ''#!/usr/bin/env bash
    set -eu

    XRANDR="${pkgs.xorg.xrandr}/bin/xrandr"
    WC="${pkgs.coreutils}/bin/wc"
    GREP="${pkgs.gnugrep}/bin/grep"
    ECHO="${pkgs.coreutils-full}/bin/echo"

    CONNECTED_DISPLAYS=$("$XRANDR" --query | "$GREP" -w connected | "$WC" -l)
    "$ECHO" "amount of connected displays: $CONNECTED_DISPLAYS"

    if [[ "$CONNECTED_DISPLAYS" -eq 1 ]]; then
    # only one display is connected, on a notebook this should be the internal one.
    # `xrandr --auto` re-enables it, preventing a disabled black screen on resume.
    "$XRANDR" --auto --verbose
    fi
    '';
    serviceConfig.Type = "oneshot";
  };

  networking.hostName = "nixtop";
  networking.networkmanager.enable = true; # XOR wpa_supplicant via networking.wireless.enable = true;

  time.timeZone = "Europe/Berlin";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  services.openssh.enable = true;

  services.xserver = {
    enable = true;
    enableTearFree = true;
    videoDrivers = [ "amdgpu" ];
    windowManager.i3.enable = true;
  };

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.variant = "altgr-intl";
  services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # detect network printers supporting IPP Everywhere (UDP 5353)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Enable sound.
  #hardware.pulseaudio.enable = true;
  # OR
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  services.logind = {
    #lidSwitchDocked = "suspend";
    lidSwitch = "ignore";
    powerKey = "suspend";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."${username}" = {
    createHome = true;
    extraGroups = [ "wheel" "video" "audio" "disk" "networkmanager" ];
    group = "users";
    home = "/home/${username}";
    isNormalUser = true;
    uid = 1000;
    shell = pkgs.zsh;
  };

  fonts.packages = with pkgs; [
    font-awesome
    dejavu_fonts
    powerline-fonts
    powerline-symbols
  ];

  environment.variables = {
    "TERMINAL" = "kitty"; # needed for i3-sensible-terminal
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # XXX: kept in systemPackages as these packages are used within systemd.services scripts
  environment.systemPackages = with pkgs; [
    gnugrep
    xorg.xrandr
    coreutils-full

    (callPackage ./scripts/clip/derivation.nix {}) # depends on: xclip, imagemagick
  ];

  programs.zsh.enable = true;

  # FIXME: install via home manager led to
  # $ pass foobar
  #  gpg: public key decryption failed: No pinentry
  #  gpg: decryption failed: No pinentry
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # XXX: Using the global nixpkgs instance saves an extra Nixpkgs evaluation,
  #      adds consistency, and removes the dependency on NIX_PATH, which is
  #      otherwise used for importing Nixpkgs.
  home-manager.useGlobalPkgs = true;
  home-manager.users."${username}" = { pkgs, ... }: {
    home.packages = with pkgs; [
      amdgpu_top
      arandr
      brightnessctl
      dmidecode
      dunst # dbus notification daemon (needed for mictray)
      eog
      evince
      file
      firefox
      fzf
      htop
      imagemagick # scripts/clip
      killall
      libinput
      lshw
      mictray
      mpv
      ncdu
      networkmanagerapplet
      nload
      pass
      pasystray
      pavucontrol
      pcmanfm
      pulseaudio # pactl in i3wm's config
      ripgrep
      ripgrep-all # rga, rga-fzf
      rofi
      tig
      thunderbird
      unzip
      wget
      which
      xclip
      xcwd # i3/config (kitty)
      xss-lock
      yt-dlp
      zip
    ];
    programs = {
      i3status-rust = {
        enable = true;
        bars = {
          default = {
            blocks = [
              {
                block = "disk_space";
                path = "/";
                info_type = "available";
                interval = 10;
                warning = 20.0;
                alert = 10.0;
              }
              {
                block = "memory";
                format = " $icon $mem_total_used_percents.eng(w:2) ";
                format_alt = " $icon_swap $swap_used_percents.eng(w:2) ";
              }
              {
                block = "cpu";
                info_cpu = 20;
                warning_cpu = 50;
                critical_cpu = 90;
              }
              {
                block = "sound";
                click = [
                  {
                    button = "left";
                    cmd = "pavucontrol";
                  }
                ];
              }
              {
                block = "battery";
                format = " $icon $percentage ";
                full_format = " 🔋 $percentage ";
                charging_format = " 🔌 $percentage ";
                empty_format = " 🪫 $percentage ";
                driver = "sysfs";
                device = "BAT0";
              }
              {
                block = "time";
                interval = 60;
                format = " $timestamp.datetime(f:'%a %d/%m %R') ";
              }
            ];
            settings = {
              theme =  {
                theme = "solarized-dark";
                overrides = {
                  idle_bg = "#123456";
                  idle_fg = "#abcdef";
                };
              };
            };
            icons = "awesome6";
            theme = "gruvbox-dark";
          };
        };
      };
      zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        history.size = 20000;
        shellAliases = {
          ll = "ls -l";
          la = "ls -la";
          tig = "TIG_SCRIPT=<(echo :toggle id) tig";
        };
        oh-my-zsh = {
          enable = true;
          theme = "ys";
          plugins = [
            "git"
            "fzf"
          ];
        };
      };
      git = {
        enable = true;
        includes = [ { path = builtins.toString ./. + "/../gitconfig"; } ];
      };
      kitty = {
        enable = true;
        font = {
          name = "Font Awesome 6 Free Regular";
          size = 12;
        };
        settings = {
          enable_audio_bell = false;
          copy_on_select = "clipboard";
        };
      };
      neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;
        plugins = with pkgs; [
          vimPlugins.nvim-treesitter.withAllGrammars
          vimPlugins.barbar-nvim
          vimPlugins.fzf-vim
          vimPlugins.vim-signify
          vimPlugins.vim-fugitive
        ];
        #extraWrapperArgs = [
        #  "--prefix"
        #  "PATH"
        #  ":"
        #  "${lib.makeBinPath [ pkgs.gcc pkgs.go ]}"
        #];
        extraPackages = with pkgs; [
          # tools needed for TreeSitter
          go
          gcc
          # tools needed for fzf-vim
          #fzf
          #gopls
        ];
        extraConfig = builtins.readFile ../neovim/init.vim;
      };
      tmux = {
        enable = true;
        baseIndex = 1;
        clock24 = true;
        keyMode = "vi";
        historyLimit = 1000;
      };
    };

    # compare generated ~/.config/i3/config with `git show $(git rev-list --max-count=1 --all -- i3/config)^:i3/config)`
    xsession.windowManager.i3 = {
      enable = true;
      config = rec {
        modifier = "Mod4";
        keybindings = lib.mkOptionDefault {
          "XF86AudioMicMute" = "exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle";
          "XF86AudioMute" = "exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle";
          "XF86AudioLowerVolume" = "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -10%";
          "XF86AudioRaiseVolume" = "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +10%";
          "XF86MonBrightnessDown" = "exec --no-startup-id brightnessctl set 5%-";
          "XF86MonBrightnessUp" = "exec --no-startup-id brightnessctl set +5%";
          "${modifier}+Return" = ''exec "${pkgs.kitty}/bin/kitty --directory $(${pkgs.xcwd}/bin/xcwd)"'';
          "${modifier}+Shift+c" = "kill";
          "${modifier}+p" = ''exec --no-startup-id "${pkgs.rofi}/bin/rofi -modi drun,run,combi -show combi -show-icons"'';
          "${modifier}+Tab" = "workspace back_and_forth";
          "${modifier}+Shift+Tab" = "move container to workspace back_and_forth";
          "${modifier}+Shift+e" = "mode $exitwarning";
        };
        startup = [
          {
            # xss-lock grabs a logind suspend inhibit lock and will use i3lock to lock the
            # screen before suspend. Use loginctl lock-session to lock your screen.
            command = "${pkgs.xss-lock}/bin/xss-lock --transfer-sleep-lock -- i3lock --nofork -c e3da92";
            always = true;
            notification = false;
          }
          {
            command = "${pkgs.networkmanagerapplet}/bin/nm-applet";
            always = true;
            notification = false;
          }
          {
            # Startup pulseaudio controller for the system tray.
            command = "${pkgs.killall}/bin/killall --regexp pasystray ; ${pkgs.pasystray}/bin/pasystray";
            always = true;
            notification = false;
          }
          {
            # Startup dunst as a dbus notification daemon to handle dbus events (e.g. needed by mictray)
            command = "${pkgs.dunst}/bin/dunst";
            always = true;
            notification = false;
          }
          {
            command = "${pkgs.mictray}/bin/mictray";
            always = true;
            notification = false;
          }
          # Start XDG autostart .desktop files using dex. See also
          # https://wiki.archlinux.org/index.php/XDG_Autostart
          #exec --no-startup-id dex --autostart --environment i3
        ];
        fonts = {
          names = [ "DejaVu Sans Mono for Powerline" "Font Awesome 6 Free Regular"];
          size = 12.0;
        };
        bars = [
          {
            fonts = {
              names = [ "DejaVu Sans Mono for Powerline" "Font Awesome 6 Free Regular"];
              size = 12.0;
            };
            position = "top";
            statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs config-default";
          }
        ];
      };
      extraConfig = ''
        set $exitwarning "(E)xit Session 😴(S)leep ⏻(P)oweroff ⟳(R)eboot 🔒(L)ock"
        mode $exitwarning {
          bindsym e exec i3-msg exit; mode "default"
          bindsym s exec systemctl suspend; mode "default"
          bindsym l exec i3lock -c e3da92; mode "default"
          bindsym p exec systemctl poweroff; mode "default"
          bindsym r exec systemctl reboot; mode "default"
          bindsym Escape mode "default"
          bindsym Return mode "default"
        }

        # activate "back and forth" (when i.e. on workspace '4' just hit $mod+4 get to previous one)
        workspace_auto_back_and_forth yes

        # disable titlebar of windows, add thick borders
        default_border pixel
        new_window pixel 4
        new_float pixel 4

        # --------------------
        # layout colors
        # --------------------
        set $BLACK     #000000
        set $WHITE     #FFFFFF
        set $GRAY      #888888
        # --------------------
        set $PINK      #EF476F
        set $ORNGE     #EFCC00
        set $GREEN     #06D6A0
        set $BLUE      #118AB2
        set $BLUEDK    #073B4C
        # --------------------

        #                       bord    bg      text    indicator (split)
        client.focused          $BLUEDK $ORNGE  $BLACK  $GREEN
        client.focused_inactive $BLUEDK $GRAY   $BLACK  $BLUEDK
        client.unfocused        $BLUEDK $GRAY   $BLACK  $BLUEDK
        client.urgent           $BLUEDK $PINK   $BLACK  $BLUEDK
      '';
    };

    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "24.11";
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

  # For more information, see `man configuration.nix`
  system.stateVersion = "24.11";
}
