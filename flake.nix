{
  description = "homelab tooling";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = [
          pkgs.kubeseal
          pkgs.yq-go
        ];
        shellHook = ''
          export PATH="$(git rev-parse --show-toplevel)/scripts:$PATH"
        '';
      };
    };
}
