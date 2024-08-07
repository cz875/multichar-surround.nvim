local M = {}

---@class MulticharSurroundOpts
---@field prompt_text string
---An array of tuples; each tuple has two elements — the left delimiter and the right delimiter.
---For example: `{ { "(", ")" }, { "[", "]" }, { "{", "}" }, { "<", ">" } }`.
---@field matching_pairs [string, string][]

-- default config
---@type MulticharSurroundOpts
M.config_table = {
  prompt_text = "Edit right pair:",
  matching_pairs = {
    { "(", ")" }, { "[", "]" }, { "{", "}" }, { "<", ">" }
  },
}

---@param user_config_table MulticharSurroundOpts
M.make_config = function(user_config_table)
  user_config_table = user_config_table or {}
  M.config_table = vim.tbl_deep_extend("force", M.config_table, user_config_table)
end

return M
