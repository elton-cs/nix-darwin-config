{
  description = "zkelton's macbook system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
    let
      configuration = { pkgs, config, ... }: {
        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget

        nixpkgs.config.allowUnfree = true;
        environment.systemPackages = with pkgs;
          [
            vim
            git
            neovim
            nixpkgs-fmt
            protobuf
            rectangle
            discord
            gimp
            lunarvim

            # programming languages
            rustup
            go

            # web dev stuff
            # nodejs_20
            # pnpm
            # corepack_20

            # needed for bevy
            openssl
            pkg-config
            trunk

            # (vscode-with-extensions.override {
            #   vscodeExtensions = with vscode-extensions; [
            #     bbenoist.nix
            #     rust-lang.rust-analyzer
            #     esbenp.prettier-vscode
            #     github.github-vscode-theme
            #   ];
            # })
          ];

        homebrew = {
          enable = true;
          casks = [
            "the-unarchiver"
            "brave-browser"
            "appcleaner"
            "cursor"
            "zed"
            "warp"
            "parsec"
            "telegram"
            "figma"
          ];
        };

        system.defaults = {
          dock.autohide = true;
          dock.show-recents = false;
          dock.tilesize = 48;
          dock.persistent-apps = [
            "/Applications/Brave Browser.app"
            "/Applications/Cursor.app"
            "/Applications/Zed.app"
            "/Applications/Warp.app"
            "/System/Applications/Utilities/Terminal.app"
            "/Applications/AppCleaner.app"
            "/System/Applications/System Settings.app"
            "/System/Applications/Calendar.app"
          ];
        };

        fonts.packages = [
          (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
        ];

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
      darwinConfigurations."simple" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              # Install Homebrew under the default prefix
              enable = true;

              # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
              enableRosetta = true;

              # User owning the Homebrew prefix
              user = "zkelton";
            };
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."simple".pkgs;
    };
}
