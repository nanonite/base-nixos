{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules          = [ ];
  boot.kernelModules                 = [ "kvm-intel" ];
  boot.extraModulePackages           = [ ];

  fileSystems."/" = {
    device  = "/dev/disk/by-uuid/abea7246-8a9f-4ebf-a76a-43c194129af4";
    fsType  = "btrfs";
    options = [ "subvol=@" "compress=zstd" "noatime" ];
  };

  fileSystems."/home" = {
    device  = "/dev/disk/by-uuid/abea7246-8a9f-4ebf-a76a-43c194129af4";
    fsType  = "btrfs";
    options = [ "subvol=@home" "compress=zstd" "noatime" ];
  };

  fileSystems."/nix" = {
    device  = "/dev/disk/by-uuid/abea7246-8a9f-4ebf-a76a-43c194129af4";
    fsType  = "btrfs";
    options = [ "subvol=@nix" "compress=zstd" "noatime" ];
  };

  # btrfs top-level mount — needed by btrbk to see raw subvolumes (@, @home, etc.)
  fileSystems."/btrfs" = {
    device  = "/dev/disk/by-uuid/abea7246-8a9f-4ebf-a76a-43c194129af4";
    fsType  = "btrfs";
    options = [ "subvolid=5" "noatime" ];
  };

  fileSystems."/.snapshots" = {
    device  = "/dev/disk/by-uuid/abea7246-8a9f-4ebf-a76a-43c194129af4";
    fsType  = "btrfs";
    options = [ "subvol=@snapshots" "noatime" ];
  };

  fileSystems."/swap" = {
    device  = "/dev/disk/by-uuid/abea7246-8a9f-4ebf-a76a-43c194129af4";
    fsType  = "btrfs";
    options = [ "subvol=@swap" "noatime" ];
  };

  fileSystems."/boot" = {
    device  = "/dev/disk/by-uuid/ABC8-093E";
    fsType  = "vfat";
    options = [ "fmask=0137" "dmask=0027" ];  # restrict EFI permissions (fixes random-seed warning)
  };

  swapDevices = [{
    device = "/swap/swapfile";
  }];

  nixpkgs.hostPlatform              = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
