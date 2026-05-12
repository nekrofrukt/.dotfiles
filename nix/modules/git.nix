{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name  = "nekrofrukt";
        email = "nekrofrukt@pm.me";
      };
      #init.defaultBranch = "main";
    };
  };
}
