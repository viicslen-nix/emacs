{
  description = "Nix-configured Emacs (evil + eglot), mirroring the NixVim setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Provides `emacsWithPackagesFromUsePackage`: every `:ensure t` in the
    # elisp config below is resolved to a Nix-built elisp package.
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        ./apps.nix
      ];

      systems = ["x86_64-linux" "aarch64-linux"];

      perSystem = {system, ...}: let
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [inputs.emacs-overlay.overlays.default];
        };

        inherit (pkgs) lib;

        # CLI tools Emacs shells out to — eglot servers, formatters, search.
        # Mirrors nixvim's `lsp.servers` + `extraPackages`.
        tools = with pkgs; [
          # Language servers
          nil # nix
          typescript-language-server
          vue-language-server
          pyright
          gopls
          lua-language-server
          bash-language-server
          vscode-langservers-extracted # html, css, json, eslint
          tailwindcss-language-server
          terraform-ls
          marksman
          sqls
          clang-tools # clangd
          zls
          phpactor

          # Formatters (apheleia)
          alejandra
          prettier
          stylua

          # Search / VCS
          ripgrep
          fd
          git
        ];

        emacs = pkgs.emacsWithPackagesFromUsePackage {
          package = pkgs.emacs-pgtk;
          # Both files are scraped for `:ensure t` and written as the init file.
          config = lib.concatMapStringsSep "\n" builtins.readFile [
            ./config/init.el
            ./config/keybinds.el
          ];
          defaultInitFile = true;
          alwaysEnsure = false;
          extraEmacsPackages = epkgs: [
            epkgs.treesit-grammars.with-all-grammars
          ];
        };
      in {
        packages.default = pkgs.symlinkJoin {
          name = "emacs-configured";
          paths = [emacs];
          nativeBuildInputs = [pkgs.makeWrapper];
          postBuild = ''
            for bin in emacs emacsclient; do
              wrapProgram $out/bin/$bin \
                --suffix PATH : ${lib.makeBinPath tools}
            done
          '';
          meta.mainProgram = "emacs";
        };

        formatter = pkgs.alejandra;

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nix-output-monitor
            alejandra
          ];
          shellHook = ''
            echo "Emacs development shell"
            echo "Use 'nom build' or 'nix run .' to try the configuration"
          '';
        };
      };
    };
}
