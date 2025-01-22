-- TODO: Make sure lsp is working
local _border = "rounded"

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = _border,
})

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
  border = _border,
})

vim.diagnostic.config({
  float = { border = _border },
})

require("lspconfig.ui.windows").default_options = {
  border = _border,
}

-- Make the preview window wider
require("telescope").setup({
  defaults = {
    layout_config = { width = 0.9 },
  },
})

function _G.TelescopeGrepString(input)
  require("telescope.builtin").grep_string({ search = input })
end

vim.cmd([[
function! GetVisualSelection()
  let [line_start, column_start] = getpos("'<")[1:2]
  let [line_end, column_end] = getpos("'>")[1:2]
  let lines = getline(line_start, line_end)
  if len(lines) == 0
    return ''
  endif
  let lines[-1] = lines[-1][: column_end - 2]
  let lines[0] = lines[0][column_start - 1:]
  return join(lines, "\n")
endfunction
]])
