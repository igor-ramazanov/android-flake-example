{
  description = "An example to build Android app using Nix";

  inputs = {
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
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
          config.android_sdk.accept_license = true;
          overlays = [devshell.overlays.default];
        };
        # TODO: find a way to pull new versions
        versions = {
          cmdLineTools = "13.0";
          tools = "26.1.1";
          platformTools = "35.0.2";
          buildTools = "34.0.0";
          emulator = "35.2.5";
          platform = "34";
          cmake = "3.22.1";
          ndk = "27.0.12077973";
        };
        androidComposition = pkgs.androidenv.composeAndroidPackages {
          cmdLineToolsVersion = versions.cmdLineTools;
          toolsVersion = versions.tools;
          platformToolsVersion = versions.platformTools;
          buildToolsVersions = [versions.buildTools];
          includeEmulator = true;
          emulatorVersion = versions.emulator;
          platformVersions = [versions.platform];
          includeSources = true;
          includeSystemImages = true;
          systemImageTypes = ["google_apis"];
          abiVersions = ["x86_64" "arm64-v8a"];
          cmakeVersions = [versions.cmake];
          includeNDK = true;
          ndkVersion = versions.ndk;
          ndkVersions = [versions.ndk];
          useGoogleAPIs = true;
          useGoogleTVAddOns = true;
          includeExtras = [];
          extraLicenses = [];
        };
        androidsdk = androidComposition.androidsdk;
        # TODO: doesn't work at the moment
        emulator = pkgs.androidenv.emulateApp {
          name = "android-flake-example-emulator";
          platformVersion = versions.platform;
          systemImageType = "google_apis";
          abiVersion = "x86_64";
          enableGPU = false;
        };
      in {
        formatter = pkgs.alejandra;
        devShell = pkgs.devshell.mkShell {
          name = "android-flake-example";
          motd = ''
            Entered the Android flake example app development environment.
          '';
          env = [
            {
              name = "ANDROID_HOME";
              value = "${androidsdk}/libexec/android-sdk";
            }
            {
              name = "GRADLE_OPTS";
              value = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidsdk}/libexec/android-sdk/build-tools/${versions.buildTools}/aapt2";
            }
          ];
          packages = [
            androidsdk
            emulator
            (pkgs.android-studio-full.withSdk androidsdk)
          ];
        };
      }
    );
}
