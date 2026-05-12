{ config, pkgs, inputs, ... }:

{
  imports = [ inputs.walker.homeManagerModules.default ];

  programs.walker = {
    enable = true;
    runAsService = true;

    config = {
      theme = "custom";

      #placeholders."default" = { input = "Search"; list = "No results"; };
      
      placeholders = {
        "default" = { input = "Search:"; list = "No results"; };
        "desktopapplications" = { input = "Search application"; list = "No applications"; };
      };

      providers = {

        prefixes = [
          {provider = "websearch"; prefix = "+";}
          {provider = "providerlist"; prefix = "_";}
        ];
      };

      keybinds.quick_activate = [ ];
      #keybinds.quick_activate = ["F1" "F2" "F3" "F4" "F5"];
    };

    themes = {
      "custom" = {
        style = builtins.readFile ./themes/custom/style.css;
        layouts = {
          layout = builtins.readFile ./themes/custom/layout.xml;
          item = builtins.readFile ./themes/custom/item.xml;
          item_providerlist = builtins.readFile ./themes/custom/item_providerlist.xml;
        };
      };
    };
  };
}
