---@alias MarkPosition [integer, integer]

---@class MarkRange
---@field from MarkPosition
---@field to MarkPosition

local multichar_surround = {}
local H = {}

---@param config MulticharSurroundOpts?
multichar_surround.setup = function(config)
  _G.MulticharSurround = multichar_surround

  H.config = vim.tbl_deep_extend("force", H.config, config or {})
end

multichar_surround.do_surround = function()
  local buf = vim.api.nvim_get_current_buf()

  ---Wrapper around getpos that returns a row, col tuple with mark-like (0,1) indexing
  ---(see :h api-indexing)
  ---@param expr string
  ---@return MarkPosition
  local function getpos(expr)
    local _, row, col, _ = unpack(vim.fn.getpos(expr))
    if row == nil or col == nil then
      error("vim.fn.getpos(\""..expr.."\") returned nil")
    end
    return {row, col-1}
  end

  local cursor_pos = getpos(".")
  local vis_pos = getpos("v")
  local begin_pos, end_pos = unpack(H.sort_pos(cursor_pos, vis_pos))

  local begin_line = H.buf_get_line(buf, begin_pos[1])
  local end_line = H.buf_get_line(buf, end_pos[1])

  -- Accounting for the mismatch of cursor position vs selection region in linewise visual mode
  -- Uses (0,1) indexing
  if vim.api.nvim_get_mode().mode == "V" then
    begin_pos[2] = 0
    end_pos[2] = #end_line-1
  end

  -- Get inclusive ranges for the left and right clusters of surrounding pairs
  local num_surrounding_chars = H.find_num_surrounding_chars(buf, begin_pos, end_pos)

  ---@type MarkRange
  local begin_range = {
    from = begin_pos,
    to = H.pos_apply_offset(begin_pos, {0, (num_surrounding_chars-1)}),
  }

  ---@type MarkRange
  local end_range = {
    from = H.pos_apply_offset(end_pos, {0, -(num_surrounding_chars-1)}),
    to = end_pos,
  }

  ---@type MarkRange
  local cursor_range = {
    from = cursor_pos,
    to = cursor_pos,
  }

  -- Set highlights on the ranges
  local namespace = vim.api.nvim_create_namespace("surround_hl")
  H.buf_set_hl_range(buf, namespace, H.config.hl_group, begin_range)
  H.buf_set_hl_range(buf, namespace, H.config.hl_group, end_range)
  H.buf_set_hl_range(buf, namespace, "TermCursor", cursor_range)
  vim.cmd.redraw()

  local end_pair = H.line_get_range(end_line, end_range)

  -- Let the user edit the right pair and calculate a mirrored left pair
  local end_pair_new = vim.fn.input({
    prompt = H.config.prompt_text,
    default = end_pair,
    cancelreturn = end_pair,
  })
  local begin_pair_new = H.get_reversed_string(end_pair_new)

  -- Case where the surrounding pairs are on different lines
  if begin_pos[1] ~= end_pos[1] then
    -- Apply changes to the left pair line in the buffer
    local begin_line_new = H.line_replace_range(begin_line, begin_range, begin_pair_new)
    H.buf_set_line(buf, begin_pos[1], begin_line_new)

    -- Apply changes to the right pair line in the buffer
    local end_line_new = H.line_replace_range(end_line, end_range, end_pair_new)
    H.buf_set_line(buf, end_pos[1], end_line_new)

  -- Case where the surrounding pairs are on the same line
  else
    -- Apply changes to the left pair, don't set in buffer
    local begin_line_new = H.line_replace_range(begin_line, begin_range, begin_pair_new)

    -- Account for the shift in indices caused by editing the left pair
    local col_offset = #end_pair_new - #end_pair
    local end_range_new = {
      from = H.pos_apply_offset(end_range.from, {0, col_offset}),
      to = H.pos_apply_offset(end_range.to, {0, col_offset}),
    }

    -- Apply changes to the right pair and set in buffer
    local final_line = H.line_replace_range(begin_line_new, end_range_new, end_pair_new)
    H.buf_set_line(buf, begin_pos[1], final_line)
  end

  -- Clear highlights
  vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)

  -- Leave visual mode
  vim.api.nvim_feedkeys('\027', 'xt', false)
end

---@class MulticharSurroundOpts
---@field prompt_text string
---@field hl_group string
---An array of tuples; each tuple has two elements — the begin delimiter and the end delimiter.
---For example: `{ { "(", ")" }, { "[", "]" }, { "{", "}" }, { "<", ">" } }`.
---@field matching_pairs [string, string][]

-- default config
---@type MulticharSurroundOpts
H.config = {
  prompt_text = "Edit right pair:",
  hl_group = "MatchParen",
  matching_pairs = {
    { "(", ")" }, { "[", "]" }, { "{", "}" }, { "<", ">" }
  },
}

