{
  description = "Lua environment with LuaRocks";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
    in {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          pkgs.lua5_4
          pkgs.lua54Packages.luarocks
        ];
      };

      packages.${system}.luaEnv = pkgs.buildEnv {
        name = "lua-env-with-luarocks";
        paths = [
          pkgs.lua5_4
          pkgs.lua54Packages.luarocks
        ];
      };
    };
}

