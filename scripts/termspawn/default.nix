# build locally via `nix-build` (uses default.nix), resulting in `result` symlink
{ pkgs ? import <nixpkgs> {} }:
pkgs.callPackage ./derivation.nix {}
