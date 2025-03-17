local M = {}
local logger
function M.info(msg)
  if not logger then
    pcall(function()
      logger = require('logger').derive('flygrep')
      logger.info(msg)
    end)
  else
    logger.info(msg)
  end
end

return M
