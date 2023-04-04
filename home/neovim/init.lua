local lsp_servers = {
	"bashls",
	"dhall_lsp_server",
	"gopls",
	"pyright",
	"rnix",
	"rust_analyzer",
	"terraformls",
}

-- Plugins
-- {{{ lualine-nvim
require("lualine").setup({
	options = { component_separators = "", section_separators = "" },
})
-- }}}
-- {{{ fidget-nvim
require("fidget").setup({})
-- }}}
-- {{{ nvim-colorizer-lua
require("colorizer").setup()
-- }}}
-- {{{ cmp-buffer
require("cmp").setup({ sources = { { name = "buffer" } } })
-- }}}
-- {{{ cmp-path
require("cmp").setup({ sources = { { name = "path" } } })
-- }}}
-- {{{ cmp-cmdline
local cmp = require("cmp")
-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline({ "/", "?" }, {
	mapping = cmp.mapping.preset.cmdline(),
	sources = { { name = "buffer" } },
})

--  Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(":", {
	mapping = cmp.mapping.preset.cmdline(),
	sources = cmp.config.sources({ { name = "path" } }, {
		{ name = "cmdline", option = { ignore_cmds = { "Man" } } },
	}),
})
-- }}}
-- {{{ cmp-nvim-lsp
require("cmp").setup({ sources = { { name = "nvim_lsp" } } })
-- The nvim-cmp almost supports LSP's capabilities so You should advertise it to LSP servers
local capabilities = require("cmp_nvim_lsp").default_capabilities()

for _, server in ipairs(lsp_servers) do
	require("lspconfig")[server].setup({ capabilities = capabilities })
end
-- }}}
-- {{{ nvim-cmp
-- Set up nvim-cmp.
local cmp = require("cmp")

cmp.setup({
	snippet = {
		-- REQUIRED - you must specify a snippet engine
		expand = function(args)
			-- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
			require("luasnip").lsp_expand(args.body) -- For `luasnip` users.
			-- require('snippy').expand_snippet(args.body) -- For `snippy` users.
			-- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
		end,
	},
	window = {
		-- completion = cmp.config.window.bordered(),
		-- documentation = cmp.config.window.bordered(),
	},
	mapping = cmp.mapping.preset.insert({
		["<C-b>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.abort(),
		["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
	}),
	sources = cmp.config.sources({
		{ name = "nvim_lsp" },
		{ name = "vsnip" }, -- For vsnip users.
		-- { name = 'luasnip' }, -- For luasnip users.
		-- { name = 'ultisnips' }, -- For ultisnips users.
		-- { name = 'snippy' }, -- For snippy users.
	}, { { name = "buffer" } }),
})

-- Set configuration for specific filetype.
cmp.setup.filetype("gitcommit", {
	sources = cmp.config.sources({
		{ name = "cmp_git" }, -- You can specify the `cmp_git` source if you were installed it.
	}, { { name = "buffer" } }),
})
-- }}}
-- {{{ nvim-tree-lua
require("nvim-tree").setup({
	respect_buf_cwd = true,
	disable_netrw = false,
	hijack_directories = { enable = true, auto_open = true },
	actions = { use_system_clipboard = true, open_file = { resize_window = true } },
	view = { side = "left", width = 40, relativenumber = true },
	git = { enable = true, ignore = false, timeout = 500 },
})

local function open_nvim_tree(data)
	-- buffer is a directory
	local directory = vim.fn.isdirectory(data.file) == 1

	if not directory then
		return
	end

	-- check if argument list is empty
	if vim.tbl_isempty(vim.fn.argv()) then
		-- create a new, empty buffer
		vim.cmd.enew()

		-- wipe the directory buffer
		vim.cmd.bw(data.buf)

		-- change to the directory
		vim.cmd.cd(data.file)

		-- open the tree
		require("nvim-tree.api").tree.open()
	end
end

open_nvim_tree({ buf = vim.fn.bufnr(), file = vim.fn.expand("%:p:h") })
-- }}}
-- {{{ nvim-lspconfig
-- Setup language servers.
local lspconfig = require("lspconfig")

for _, server in ipairs(lsp_servers) do
	lspconfig[server].setup({
		capabilities = capabilities,
		on_attach = on_attach,
		flags = lsp_flags,
	})
end

-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set("n", "<space>e", vim.diagnostic.open_float)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist)

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		-- Enable completion triggered by <c-x><c-o>
		vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

		-- Buffer local mappings.
		-- See `:help vim.lsp.*` for documentation on any of the below functions
		local opts = { buffer = ev.buf }
		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
		-- vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
		vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, opts)
		vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, opts)
		vim.keymap.set("n", "<space>wl", function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end, opts)
		vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, opts)
		vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
		vim.keymap.set("n", "<space>ca", vim.lsp.buf.code_action, opts)
		vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
		vim.keymap.set("n", "<space>f", function()
			vim.lsp.buf.format({ async = true })
		end, opts)
	end,
})

require("lspkind").init({
	-- DEPRECATED (use mode instead): enables text annotations
	--
	-- default: true
	-- with_text = true,

	-- defines how annotations are shown
	-- default: symbol
	-- options: 'text', 'text_symbol', 'symbol_text', 'symbol'
	mode = "symbol_text",

	-- default symbol map
	-- can be either 'default' (requires nerd-fonts font) or
	-- 'codicons' for codicon preset (requires vscode-codicons font)
	--
	-- default: 'default'
	preset = "codicons",

	-- override preset symbols
	--
	-- default: {}
	symbol_map = {
		Text = "",
		Method = "",
		Function = "",
		Constructor = "",
		Field = "ﰠ",
		Variable = "",
		Class = "ﴯ",
		Interface = "",
		Module = "",
		Property = "ﰠ",
		Unit = "塞",
		Value = "",
		Enum = "",
		Keyword = "",
		Snippet = "",
		Color = "",
		File = "",
		Reference = "",
		Folder = "",
		EnumMember = "",
		Constant = "",
		Struct = "פּ",
		Event = "",
		Operator = "",
		TypeParameter = "",
	},
})
-- }}}
