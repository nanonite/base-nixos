{ pkgs, lib, ... }:

# ── rpi4.nix — Raspberry Pi 4 specific overrides ─────────────────────────────
#
# Loaded via extraModules in flake.nix alongside nixos-hardware.raspberry-pi-4.
# The nixos-hardware module handles: GPU firmware, DTS overlays, camera support.
# This file adds anything not covered by nixos-hardware.

{
  # RPi firmware bootloader (not systemd-boot)
  boot.loader.raspberryPi = {
    enable  = true;
    version = 4;
  };
  boot.loader.generic-extlinux-compatible.enable = true;

  # RPi 4 specific kernel modules
  # Note: RPi 4 does NOT support hardware KVM acceleration —
  # mb sandboxes run in QEMU/TCG mode (slower). RPi 5 has KVM.
  boot.kernelModules = lib.mkForce [
    "vhost_vsock" # vsock for masterblaster stereOS communication
    "bcm2835-v4l2" # camera module support
    # kvm-aarch64 is NOT available on RPi 4 (no virtualization extension in Cortex-A72)
  ];

  # RPi 4 has 4–8 GB RAM — set swap accordingly
  # Adjust to your board's RAM size
  swapDevices = [{
    device = "/swapfile";
    size   = 4096; # 4 GiB — adjust if you have 8 GB model
  }];

  # Framebuffer for serial/HDMI console during boot
  boot.initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
}
