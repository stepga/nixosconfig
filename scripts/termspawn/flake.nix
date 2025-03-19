{
  # see intro for shell script packaging: https://ertt.ca/nix/shell-scripts/
  description = "A script for starting a new kitty in currently focused kitty's CWD.";
  outputs = { self, nixpkgs }: {
    defaultPackage.x86_64-linux = self.packages.x86_64-linux.termspawn;
    packages.x86_64-linux.termspawn =
      let
        pkgs = import nixpkgs { system = "x86_64-linux"; };
        my-name = "termspawn";
        my-src = builtins.readFile ./termspawn.sh;
        my-script = (pkgs.writeScriptBin my-name my-src).overrideAttrs(old: {
          buildCommand = "${old.buildCommand}\n patchShebangs $out";
        });
        my-buildInputs = with pkgs; [
          coreutils # nohup, cut, ...
          kitty
          xorg.xprop
          gawk # awk
        ];
      in pkgs.symlinkJoin {
        name = my-name;
        paths = [ my-script ] ++ my-buildInputs;
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = "wrapProgram $out/bin/${my-name} --prefix PATH : $out/bin";
      };
  };
}
