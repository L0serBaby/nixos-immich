{ config, pkgs, ... }:

{
  # Bootloader - UEFI
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking - DHCP reservation handled by UniFi
  networking.useDHCP = true;
  networking.hostName = "HoWse-Immich01"; # cloud-init may override

  # Nutanix cloud-init support - hostname/metadata only
  services.cloud-init = {
    enable = true;
    network.enable = false;
  };
  systemd.services.cloud-init.after = [ "network-pre.target" ];

  # Declarative mount for the Immich data disk (sdb)
  # Mounted by device path, not by-label, to avoid boot-time udev race
  # nofail prevents a missing/slow disk from dropping the whole boot to emergency mode
  fileSystems."/var/lib/immich" = {
    device = "/dev/sdb";
    fsType = "ext4";
    options = [ "nofail" ];
  };

  # SSH - password auth
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "changeme";
  };

  # Set a root password too, so emergency mode console is reachable if something fails
  users.users.root.initialPassword = "changeme";

  environment.systemPackages = with pkgs; [
    git
    nano
    curl
    htop
    iputils
    dnsutils
    traceroute
  ];

  # Immich - native NixOS module
  services.immich = {
    enable = true;
    host = "0.0.0.0";
    port = 2283;
    mediaLocation = "/var/lib/immich";
  };

  networking.firewall.allowedTCPPorts = [ 2283 ];

  system.stateVersion = "24.11";
}