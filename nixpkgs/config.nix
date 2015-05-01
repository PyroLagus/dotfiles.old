# ~/.nixpkgs/config.nix

{
  allowUnfree = true;

  packageOverrides = pkgs : with pkgs; rec {
    hsEnv = haskellngPackages.ghcWithPackages (p: with p; [
      cabal-install cabal2nix lens text transformers aeson ansi-terminal sqlite-simple system-filepath curl
    ]);
    firefox-nightly = callPackage ./firefox-nightly {
      gconf = pkgs.gnome.GConf;
      inherit (pkgs.gnome) libgnome libgnomeui;
      inherit (pkgs.xlibs) libX11 libXScrnSaver libXcomposite libXdamage libXext
        libXfixes libXinerama libXrender libXt;
    };
  };
}
