if vim.g.loaded_ghostty_navigator then
  return
end
vim.g.loaded_ghostty_navigator = true

local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")

vim.api.nvim_create_user_command("GhosttyNavigatorUninstall", function()
  vim.fn.system({ "make", "-C", plugin_dir, "uninstall" })
  if vim.v.shell_error == 0 then
    vim.notify("ghostty-navigator.nvim: uninstalled", vim.log.levels.INFO)
  else
    vim.notify("ghostty-navigator.nvim: uninstall failed", vim.log.levels.ERROR)
  end
end, { desc = "Uninstall ghostty-navigator daemon and LaunchAgent" })
