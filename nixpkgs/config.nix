# ~/.nixpkgs/config.nix

{
  packageOverrides = super: let self = super.pkgs; in
  {
    hsEnv = self.haskellngPackages.ghcWithPackages (p: with p; [
      cabal-install cabal2nix lens text transformers aeson ansi-terminal sqlite-simple system-filepath curl
    ]);
  };
}
