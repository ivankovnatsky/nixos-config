-- Auto-capitalize first letter after sentence endings (. ? !)
-- Works in: prose filetypes, scratch buffers, and comment lines in code files

local prose_filetypes = {
  markdown = true,
  text = true,
  gitcommit = true,
  mail = true,
  plaintex = true,
  tex = true,
  rst = true,
  asciidoc = true,
  [""] = true, -- scratch buffers
}

local function is_in_comment()
  local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
  if not ok then
    return false
  end

  local node = ts_utils.get_node_at_cursor()
  while node do
    if node:type():match("comment") then
      return true
    end
    node = node:parent()
  end
  return false
end

local function should_auto_capitalize()
  local ft = vim.bo.filetype

  -- For gitcommit, skip the first line (title/subject line)
  if ft == "gitcommit" and vim.fn.line(".") == 1 then
    return false
  end

  -- Always enable for prose filetypes
  if prose_filetypes[ft] then
    return true
  end

  -- For other files, only enable in comments (via treesitter)
  return is_in_comment()
end

-- Words that should always be capitalized
local always_capitalize = {
  ["i"] = "I",
  ["i'm"] = "I'm",
  ["i've"] = "I've",
  ["i'll"] = "I'll",
  ["i'd"] = "I'd",
}

-- Auto-capitalize after sentence endings
vim.api.nvim_create_autocmd("InsertCharPre", {
  callback = function()
    if not should_auto_capitalize() then
      return
    end
    if not vim.v.char:match("%a") then
      return
    end

    local line = vim.fn.getline(".")
    local col = vim.fn.col(".") - 1
    local before = line:sub(1, col)

    -- Check current line for sentence ending (requires space after punctuation)
    if before:match("[%.%?!]%s+$") then
      vim.v.char = vim.v.char:upper()
      return
    end

    -- Check if at line start and previous line ends a sentence
    if before:match("^%s*$") then
      local prev_line = vim.fn.getline(vim.fn.line(".") - 1)
      if prev_line:match("[%.%?!]%s*$") or prev_line == "" then
        vim.v.char = vim.v.char:upper()
      end
    end
  end,
})

-- Auto-capitalize words like "I", "I'm", etc. after typing space or punctuation
vim.api.nvim_create_autocmd("InsertCharPre", {
  callback = function()
    if not should_auto_capitalize() then
      return
    end
    -- Trigger on space or punctuation after a word
    if not vim.v.char:match("[%s%p]") then
      return
    end

    local line = vim.fn.getline(".")
    local col = vim.fn.col(".") - 1
    local before = line:sub(1, col)

    -- Get the last word before cursor
    local word = before:match("(%S+)$")
    if not word then
      return
    end

    local replacement = always_capitalize[word:lower()]
    if replacement and word ~= replacement then
      local lnum = vim.fn.line(".")
      local start_col = col - #word
      -- Schedule the replacement since we can't modify text in InsertCharPre
      vim.schedule(function()
        local current_line = vim.fn.getline(lnum)
        local new_line = current_line:sub(1, start_col) .. replacement .. current_line:sub(start_col + #word + 1)
        vim.fn.setline(lnum, new_line)
      end)
    end
  end,
})
