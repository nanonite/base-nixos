# ──────────────────────────────────────────────────────────────────────────────
# THIS FILE IS GENERATED DURING INSTALLATION — do not write it by hand.
#
# After booting the NixOS ISO and partitioning your disk with btrfs subvolumes,
# run: nixos-generate-config --root /mnt
# This file will appear at /mnt/etc/nixos/hardware-configuration.nix.
# Copy it here and commit it.
#
# Expected btrfs subvolume layout (created during installation):
#
#   @           →  /
#   @home       →  /home
#   @nix        →  /nix
#   @snapshots  →  /.snapshots    (btrbk writes here)
#   @swap       →  /swap          (btrfs swapfile lives here)
#
# Expected fileSystems entries after generate-config (you'll need to add
# the mount options manually — nixos-generate-config doesn't detect them):
#
#   fileSystems."/" = {
#     device  = "/dev/disk/by-uuid/YOUR-UUID";
#     fsType  = "btrfs";
#     options = [ "subvol=@" "compress=zstd" "noatime" ];
#   };
#   fileSystems."/home" = {
#     device  = "/dev/disk/by-uuid/YOUR-UUID";
#     fsType  = "btrfs";
#     options = [ "subvol=@home" "compress=zstd" "noatime" ];
#   };
#   fileSystems."/nix" = {
#     device  = "/dev/disk/by-uuid/YOUR-UUID";
#     fsType  = "btrfs";
#     options = [ "subvol=@nix" "compress=zstd" "noatime" ];
#   };
#   fileSystems."/.snapshots" = {
#     device  = "/dev/disk/by-uuid/YOUR-UUID";
#     fsType  = "btrfs";
#     options = [ "subvol=@snapshots" "noatime" ];
#   };
#   fileSystems."/boot" = {
#     device  = "/dev/disk/by-uuid/YOUR-EFI-UUID";
#     fsType  = "vfat";
#   };
#   swapDevices = [{
#     device = "/swap/swapfile";
#     size   = 16 * 1024; # in MiB — set to your RAM size for hibernate support
#   }];
# ──────────────────────────────────────────────────────────────────────────────

# Paste the generated hardware-configuration.nix content below this line:

{ config, lib, pkgs, modulesPath, ... }:

{
  # REPLACE THIS ENTIRE FILE with the output of:
  # nixos-generate-config --root /mnt --show-hardware-config
}
