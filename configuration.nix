{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # TODO this on bare metal
  networking.hostName = "nixos"; # Define your hostname.

  # TODO definitely fix this
  networking.firewall.enable = false;

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.nik = {
    isNormalUser = true;
    extraGroups = [ "wheel" "multimedia" ]; 
  };

  # get vim and configure it to not be fugly
  environment.systemPackages = with pkgs; [
    ((vim_configurable.override { }).customize{
      name = "vim";
      vimrcConfig.packages.myplugins = with pkgs.vimPlugins; {
        start = [vim-nix vim-lastplace];
        opt = [];
      };
      vimrcConfig.customRC = ''
        syntax on
        set number relativenumber autoindent
	set clipboard=unnamedplus
      '';
    })
    git
  ];

  # create mutltimedia group so services can write each other's data
  users.groups.multimedia = { };

  # put all the multimedia here
  # TODO fix this to make jellyfin dash look good 
  systemd.tmpfiles.rules = [
    "d /data/media 0770 - multimedia - -"
  ];
  
  services= {
    openssh.enable = true;
    # TODO expore if this can be declarative
    jellyfin = {
      enable = true;
      group = "multimedia";
    };
    sonarr = {enable = true; group = "multimedia"; };
    radarr = {enable = true; group = "multimedia"; };
    bazarr = {enable = true; group = "multimedia"; };
    readarr = {enable = true; group = "multimedia"; };
    prowlarr = {enable = true; };

    # this is declarative - nice
    deluge = {
      enable = true;
      group = "multimedia";
      web.enable = true;
      dataDir = "/data/media/torrent";
      declarative = true;
      config = {
        enabled_plugins = [ "Label" ];
      };
      authFile = pkgs.writeTextFile {
        name = "deluge-auth";
	text = ''
	  localclient::10
        '';	  
      };
    };
  };


  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?

}

