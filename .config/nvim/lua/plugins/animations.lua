return {
  -- Animated "smear" cursor: trails smoothly when jumping, moving and typing
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    -- Ghostty draws its own cursor trail via shader
    cond = vim.env.TERM ~= "xterm-ghostty",
    opts = {
      smear_between_buffers = true,
      smear_between_neighbor_lines = true,
      smear_insert_mode = true,
      scroll_buffer_space = true,
      legacy_computing_symbols_support = false,
      -- snappier, less floaty trail
      stiffness = 0.8,
      trailing_stiffness = 0.6,
      distance_stop_animating = 0.5,
    },
  },

  -- Smooth scrolling (snacks ships with LazyVim)
  {
    "folke/snacks.nvim",
    opts = {
      scroll = { enabled = true },
    },
  },
}
