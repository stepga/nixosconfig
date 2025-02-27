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
      htop
      i3status-rust
      imagemagick # scripts/clip
      libinput
      lshw
      mictray
      mpv
      networkmanagerapplet
      pass
      pasystray
      pavucontrol
      pcmanfm
      pulseaudio # pactl in i3wm's config
      rofi
      tig
      tmux
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
      bash = {
        enable = true;
      };
      git = {
        enable = true;
        includes = [ { path = builtins.toString ./. + "/../gitconfig"; } ];
      };
      kitty = {
        enable = true;
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
      };
    };

    services = {
      gpg-agent = {
        enable = true;
        enableSshSupport = true;
      };
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
