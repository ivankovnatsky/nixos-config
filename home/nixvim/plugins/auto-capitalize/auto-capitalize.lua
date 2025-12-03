-- Auto-capitalize first letter after sentence endings (. ? !)
-- Only enabled for prose filetypes

local prose_filetypes = { markdown = true, text = true, gitcommit = true }

vim.api.nvim_create_autocmd("InsertCharPre", {
  callback = function()
    if not prose_filetypes[vim.bo.filetype] then return end
    if not vim.v.char:match('%a') then return end

    local line = vim.fn.getline('.')
    local col = vim.fn.col('.') - 1
    local before = line:sub(1, col)

    -- Check current line for sentence ending
    if before:match('[%.%?!]%s*$') then
      vim.v.char = vim.v.char:upper()
      return
    end

    -- Check if at line start and previous line ends a sentence
    if before:match('^%s*$') then
      local prev_line = vim.fn.getline(vim.fn.line('.') - 1)
      if prev_line:match('[%.%?!]%s*$') or prev_line == '' then
        vim.v.char = vim.v.char:upper()
      end
    end
  end,
})
