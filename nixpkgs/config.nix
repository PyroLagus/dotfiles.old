# ~/.nixpkgs/config.nix

{
  allowUnfree = true;

  packageOverrides = pkgs : with pkgs; rec {
    hsEnv = haskellPackages.ghcWithPackages (p: with p; [
      cabal-install cabal2nix lens text transformers aeson ansi-terminal sqlite-simple system-filepath curl
    ]);
    firefox-nightly = callPackage /home/codehero/.nixpkgs/firefox-nightly {
      gconf = pkgs.gnome.GConf;
      inherit (pkgs.gnome) libgnome libgnomeui;
      inherit (pkgs.xlibs) libX11 libXScrnSaver libXcomposite libXdamage libXext
        libXfixes libXinerama libXrender libXt;
      inherit (pkgs.gst_all_1) gstreamer gst-plugins-bad gst-plugins-base gst-plugins-good gst-plugins-ugly gst-libav;
    };
  };
}
