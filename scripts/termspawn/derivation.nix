{ pkgs ? import <nixpkgs> { } }:

pkgs.writeShellApplication {
  name = "termspawn";
  runtimeInputs = with pkgs; [
    gnugrep
    kitty
    pstree
    xdotool
  ];
  text = builtins.readFile ./termspawn.sh;
}
