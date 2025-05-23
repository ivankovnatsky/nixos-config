{
  # https://github.com/okuuva/auto-save.nvim
  programs.nixvim.plugins.auto-save = {
    enable = true;
    settings = {
      trigger_events = {
        immediate_save = [
          "BufLeave"
          "FocusLost"
        ];
        defer_save = [
          "InsertLeave"
          "TextChanged"
        ];
        cancel_deferred_save = [ "InsertEnter" ];
      };
      write_all_buffers = false;
      noautocmd = false;
      lockmarks = false;
      debounce_delay = 5000;
      debug = false;

      condition = ''
        function(buf)
          local fn = vim.fn
          local utils = require("auto-save.utils.data")

          if utils.not_in(fn.getbufvar(buf, "&filetype"), {'oil'}) then
            return true
          end
          return false
        end
      '';
    };
  };
}
