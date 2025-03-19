{ pkgs ? import <nixpkgs> { } }:

pkgs.writeShellApplication {
  name = "termspawn";
  runtimeInputs = with pkgs; [
    coreutils # nohup, cut, ...
    kitty
    xorg.xprop
    gawk # awk
  ];
  text = builtins.readFile ./termspawn.sh;
}
