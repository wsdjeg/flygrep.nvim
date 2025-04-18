local M = {}
local util = require('flygrep.util')
function M.def_higroup(color_templete)
  vim.api.nvim_set_hl(0, 'FlyGrep_a', color_templete.a)
  vim.api.nvim_set_hl(0, 'FlyGrep_b', color_templete.b)
  util.hi_separator('FlyGrep_a', 'FlyGrep_b')
  util.hi_separator('FlyGrep_b', 'Normal')
end

return M
