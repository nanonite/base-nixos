{ config, pkgs, lib, ... }:

# ── Desktop — NVIDIA-specific overrides ───────────────────────────────────────
# This module is added to the "desktop" host in flake.nix.
# It extends the shared gaming.nix hardware.opengl block with NVIDIA drivers.
#
# Uncomment the desktop block in flake.nix when you're ready.

{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # modesetting is required for Wayland (niri) on NVIDIA
    modesetting.enable = true;

    # Use the proprietary driver — open-source kernel module is not stable
    # enough for Wayland + gaming workloads yet as of early 2026
    open = false;

    nvidiaSettings = true;

    # Pin to stable driver — change to .beta or .production if needed
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Helps with suspend/resume stability on desktop
    powerManagement.enable = true;
  };

  # NVIDIA Wayland environment variables
  # These tell Mesa, GBM, and libva to use the NVIDIA driver
  environment.sessionVariables = {
    GBM_BACKEND             = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME       = "nvidia";
    # Fixes invisible hardware cursor on some NVIDIA + Wayland setups
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  # KVM on desktop is kvm-amd or kvm-intel depending on your CPU
  # Change kvm-intel → kvm-amd if your desktop has a Ryzen/Threadripper CPU
  boot.kernelModules = [ "kvm-intel" "vhost_vsock" ]; # change to kvm-amd if AMD
}
