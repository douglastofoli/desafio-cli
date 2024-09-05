{
  description = "A basic flake to run an Elixir Project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      inherit (pkgs.lib) optional optionals;
      pkgs = import nixpkgs {inherit system;};

      beamPkg = pkgs.beam.packagesWith pkgs.erlang_26;
      elixir = beamPkg.elixir.override {
        version = "1.17.2";
        sha256 = "sha256-8rb2f4CvJzio3QgoxvCv1iz8HooXze0tWUJ4Sc13dxg=";
      };

      inputs = with pkgs;
        [elixir erlang_26 glibcLocales]
        ++ optional stdenv.isLinux [inotify-tools]
        ++ optional stdenv.isDarwin terminal-notifier
        ++ optionals stdenv.isDarwin
        (with darwin.apple_sdk.frameworks; [CoreFoundation CoreServices]);
    in
      with pkgs; {
        devShells.default = mkShell {
          name = "desafio-cli";
          packages = inputs;
        };
      });
}