---examples:
---a -> a
---{ -> }
---) -> (
---@param input_char string
---@return string
H.get_matching_char = function(input_char)
  for _, pair in pairs(H.config.matching_pairs) do
    local begin_char, end_char = unpack(pair)
    if begin_char == input_char then return end_char end
    if end_char == input_char then return begin_char end
  end

  return input_char
end

---examples:
---b) -> (b
---[( -> )]
---@param input_string string
---@return string
H.get_reversed_string = function(input_string)
  return vim.iter(vim.split(input_string, ""))
    :map(H.get_matching_char)
    :rev()
    :join("")
end

---str[index]
---@param str string
---@param index integer
---@return string
H.get_char_at = function(str, index)
  return string.sub(str, index, index)
end

---Returns the number of surrounding pairs in buf from begin_pos to end_pos
---
---example (start/end of selection marked by '|' ):
---  begin_line: |{{this is the first line
---  end_line: this is the last line}}|
---     --> returns 2
---@param buf integer
---@param begin_pos MarkPosition
---@param end_pos MarkPosition
---@return integer
H.find_num_surrounding_chars = function(buf, begin_pos, end_pos)
  local begin_line = H.buf_get_line(buf, begin_pos[1])
  local end_line = H.buf_get_line(buf, end_pos[1])
  local bool_same_line = (begin_pos[1] == end_pos[1])

  local i = 0 -- Offset as loop "closes in" on the center of the surrounded region
  local begin_col_initial = begin_pos[2]+1 -- 1-based
  local begin_col_max = #begin_line
  local end_col_initial = end_pos[2]+1 -- 1-based
  local end_col_min = 1
  while true do
    local begin_col_cur = begin_col_initial + i
    local end_col_cur = end_col_initial - i

    local begin_char = H.get_char_at(begin_line, begin_col_cur)
    local end_char = H.get_char_at(end_line, end_col_cur)

    local bool_colliding = (bool_same_line) and (begin_col_cur >= end_col_cur)
    local bool_out_of_bounds = (begin_col_cur > begin_col_max) or (end_col_cur < end_col_min)
    local bool_not_matching = (begin_char ~= H.get_matching_char(end_char))

    if bool_colliding or bool_out_of_bounds or bool_not_matching then
      break
    end

    i = i + 1
  end

  return i
end

---@param buf integer
---@param namespace integer
---@param hl_group string
---@param range MarkRange
H.buf_set_hl_range = function(buf, namespace, hl_group, range)
  -- Decrement rows in accordance with the (0,0) indexing that vim.hl.range uses
  local hl_range = {
    from = H.pos_apply_offset(range.from, {-1, 0}),
    to = H.pos_apply_offset(range.to, {-1, 0}),
  }
  vim.hl.range(
    buf,
    namespace,
    hl_group,
    hl_range.from,
    hl_range.to,
    { inclusive = true }
  )
end

---@param pos1 MarkPosition
---@param pos2 MarkPosition
---@return [MarkPosition, MarkPosition]
H.sort_pos = function (pos1, pos2)
  local bool_pos1_is_first = (pos1[1] == pos2[1])
    and pos1[2] < pos2[2]
    or  pos1[1] < pos2[1]

  return bool_pos1_is_first
    and {pos1, pos2}
    or  {pos2, pos1}
end

---@param buf integer
---@param row_num integer
---@return string
H.buf_get_line = function(buf, row_num)
  return vim.api.nvim_buf_get_lines(buf, row_num-1, row_num, true)[1]
end

---@param buf integer
---@param row_num integer
---@param str string
H.buf_set_line = function(buf, row_num, str)
  vim.api.nvim_buf_set_lines(buf, row_num-1, row_num, true, {str})
end

---@param base_str string
---@param range MarkRange
---@param insert_str string
---@return string
H.line_replace_range = function(base_str, range, insert_str)
  local from_col_index = range.from[2]+1
  local to_col_index = range.to[2]+1
  return
      string.sub(base_str, 1, from_col_index-1)
    ..insert_str
    ..string.sub(base_str, to_col_index+1)
end

---@param str string
---@param range MarkRange
---@return string
H.line_get_range = function(str, range)
  local from_col_index = range.from[2]+1
  local to_col_index = range.to[2]+1
  return string.sub(str, from_col_index, to_col_index)
end

---@param pos MarkPosition
---@param offset MarkPosition
---@return MarkPosition
H.pos_apply_offset = function(pos, offset)
  return {
    pos[1] + offset[1],
    pos[2] + offset[2],
  }
end

---@return MarkPosition
H.get_cursor = function()
  local _, row, col, _ = vim.fn.getpos(".")
  return {row, col}
end

-- return multichar_surround
vim.keymap.set("x", "S", function()
  multichar_surround.do_surround()
end)
