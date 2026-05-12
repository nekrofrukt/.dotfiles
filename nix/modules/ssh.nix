{ config, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = {
        hashKnownHosts = true;
	    serverAliveInterval = 60;
	    serverAliveCountMax = 3;
	    identitiesOnly = true;
      };

      "github.com" = {
        user = "git";
	    hostname = "github.com";
	    identityFile = "~/.ssh/id_ed25519";
	    identitiesOnly = true;
      };

      "raspberry-pi" = {
        hostname = "192.168.1.60";
	    user = "nekrofrukt";
      };

      "tailscale-pi" = {
        hostname = "100.77.202.15";
	    user = "nekrofrukt";
      };
    };
  };
}
