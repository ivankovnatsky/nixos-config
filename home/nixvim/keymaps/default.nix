{
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<C-h>";
      action = "<C-W>h";
      options = {
        silent = true;
        desc = "Move to window left";
      };
    }
    {
      mode = "n";
      key = "<C-l>";
      action = "<C-W>l";
      options = {
        silent = true;
        desc = "Move to window right";
      };
    }
    {
      mode = "n";
      key = "<C-k>";
      action = "<C-W>k";
      options = {
        silent = true;
        desc = "Move to window over";
      };
    }
    {
      mode = "n";
      key = "<C-j>";
      action = "<C-W>j";
      options = {
        silent = true;
        desc = "Move to window bellow";
      };
    }
    {
      mode = "n";
      key = "ZA";
      action = ":bd<CR>";
      options = {
        silent = true;
        desc = "Close buffer";
      };
    }
    {
      mode = "n";
      key = "ZX";
      action = ":w | bd<CR>";
      options = {
        silent = true;
        desc = "Save and close buffer";
      };
    }
  ];
}
