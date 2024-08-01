local config = require("config")

local M = {}

-- examples:
-- a -> a
-- { -> }
-- ) -> (
M.get_matching_char = function(input_char)
  for _,pair in ipairs(config.config_table.matching_pairs) do
    local left_char = pair[1]
    local right_char = pair[2]

    if left_char == input_char then
      return right_char
    end

    if right_char == input_char then
      return left_char
    end
  end

  return input_char
end

-- examples:
-- b) -> (b
-- [( -> )]
M.get_reversed_string = function(input_string)
  local output = ""

  for char in input_string:gmatch(".") do
    output = M.get_matching_char(char)..output
  end

  return output
end

-- takes a string and an index
-- returns the char at that index
local function get_char(str, index)
  return str:sub(index, index)
end

-- takes 2 positions representing the beginning and end of a selected region
-- along with the line in the buffer where each of those positions are
--
-- returns the number of matching character pairs surrounding the selection
--
-- example (start/end of selection marked by '|' ):
--   begin_line: |{{this is the first line
--   end_line: this is the last line}}|
--      --> returns 2
M.find_num_surrounding_layers = function(begin_line, begin_pos, end_line, end_pos)
  local i = 0
  while true do
    local begin_char = get_char(begin_line, begin_pos.col + i)
    local end_char = get_char(end_line, end_pos.col - i)

    local bool_colliding = (begin_pos.row == end_pos.row) and ((begin_pos.col + i) >= (end_pos.col - i))
    local bool_out_of_bounds = ((begin_pos.col + i) > #begin_line) and ((end_pos.col - i) < 1)
    local bool_not_matching = begin_char ~= M.get_matching_char(end_char)
    if bool_colliding or bool_not_matching or bool_out_of_bounds then
      break
    end

    i = i + 1
  end

  return i
end

-- given a buffer id number and row number, get the length of the line
M.get_line_length = function(buf, row_index)
  local line = vim.api.nvim_buf_get_lines(buf, row_index-1, row_index, true)[1]
  return #line
end

-- convert getpos() positions to more convenient tables
M.to_pos = function(tuple)
  return {
    ["row"] = tuple[2],
    ["col"] = tuple[3],
  }
end

-- given two positions, check if the first argument is first in the buffer
M.check_pos1_is_first = function(pos1, pos2)
  if pos1.row == pos2.row then
    return pos1.col < pos2.col
  else
    return pos1.row < pos2.row
  end
end

-- given a string, index, length, and insertion string:
-- 1. delete characters from the index -> index + length
-- 2. insert the new insertion string at index
M.string_remove_and_insert = function(str, start_index, length, insert_str)
  return str:sub(0, start_index-1)..insert_str..str:sub(start_index + length)
end

return M
