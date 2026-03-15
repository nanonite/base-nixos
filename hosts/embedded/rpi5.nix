{ pkgs, lib, ... }:

# ── rpi5.nix — Raspberry Pi 5 (stub — extend when ready) ─────────────────────
#
# RPi 5 has hardware KVM (Cortex-A76 with ARMv8.2+ virtualization extension).
# This means mb sandboxes run at near-native speed via kvm-aarch64.
#
# To activate: uncomment rpi5 in flake.nix nixosConfigurations and add the
# nixos-hardware RPi 5 module when it becomes available.

{
  # RPi 5 supports hardware KVM — full speed stereOS sandboxes
  boot.kernelModules = [ "kvm-aarch64" "vhost_vsock" ];

  # RPi 5 firmware bootloader
  boot.loader.raspberryPi = {
    enable  = true;
    version = 5;
  };
  boot.loader.generic-extlinux-compatible.enable = true;

  # RPi 5 ships with up to 16 GB RAM — adjust swap
  swapDevices = [{
    device = "/swapfile";
    size   = 8192; # 8 GiB — adjust to your model
  }];

  # TODO: add nixos-hardware RPi 5 module when available:
  # imports = [ nixos-hardware.nixosModules.raspberry-pi-5 ];
}
