# NixOS Config — Framework 13 (11th gen Intel) + Desktop

## Structure

```
flake.nix                       ← entry point, all inputs declared here
modules/
  common.nix                    ← shared config: bootloader, Nix settings, audio, portals
  gaming.nix                    ← Steam, Proton-GE, GameMode, MangoHud, Vesktop
  nvidia.nix                    ← NVIDIA driver overrides (desktop only, opt-in)
hosts/
  framework/
    configuration.nix           ← niri, greetd, fingerprint, power, bluetooth
    hardware-configuration.nix  ← GENERATED during install — disk UUIDs, modules
  desktop/
    configuration.nix           ← (add when ready)
    hardware-configuration.nix  ← (generated when you install on desktop)
home/
  home.nix                      ← Home Manager: niri keybinds, tmux, bash, packages
```

## Before You Start: Checklist

1. **Back up Ubuntu** — copy anything important off the Framework first
2. **Disable Secure Boot** — Framework BIOS → Security → Secure Boot → Disabled
3. **Download the ISO** — https://nixos.org/download → NixOS 24.11 / minimal x86_64
4. **Flash the ISO** — `dd if=nixos.iso of=/dev/sdX bs=4M status=progress` (or Ventoy/Balena Etcher)

## Installation Steps

### 1. Boot the ISO

- Insert USB, power on Framework, press F12 at the Framework logo to get the boot menu
- Select your USB drive
- Boot into the NixOS live environment (graphical or minimal, either works)

### 2. Partition the Disk

```bash
# Identify your NVMe drive (usually nvme0n1)
lsblk

# Open parted
sudo parted /dev/nvme0n1 -- mklabel gpt

# EFI partition (512MB)
sudo parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
sudo parted /dev/nvme0n1 -- set 1 esp on

# Root partition (rest of the disk)
sudo parted /dev/nvme0n1 -- mkpart primary 512MiB 100%
```

### 3. Format and Create btrfs Subvolumes

```bash
# Format EFI
sudo mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1

# Format root as btrfs
sudo mkfs.btrfs -L nixos /dev/nvme0n1p2

# Mount root to create subvolumes
sudo mount /dev/nvme0n1p2 /mnt

# Create subvolumes
sudo btrfs subvolume create /mnt/@
sudo btrfs subvolume create /mnt/@home
sudo btrfs subvolume create /mnt/@nix
sudo btrfs subvolume create /mnt/@snapshots
sudo btrfs subvolume create /mnt/@swap

# Unmount
sudo umount /mnt
```

### 4. Mount Everything

```bash
# Mount root subvolume
sudo mount -o compress=zstd,noatime,subvol=@ /dev/nvme0n1p2 /mnt

# Create mount points
sudo mkdir -p /mnt/{boot,home,nix,.snapshots,swap}

# Mount the rest
sudo mount -o compress=zstd,noatime,subvol=@home       /dev/nvme0n1p2 /mnt/home
sudo mount -o compress=zstd,noatime,subvol=@nix        /dev/nvme0n1p2 /mnt/nix
sudo mount -o noatime,subvol=@snapshots                /dev/nvme0n1p2 /mnt/.snapshots
sudo mount -o noatime,subvol=@swap                     /dev/nvme0n1p2 /mnt/swap
sudo mount /dev/nvme0n1p1 /mnt/boot

# Create swapfile (set size to your RAM in GiB, e.g. 16G)
sudo btrfs filesystem mkswapfile --size 16G /mnt/swap/swapfile
sudo swapon /mnt/swap/swapfile
```

### 5. Generate Base Config

```bash
sudo nixos-generate-config --root /mnt
```

### 6. Clone This Repo

```bash
# Install git temporarily
nix-shell -p git

# Clone your config into /mnt/etc/nixos
# (replace with your actual repo URL)
sudo git clone https://github.com/yourname/nixos-config /mnt/etc/nixos

# Copy the generated hardware config into the framework host folder
sudo cp /mnt/etc/nixos/hardware-configuration.nix \
        /mnt/etc/nixos/hosts/framework/hardware-configuration.nix
```

### 7. Edit hardware-configuration.nix

Add the btrfs mount options — nixos-generate-config detects the mounts but
not the options. Open the file and ensure each btrfs entry has the matching
`options = [ ... ]` from the template in `hosts/framework/hardware-configuration.nix`.

Also update `modules/common.nix`:
- Change `"you"` to your actual username
- Change the timezone

### 8. Install

```bash
sudo nixos-install --flake /mnt/etc/nixos#framework
```

Set the root password when prompted. Then:

```bash
sudo reboot
```

### 9. First Boot

Log in via the greetd TUI greeter → niri starts.

Set your user password:
```bash
passwd
```

Enroll fingerprints (optional):
```bash
fprintd-enroll
```

### 10. Ongoing Workflow

```bash
# Update system (alias defined in home.nix)
update

# Update flake inputs AND system
upgrade

# Rollback if something breaks
rollback

# List all generations
generations

# Take a manual btrfs snapshot before something risky
snap
```

## Transferring to Desktop Later

1. Add a `hosts/desktop/configuration.nix` (copy framework's, adjust hostname)
2. Run `nixos-generate-config` on the desktop during its install
3. Copy its `hardware-configuration.nix` to `hosts/desktop/`
4. Uncomment the `desktop` block in `flake.nix`
5. Uncomment the `nvidia.nix` import in the desktop host config
6. `sudo nixos-rebuild switch --flake /etc/nixos#desktop`
