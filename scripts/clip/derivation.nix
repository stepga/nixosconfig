{ pkgs ? import <nixpkgs> { } }:

pkgs.writeShellApplication {
  name = "clip";
  runtimeInputs = [ pkgs.xclip pkgs.imagemagick ];
  text = builtins.readFile ./clip.bash;
}
