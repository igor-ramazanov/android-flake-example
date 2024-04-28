{
  description = "An example to build Android app using Nix";

  inputs = {
    android.inputs.devshell.follows = "devshell";
    android.inputs.flake-utils.follows = "flake-utils";
    android.inputs.nixpkgs.follows = "nixpkgs";
    android.url = "github:tadfisher/android-nixpkgs/stable";
    devshell.url = "github:numtide/devshell";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    android,
    devshell,
    flake-utils,
    nixpkgs,
    ...
  }:
    flake-utils.lib.eachSystem ["x86_64-linux"] (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            devshell.overlays.default
          ];
        };
        android-sdk = android.sdk.${system} (sdkPkgs:
          with sdkPkgs; [
            build-tools-34-0-0
            cmake-3-22-1
            cmdline-tools-latest
            ndk-26-1-10909125
            platforms-android-34
            platform-tools
            skiaparser-3
            sources-android-34
          ]);
        versions = let
          buildTools = pkgs.lib.lists.findFirst (x: builtins.match "build-tools-.*" x.pname != null) {} android-sdk.packages;
          ndk =
            pkgs.lib.lists.findFirst (x: builtins.match "ndk-.*" x.pname != null) {} android-sdk.packages;
        in {
          buildToolsFull = buildTools.version + ".0.0";
          buildToolsShort = buildTools.version;
          ndk = ndk.version;
        };
        toolchain = "${android-sdk}/share/android-sdk/ndk/${versions.ndk}/toolchains/llvm/prebuilt/linux-x86_64";
      in {
        formatter = pkgs.alejandra;
        devShell = pkgs.devshell.mkShell {
          name = "android-flake-example";
          motd = ''
            Entered the Android flake example app development environment.
          '';
          commands = [
            {
              name = "gradleAapt2";
              help = "Gradle with overriden aapt2";
              command = let
                aapt2 = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${android-sdk}/share/android-sdk/build-tools/${versions.buildToolsFull}/aapt2";
              in ''
                #!/usr/bin/env -S zsh --login --interactive
                gradle ${aapt2} "$@"
              '';
            }
            {
              name = "aarch64-linux-android-clang++";
              command = ''
                #!/usr/bin/env -S zsh --login --interactive
                ${toolchain}/bin/aarch64-linux-android${versions.buildToolsShort}-clang++ "$@"
              '';
            }
            {
              name = "c++";
              command = ''
                #!/usr/bin/env -S zsh --login --interactive
                ${toolchain}/bin/aarch64-linux-android${versions.buildToolsShort}-clang++ "$@"
              '';
            }
            {
              name = "aarch64-linux-android-ar";
              command = ''
                #!/usr/bin/env -S zsh --login --interactive
                ${toolchain}/bin/llvm-ar "$@"
              '';
            }
          ];
          env = [
            {
              name = "ANDROID_HOME";
              value = "${android-sdk}/share/android-sdk";
            }
          ];
          packages = [
            android-sdk
            pkgs.androidStudioPackages.stable
          ];
        };
      }
    );
}
