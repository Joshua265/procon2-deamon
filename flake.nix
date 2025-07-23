{
  description = "Userspace Pro Controller 2 (Switch 2) daemon — USB handshake + uinput translator";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        # Allow proprietary firmware if the user enables it globally
        config.allowUnfree = true;
      };

      pname = "procon2-daemon";
      version = "0.1.0";

      # --- Build the Rust binary ------------------------------------------------
      drv = pkgs.rustPlatform.buildRustPackage {
        inherit pname version;
        src = ./.;

        cargoHash = "sha256-+Awdya4v9w9/NNy46WM+u9xnNnOwUdeLbDMkGB064Ok=";

        nativeBuildInputs = [pkgs.pkg-config pkgs.systemd];
        buildInputs = [pkgs.libusb1 pkgs.hidapi];

        postInstall = ''
          # udev rule template (optional)
          mkdir -p $out/lib/udev/rules.d
          cat > $out/lib/udev/rules.d/99-${pname}.rules <<EOF
          SUBSYSTEM=="usb", ATTR{idVendor}=="057e", ATTR{idProduct}=="2069", TAG+="uaccess", GROUP="input", RUN+="${pkgs.systemd}/bin/systemctl --user restart ${pname}.service"
          EOF
        '';

        meta = with pkgs.lib; {
          description = "Daemon that enables Nintendo Pro Controller 2 on Linux via libusb + uinput";
          homepage = "https://github.com/yourhandle/procon2-daemon";
          license = licenses.mit;
          maintainers = [maintainers.Joshua265];
          platforms = platforms.linux;
        };
      };

      # --- Optional: user‑service module ---------------------------------------
      svc = pkgs.writeText "${pname}.service" ''
        [Unit]
        Description=Pro Controller 2 userspace driver
        BindsTo=dev-bus-usb-057E:2069.device

        [Service]
        ExecStart=${drv}/bin/${pname}
        CapabilityBoundingSet=CAP_SYS_RAWIO
        Restart=on-failure

        [Install]
        WantedBy=default.target
      '';
    in {
      packages.default = drv;

      # Quick `nix develop` shell for hacking
      devShells.default = pkgs.mkShell {
        packages = [
          pkgs.rustc
          pkgs.cargo
          pkgs.cargo-edit
          pkgs.pkg-config
          pkgs.libusb1
          pkgs.hidapi
          pkgs.systemd
        ];
        RUST_BACKTRACE = "1";
      };

      # Extra output: systemd unit for users to `systemctl --user enable`.
      packages."${pname}-service" = pkgs.runCommand "${pname}-service" {} ''
        mkdir -p $out
        cp ${svc} $out/
      '';
    });
}
