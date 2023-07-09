{
  nixConfig.bash-prompt-prefix = "\[naersk-opencv-rs\]$ ";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    naersk.url = "github:nix-community/naersk";

    nixpkgs-mozilla = {
      url = "github:mozilla/nixpkgs-mozilla";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-mozilla,
    naersk,
    ...
  }: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";

      overlays = [
        (import nixpkgs-mozilla)
      ];
    };

    toolchain = (pkgs.rustChannelOf {
      rustToolchain = ./rust-toolchain.toml;
      sha256 = "sha256-Zk2rxv6vwKFkTTidgjPm6gDsseVmmljVt201H7zuDkk=";
    }).rust;


    naersk' = pkgs.callPackage naersk {
      cargo = toolchain;
      rustc = toolchain;
    };

    deps = with pkgs; [ pkg-config toolchain cmake opencv clang llvmPackages.libclang llvmPackages.libclang.dev libclang libclang.lib ];
    dev-deps = deps ++ [ ];

  in {
    packages.x86_64-linux.default = naersk'.buildPackage {
      src = ./.;
      buildInputs = deps;
      LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
    };

    devShells.x86_64-linux.default = pkgs.mkShell {
      nativeBuildInputs = dev-deps;
      LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
    };

  };
}
