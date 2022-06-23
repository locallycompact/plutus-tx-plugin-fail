{
  nixConfig.bash-prompt = "[plutus-tx-plugin-fail:] ";
  description = "plutus-tx-plugin-fail";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    haskellNix.url = "github:input-output-hk/haskell.nix";
    lint-utils = {
      url = "git+https://gitlab.homotopic.tech/nix/lint-utils";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, flake-utils, lint-utils, haskellNix }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        deferPluginErrors = true;
        overlays = [
          haskellNix.overlay
          (final: prev: {
            # This overlay adds our project to pkgs
            plutus-tx-plugin-fail =
              final.haskell-nix.project' {
                src = ./.;
                compiler-nix-name = "ghc923";
                projectFileName = "stack.yaml";
                modules = [{
                  packages = { };
                }];
                shell.buildInputs = with pkgs; [
                  cabal-install
                  ghcid
                  haskell-language-server
                  hlint
                  nixpkgs-fmt
                  stylish-haskell
                ];
              };
          })
        ];
        pkgs = import nixpkgs { inherit system overlays; inherit (haskellNix) config; };
        flake = pkgs.plutus-tx-plugin-fail.flake { };
      in
      flake // {
        checks = flake.checks // {
          cabal-fmt = lint-utils.outputs.linters.${system}.cabal-fmt ./.;
          hlint = lint-utils.outputs.linters.${system}.hlint ./.;
          nixpkgs-fmt = lint-utils.outputs.linters.${system}.nixpkgs-fmt ./.;
          stylish-haskell = lint-utils.outputs.linters.${system}.stylish-haskell ./.;
        };
        defaultPackage = flake.packages."plutus-tx-plugin-fail:lib:plutus-tx-plugin-fail";
      });
}
