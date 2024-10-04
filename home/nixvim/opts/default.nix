{ config, ... }:

{
  programs.nixvim = {
    opts = {
      # My options
      # Background
      # background = if config.flags.darkMode then "dark" else "light";

      # Disable mouse mode, this is needed for handy copy-pasting from the
      # command line.
      mouse = "";

      foldmethod = "marker";
      autowrite = true;
      lazyredraw = true;
      showmatch = true;
      # Display commands typing in
      showcmd = true;

      # My options end

      # Enable relative line numbers
      number = true;
      relativenumber = true;

      # Set tabs to 2 spaces
      tabstop = 2;
      softtabstop = 2;

      expandtab = true;

      # Enable auto indenting and set it to spaces
      smartindent = true;
      shiftwidth = 2;

      # Enable smart indenting (see https://stackoverflow.com/questions/1204149/smart-wrap-in-vim)
      breakindent = true;

      # Enable incremental searching
      hlsearch = true;
      incsearch = true;

      # Enable text wrap
      wrap = true;

      # Better splitting
      splitbelow = true;
      splitright = true;

      # Enable ignorecase + smartcase for better searching
      ignorecase = true;
      smartcase = true; # Don't ignore case with capitals
      grepprg = "rg --vimgrep";
      grepformat = "%f:%l:%c:%m";

      # Decrease updatetime
      updatetime = 50; # faster completion (4000ms default)

      # Set completeopt to have a better completion experience
      completeopt = [ "menuone" "noselect" "noinsert" ]; # mostly just for cmp

      # Enable persistent undo history
      swapfile = false;
      backup = false;
      undofile = true;

      # Enable 24-bit colors
      termguicolors = true;

      # Enable the sign column to prevent the screen from jumping
      # signcolumn = "yes";

      # Enable cursor line highlight
      cursorline = true; # Highlight the line where the cursor is located

      # Set fold settings
      # These options were reccommended by nvim-ufo
      # See: https://github.com/kevinhwang91/nvim-ufo#minimal-configuration
      foldcolumn = "0";
      foldlevel = 99;
      foldlevelstart = 99;
      foldenable = true;

      # Always keep 8 lines above/below cursor unless at start/end of file
      scrolloff = 8;

      # Place a column line
      # colorcolumn = "80";

      # Reduce which-key timeout to 10ms
      # https://github.com/tpope/vim-commentary/issues/105
      # https://github.com/tpope/vim-commentary/issues/46
      # FIXME: try out comment plugin and uncomment to try it out.
      # timeoutlen = 10;

      # Set encoding type
      encoding = "utf-8";
      fileencoding = "utf-8";

      # More space in the neovim command line for displaying messages
      cmdheight = 0;

      # We don't need to see things like INSERT anymore
      showmode = true;
    };
    extraConfigLua = ''
      vim.opt.langmap = 'йq,цw,уe,кr,еt,нy,гu,шi,щo,зp,х[,ї],' ..
        'фa,іs,вd,аf,пg,рh,оj,лk,дl,ж\\;,є\',ґ\\,яz,чx,сc,мv,иb,тn,ьm,б\\,,ю.,' ..
        'ЙQ,ЦW,УE,КR,ЕT,НY,ГU,ШI,ЩO,ЗP,Х{,Ї},ФA,' ..
        'ІS,ВD,АF,ПG,РH,ОJ,ЛK,ДL,Ж\\:,Є\\",Ґ\\|,ЯZ,ЧX,СC,МV,ИB,ТN,ЬM,Б\\<,Ю>,№#'

      ${builtins.readFile ./appearance.lua}
    '';
  };
}
