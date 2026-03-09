local M = {}

local health = vim.health

function M.check()
  health.start("ghostty-navigator.nvim")

  -- Neovim version
  if vim.fn.has("nvim-0.9") == 1 then
    health.ok("Neovim >= 0.9")
  else
    health.error("Neovim >= 0.9 required")
  end

  -- Ghostty terminal
  if vim.env.TERM_PROGRAM == "ghostty" then
    health.ok("Running inside Ghostty")
  else
    health.warn("Not running inside Ghostty (TERM_PROGRAM=" .. (vim.env.TERM_PROGRAM or "nil") .. ")")
  end

  -- Daemon binary
  local bin = (os.getenv("HOME") or "") .. "/.local/bin/ghostty-navigator.nvim"
  if vim.fn.executable(bin) == 1 then
    health.ok("Daemon binary found: " .. bin)
  else
    health.error("Daemon binary not found. Run `make` in the plugin directory to build it.")
  end

  -- LaunchAgent loaded
  vim.fn.system({ "launchctl", "list", "dev.tmm.ghostty-navigator" })
  if vim.v.shell_error == 0 then
    health.ok("LaunchAgent is loaded")
  else
    health.error("LaunchAgent is not loaded. Run `make` in the plugin directory.")
  end

  -- Daemon process running
  local ps = vim.fn.system({ "pgrep", "-f", "ghostty-navigator.nvim" })
  if vim.v.shell_error == 0 and ps ~= "" then
    health.ok("Daemon process is running (PID " .. vim.trim(ps):match("%d+") .. ")")
  else
    health.error(
      "Daemon is not running. Grant Accessibility permissions in System Settings > Privacy & Security > Accessibility, then restart with `launchctl stop dev.tmm.ghostty-navigator && launchctl start dev.tmm.ghostty-navigator`"
    )
  end
end

return M
