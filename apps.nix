# App outputs for the Emacs flake
# This file is imported by flake.nix via flake-parts
{
  perSystem = {config, ...}: {
    apps.default = {
      type = "app";
      program = "${config.packages.default}/bin/emacs";
      meta.description = "Nix-configured Emacs (evil + eglot)";
    };
  };
}
