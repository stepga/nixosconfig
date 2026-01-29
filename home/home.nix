{ pkgs, lib, variables, ... }:

{
  home.username = "${variables.username}";
  home.homeDirectory = "/home/${variables.username}";

  home.packages = with pkgs; [
    alsa-utils # aplay
    amdgpu_top
    android-file-transfer
    arandr
    autojump
    bear
    brightnessctl
    ccls
    colordiff
    dmidecode
    dunst # dbus notification daemon (needed for mictray)
    entr # launch and auto-reload on file change: `find ./src/ | entr -r go test src/foo.go`
    eog
    evince
    file
    firefox
    foliate
    fzf
    gimp
    gcc
    gnumake
    gopls
    gparted
    gore
    htop
    imagemagick # scripts/clip
    killall
    libinput
    lshw
    man-pages
    man-pages-posix
    mictray
    mpv
    nautilus
    ncdu
    networkmanagerapplet
    nextcloud-client
    nil
    nixfmt-rfc-style
    nload
    pass
    pasystray
    pavucontrol
    pcmanfm
    pstree
    pulseaudio # pactl in i3wm's config
    ripgrep
    ripgrep-all # rga, rga-fzf
    rofi
    ruby
    signal-desktop
    simple-scan
    thunderbird
    tig
    unrar
    unzip
    wget
    which
    xclip
    xdotool
    xss-lock
    xxd
    yt-dlp
    zip
    nodejs_24
    (pkgs.python312.withPackages (ps: with ps; [
      numpy # these two are
      scipy # probably redundant to pandas
      jupyterlab
      pandas
      statsmodels
      scikit-learn
      matplotlib
      pyqt5
      qtpy
    ]))
  ];

  home.sessionPath = [
    "$HOME/go/bin"
  ];

  programs.i3status-rust = {
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

  programs.zsh = {
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
        "autojump"
        "git"
        "fzf"
      ];
    };
    initContent = lib.mkOrder 1200 ''
      source ~/.functions.sh
    '';
  };

  home.file.".functions.sh".source = ./functions.sh;

  programs.git = {
    enable = true;
    settings = {
      user = {
        email = "${variables.git.user.email}";
        name = "${variables.git.user.name}";
      };
      alias = {
        "a" = "add";
        "cv" = "commit --verbose";
        "co" = "checkout";
        "ca" = "commit -a --verbose";
        "d" = "diff";
        "wd" = "diff --word-diff";
        "lg" = "log --graph --abbrev-commit --decorate --date=format:'%Y-%m-%d %H:%M:%S' --format=format:'%C(bold blue)%h%C(reset) %C(bold green)(%ad)%C(reset) %C(bold)%s%C(reset) | %C(bold red)%an%C(reset)%C(bold cyan)%d%C(reset)'";
        "ri" = "rebase -i";
        "s" = "status";
      };
      core = {
        "editor" = "nvim";
        "lineNumber" = "true";
        "filemode" = "false";
        "autocrlf" = "false";
      };
      grep = {
        "linenumber" = "true";
      };
      push = {
        "default" = "matching";
      };
      advice = {
        "ignoredHook" = "false";
      };
    };
  };

  programs.go = {
    enable = true;
  };

  programs.kitty = {
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

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    plugins = with pkgs; [
      vimPlugins.barbar-nvim
      vimPlugins.fzf-vim
      vimPlugins.which-key-nvim

      # git
      vimPlugins.vim-signify
      vimPlugins.vim-fugitive

      # treesitter: highlighting & indenting; requires gcc
      vimPlugins.nvim-treesitter.withAllGrammars
      # nix ftplugin
      vimPlugins.vim-nix

      # go
      vimPlugins.go-nvim

      # lsp
      vimPlugins.nvim-lspconfig

      # autocompletion plugin
      vimPlugins.nvim-cmp
      vimPlugins.cmp-buffer
      vimPlugins.cmp-path
      vimPlugins.cmp-cmdline
      # LSP source for nvim-cmp
      vimPlugins.cmp-nvim-lsp
      # Snippets source for nvim-cmp
      vimPlugins.cmp_luasnip
      # Snippets plugin vsnip
      vimPlugins.cmp-vsnip
      vimPlugins.vim-vsnip
    ];
    extraConfig = builtins.readFile ./neovim/init.vim;
  };

  programs.tmux = {
    enable = true;
    baseIndex = 1;
    clock24 = true;
    keyMode = "vi";
    historyLimit = 1000;
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
        "${modifier}+Return" = ''exec termspawn'';
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

        ## force floating for all new windows
        #for_window [class="[.]*"] floating enable
    '';
  };

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.11";
}
