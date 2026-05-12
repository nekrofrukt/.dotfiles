{ config, pkgs, ... }:

{
  dconf.settings = {
    "org.gnome.desktop.peripherals.keyboard" = {
      repeat = true;
      delay = 200;
      repeat-interval = 30;
    };
  };
}
