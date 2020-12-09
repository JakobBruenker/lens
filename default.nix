{ pkgs ? import <nixpkgs> {}, compilerVersion ? "ghc8101" }:
let
  haskellPackages = pkgs.haskell.packages."${compilerVersion}".override {
    overrides = self: super: {
      # test fails
      time-compat = pkgs.haskell.lib.dontCheck super.time-compat;
      # test requires QuickCheck < 2.14
      psqueues = pkgs.haskell.lib.dontCheck super.psqueues;
      # test requires QuickCheck < 2.14
      vector = pkgs.haskell.lib.dontCheck super.vector;
      # test requires QuickCheck < 2.14
      attoparsec = pkgs.haskell.lib.dontCheck super.attoparsec;
      # test requires QuickCheck < 2.14
      cassava = pkgs.haskell.lib.dontCheck super.cassava;
      # getting infinite recursion if I do this in source-overrides
      splitmix = super.splitmix_0_1_0_3;
    };
  };
in
  haskellPackages.developPackage {
    root = ./.;
    source-overrides = {
      strict = "0.4";
      th-abstraction = "0.4.0.0";
      aeson = "1.5.4.1";
      data-fix = "0.3.0";
      quickcheck-instances = "0.3.25";
      QuickCheck = "2.14.1";
    };
  }
