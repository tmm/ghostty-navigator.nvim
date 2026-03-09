# ghostty-navigator.nvim

Seamless navigation between Neovim and [Ghostty](https://ghostty.org) splits using `Ctrl+hjkl`. Inspired by [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator).

<video src="https://github.com/tmm/ghostty-navigator.nvim/raw/main/.github/demo.mp4"></video>

## Install

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "tmm/ghostty-navigator.nvim",
  build = "make",
  opts = {},
}
```

The `build` step compiles a Swift daemon, installs a LaunchAgent, and starts the daemon automatically. (For other plugin managers, clone the repo into your Neovim packages and run `make` manually.)

On first install, grant Accessibility permissions to the daemon binary in **System Settings > Privacy & Security > Accessibility**, then restart it:

```sh
launchctl stop dev.tmm.ghostty-navigator && launchctl start dev.tmm.ghostty-navigator
```

## Requirements

- Neovim >= 0.9
- Ghostty >= 1.3.0 (macOS only, requires AppleScript support)
- Accessibility permissions for the background daemon (System Settings > Privacy & Security > Accessibility)

## How It Works

A Swift daemon intercepts `Ctrl+hjkl` at the OS level via a `CGEventTap` when Ghostty is the focused application. The Neovim plugin coordinates with the daemon using a flag file (`/tmp/ghostty-nvim-active`).

```
Press Ctrl+h (Ghostty is focused)
  └─ Swift daemon intercepts key
      ├─ nvim is active (flag file exists) → pass key through
      │   └─ Neovim handles it
      │       ├─ Another nvim split exists → wincmd navigates
      │       ├─ A keymap handles it (popup, etc.) → keymap runs
      │       └─ At edge, no keymap → osascript goto_split → Ghostty moves focus
      └─ shell is active (no flag file) → goto_split → Ghostty moves focus
```

Navigation works in normal mode and terminal mode (`:terminal` buffers).

## Configuration

Default options:

```lua
{
  -- Keymaps to set up. Keys are the lhs, values are the wincmd direction.
  keys = {
    ["<C-h>"] = "h",
    ["<C-j>"] = "j",
    ["<C-k>"] = "k",
    ["<C-l>"] = "l",
  },
}
```

## Health Check

Run `:checkhealth ghostty-navigator` to verify the daemon is installed, running, and permissions are granted.

## Troubleshooting

If the daemon isn't working, check its logs:

```sh
cat ~/.local/share/ghostty-navigator.nvim/stderr.log
```

## Uninstall

Removing the plugin from your Neovim config does not clean up the daemon. Run `:GhosttyNavigatorUninstall` in Neovim before removing the plugin, or run `make uninstall` from the plugin directory.

This stops the daemon, removes the LaunchAgent plist, and cleans up the binary and logs.

## License

MIT
