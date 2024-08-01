local util = require("util")
local config = require("config")

local M = {}

M.setup = config.make_config

M.do_surround = function()
  local buf = vim.api.nvim_get_current_buf()

  local cursor_pos = util.to_pos(vim.fn.getpos("."))
  local visual_pos = util.to_pos(vim.fn.getpos("v"))

  local begin_pos
  local end_pos

  if util.check_pos1_is_first(cursor_pos, visual_pos) then
    begin_pos = cursor_pos
    end_pos = visual_pos
  else
    begin_pos = visual_pos
    end_pos = cursor_pos
  end

  -- accounting for the mismatch of cursor position vs selection region in linewise mode
  if vim.api.nvim_get_mode().mode == "V" then
    begin_pos.col = 1
    end_pos.col = util.get_line_length(buf, end_pos.row)
  end

  -- note: unlike most of the rest of this function, vim api positions are 0-indexed
  local lines = vim.api.nvim_buf_get_lines(buf, begin_pos.row-1, end_pos.row, true)

  local num_surrounding_layers = util.find_num_surrounding_layers(lines[1], begin_pos, lines[#lines], end_pos)

  local left_pair_col_range = {
    from = begin_pos.col,
    to = begin_pos.col + (num_surrounding_layers - 1),
  }

  local right_pair_col_range = {
    from = end_pos.col - (num_surrounding_layers - 1),
    to = end_pos.col,
  }

  local namespace = vim.api.nvim_create_namespace("surround_hl")
  vim.api.nvim_buf_add_highlight(buf, namespace, "Cursor", begin_pos.row-1, left_pair_col_range.from-1, left_pair_col_range.to)
  vim.api.nvim_buf_add_highlight(buf, namespace, "Cursor", end_pos.row-1, right_pair_col_range.from-1, right_pair_col_range.to)
  vim.cmd.redraw()

  local right_pair = lines[#lines]:sub(right_pair_col_range.from, right_pair_col_range.to)
  local input = vim.fn.input({ prompt = config.config_table.prompt_text, default = right_pair, cancelreturn = right_pair })

  local new_right_pair = input
  local new_left_pair = util.get_reversed_string(input)

  local new_left_pair_col = begin_pos.col
  lines[1] = util.string_remove_and_insert(lines[1], new_left_pair_col, num_surrounding_layers, new_left_pair)

  local new_right_pair_col = end_pos.col - (num_surrounding_layers - 1)
  if begin_pos.row == end_pos.row then
    new_right_pair_col = new_right_pair_col - num_surrounding_layers + #new_right_pair
  end
  lines[#lines] = util.string_remove_and_insert(lines[#lines], new_right_pair_col, num_surrounding_layers, new_right_pair)

  vim.api.nvim_buf_set_lines(buf, begin_pos.row-1, end_pos.row, true, lines)

  vim.api.nvim_buf_clear_namespace(buf, vim.api.nvim_get_namespaces()["surround_hl"], 0, -1)

  vim.api.nvim_input("<esc>")
end

return M
