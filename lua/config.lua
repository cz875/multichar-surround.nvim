local M = {}

-- default config
M.config_table = {
  prompt_text = "Edit right pair:",
  matching_pairs = {
    { "(", ")" }, { "[", "]" }, { "{", "}" }, { "<", ">" }
  },
}

M.make_config = function(user_config_table)
  user_config_table = user_config_table or {}
  M.config_table = vim.tbl_deep_extend("force", M.config_table, user_config_table)
end

return M
