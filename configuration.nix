{ pkgs, variables, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
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
      XAUTHORITY = "/home/${variables.username}/.Xauthority";
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

  networking.hostName = "${variables.hostname}";
  networking.networkmanager.enable = true; # XOR wpa_supplicant via networking.wireless.enable = true;

  time.timeZone = "Europe/Berlin";

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

  services.upower = {
    enable = true;
    percentageCritical = 3; # default 5
    criticalPowerAction = "Hibernate";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."${variables.username}" = {
    createHome = true;
    extraGroups = [ "wheel" "video" "audio" "disk" "networkmanager" ];
    group = "users";
    home = "/home/${variables.username}";
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
    (callPackage ./scripts/termspawn/derivation.nix {})

    fritzing
    musescore
  ];

  documentation.dev.enable = true;

  programs.zsh.enable = true;

  # needed for packages like `unrar`
  nixpkgs.config.allowUnfree = true;

  # FIXME: install via home manager led to
  # $ pass foobar
  #  gpg: public key decryption failed: No pinentry
  #  gpg: decryption failed: No pinentry
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # enable pam support for i3lock; https://github.com/NixOS/nixpkgs/issues/401891
  security.pam.services.i3lock.enable = true;

  # For more information, see `man configuration.nix`
  system.stateVersion = "24.11";
}
