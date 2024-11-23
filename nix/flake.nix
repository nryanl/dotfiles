{
  description = "First Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nix-homebrew,
    }:
    let
      configuration =
        { pkgs, config, ... }:
        {

          # Allow packages with unfree licenses to be installed
          nixpkgs.config.allowUnfree = true;

          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = [
            pkgs.obsidian
            pkgs.spotify
            pkgs.pyenv
            pkgs.discord
            pkgs.vscode
            pkgs.postman

            #rust related
            pkgs.rustup
            pkgs.sqlx-cli

            pkgs.vscode-extensions.github.copilot

            #terminal related
            pkgs.alacritty
            pkgs.oh-my-zsh
            pkgs.tmux
            pkgs.neovim
            pkgs.mkalias
            pkgs.fzf
            pkgs.ripgrep
            pkgs.gh
            pkgs.vimPlugins.vim-plug
            pkgs.nixfmt-rfc-style

            pkgs.jekyll
            pkgs.ruby

          ];

          homebrew = {
            enable = true;
            brews = [
              "mas"
              "x86_64-linux-gnu-binutils"
            ];
            casks = [
              "vmware-fusion"
              "vagrant-vmware-utility"
              "anydesk"
              "firefox"
              "zed"
              "1password"
              "1password-cli"
              "pgadmin4"
              "vagrant"
            ];
            masApps = {
              "Yoink" = 457622435;
              # Xcode = 497799835;
            };
            onActivation.cleanup = "zap";
            onActivation.autoUpdate = true;
            onActivation.upgrade = true;
          };

          fonts.packages = [
            (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
          ];

          system.activationScripts.applications.text =
            let
              env = pkgs.buildEnv {
                name = "system-applications";
                paths = config.environment.systemPackages;
                pathsToLink = "/Applications";
              };
            in
            pkgs.lib.mkForce ''
              	# Set up applications.
              	echo "setting up /Applications..." >&2
              	rm -rf /Applications/Nix\ Apps
              	mkdir -p /Applications/Nix\ Apps
              	find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
              	while read src; do
                	  app_name=$(basename "$src")
                	  echo "copying $src" >&2
                	  ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
              	done
            '';

          networking = {
            computerName = "grwhite";
            hostName = "grwhite";
          };
          time.timeZone = "America/New_York";
          system.keyboard = {
            enableKeyMapping = true;
            remapCapsLockToControl = true;
          };
          system.defaults = {
            dock = {
              orientation = "left";
              autohide = true;
              show-recents = false;
              persistent-apps = [
                "/Applications/Firefox.app"
                "/Applications/1Password.app"
                "${pkgs.alacritty}/Applications/Alacritty.app"
                "${pkgs.vscode}/Applications/Visual Studio Code.app"
                "${pkgs.obsidian}/Applications/Obsidian.app"
                "${pkgs.discord}/Applications/Discord.app"
                "${pkgs.spotify}/Applications/Spotify.app"
                "/System/Applications/Mail.app"
                "/System/Applications/Calendar.app"
              ];
              wvous-tr-corner = 14; # Quick note in top right corner
              expose-animation-duration = 0.5;
              autohide-time-modifier = 0.5;
            };

            universalaccess = {
              reduceMotion = true;
            };

            alf = {
              globalstate = 1; # 1 enabled - 0 disabled - 2 blocks all connections except essential services
              loggingenabled = 1; # 1 enabled - 0 disabled
              stealthenabled = 1; # 1 enabled - 0 disabled
            };
            # Sets finder view to column by default
            finder = {
              FXPreferredViewStyle = "clmv";
            };
            loginwindow = {
              GuestEnabled = false;
            };
            NSGlobalDomain = {
              NSWindowShouldDragOnGesture = true;
              AppleICUForce24HourTime = true;
              AppleInterfaceStyle = "Dark";
              "com.apple.mouse.tapBehavior" = 1;
            };
            trackpad = {
              Clicking = true;
            };
          };

          system.startup = {
            chime = false;
          };

          # Auto upgrade nix package and the daemon service.
          services.nix-daemon.enable = true;
          # nix.package = pkgs.nix;

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Create /etc/zshrc that loads the nix-darwin environment.
          programs.zsh.enable = true; # default shell on catalina
          # programs.fish.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 5;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#simple
      darwinConfigurations."macbook" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              #Apple Silicon Only
              enableRosetta = true;
              # User owning the Homebrew prefix
              user = "nryanl";
            };
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."simple".pkgs;
    };
}
