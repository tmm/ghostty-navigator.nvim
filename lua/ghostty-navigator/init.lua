-- ghostty-navigator: Seamless navigation between Neovim and Ghostty splits.
--
-- When at the edge of Neovim splits, navigates to the adjacent Ghostty
-- split via AppleScript. Similar to vim-tmux-navigator but for Ghostty.
--
-- Uses a flag file (/tmp/ghostty-nvim-active) to signal to the
-- ghostty-navigator daemon that nvim is the focused process. The daemon
-- intercepts Ctrl+hjkl at the OS level and passes them through when
-- nvim is active.
--
-- Requires Ghostty >= 1.3.0 with AppleScript enabled.

local M = {}

local ghostty_directions = { h = "left", j = "bottom", k = "top", l = "right" }
local flag_file = "/tmp/ghostty-nvim-active"

--- Check if the current terminal is Ghostty.
---@return boolean
local function is_ghostty()
  return vim.env.TERM_PROGRAM == "ghostty"
end

--- Write the flag file with PID to signal nvim is active.
local function write_flag()
  local f = io.open(flag_file, "w")
  if f then
    f:write(tostring(vim.fn.getpid()))
    f:close()
  end
end

--- Remove the flag file to signal nvim is no longer active.
local function remove_flag()
  os.remove(flag_file)
end

--- Navigate to the Ghostty split in the given direction.
---@param direction string One of "left", "right", "top", "bottom"
local function goto_ghostty_split(direction)
  vim.fn.jobstart({
    "osascript",
    "-e",
    'tell application "Ghostty"',
    "-e",
    "set t to focused terminal of selected tab of front window",
    "-e",
    'perform action "goto_split:' .. direction .. '" on t',
    "-e",
    "end tell",
  }, { detach = true })
end

--- Navigate in the given direction, crossing from Neovim to Ghostty when at edge.
---@param direction string One of "h", "j", "k", "l"
function M.navigate(direction)
  local win = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. direction)
  if vim.api.nvim_get_current_win() == win and is_ghostty() then
    goto_ghostty_split(ghostty_directions[direction])
  end
end

--- Set up keymaps for Ctrl+hjkl navigation.
---@param opts? { keys?: table<string, string> }
function M.setup(opts)
  opts = opts or {}
  local keys = opts.keys or {
    ["<C-h>"] = "h",
    ["<C-j>"] = "j",
    ["<C-k>"] = "k",
    ["<C-l>"] = "l",
  }

  if not is_ghostty() then
    return
  end

  write_flag()

  local group = vim.api.nvim_create_augroup("GhosttyNavigator", { clear = true })
  vim.api.nvim_create_autocmd("FocusGained", {
    group = group,
    callback = write_flag,
  })
  vim.api.nvim_create_autocmd("FocusLost", {
    group = group,
    callback = remove_flag,
  })
  vim.api.nvim_create_autocmd("VimSuspend", {
    group = group,
    callback = remove_flag,
  })
  vim.api.nvim_create_autocmd("VimResume", {
    group = group,
    callback = write_flag,
  })
  vim.api.nvim_create_autocmd("VimLeave", {
    group = group,
    callback = remove_flag,
  })

  for lhs, dir in pairs(keys) do
    vim.keymap.set({ "n", "t" }, lhs, function()
      if vim.fn.mode() == "t" then
        vim.cmd("stopinsert")
      end
      M.navigate(dir)
    end, { desc = "Go to " .. ghostty_directions[dir] .. " window/split" })
  end
end

return M
