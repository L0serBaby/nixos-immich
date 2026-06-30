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

  # Declarative mount for the Immich data disk
  # by-label, NOT /dev/sdX - disk letters (sda/sdb) are not stable across reboots on this platform
  # x-systemd.device-timeout gives udev time to register the label before giving up
  # nofail prevents a missing/slow disk from dropping the whole boot to emergency mode
  fileSystems."/var/lib/immich" = {
    device = "/dev/disk/by-label/immich-data";
    fsType = "ext4";
    options = [ "nofail" "x-systemd.device-timeout=30s" ];
  };

  # Explicit ordering so immich-server actually waits for its dependencies
  # instead of racing them on boot
  systemd.services.immich-server = {
    after = [ "postgresql.service" "redis-immich.service" "var-lib-immich.mount" ];
    requires = [ "postgresql.service" "redis-immich.service" "var-lib-immich.mount" ];
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