return {
  "404pilo/aicommits.nvim",
  config = function()
    require("aicommits").setup({
      active_provider = "gemini-api",
      providers = {
        ["gemini-api"] = {
          enabled = true,
          model = "gemini-2.5-flash", -- Latest Gemini model
          max_length = 50,
          generate = 3, -- Generate 1-8 commit message options
          temperature = 0.7,
          max_tokens = 200,
          thinking_budget = 0, -- 0 = disabled (default, faster/cheaper), -1 = dynamic, 1-24576 = manual
        },
      },
    })
  end,
}
