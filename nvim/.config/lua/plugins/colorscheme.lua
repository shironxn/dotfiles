return {
  -- pywal colorscheme for LazyVim
  -- loads ~/.cache/wal/colors.json for wallpaper-synced colors
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "pywal",
    },
  },
  -- re-apply pywal when a plugin triggers ColorScheme event
  {
    "nvim-lua/plenary.nvim",
    -- dummy dependency; config is the hook
    config = function()
      local group = vim.api.nvim_create_augroup("pywal_reload", { clear = true })

      -- reload pywal colors without restart
      vim.api.nvim_create_user_command("Pywal", function()
        vim.cmd.colorscheme("pywal")
        vim.notify("pywal reloaded", vim.log.levels.INFO)
      end, {})

      vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = function()
          if vim.g.colors_name ~= "pywal" then
            vim.cmd.colorscheme("pywal")
          end
        end,
      })
    end,
  },
}
