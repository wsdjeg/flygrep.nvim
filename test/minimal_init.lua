-- test/minimal_init.lua
-- Minimal Neovim configuration for testing

print('Initializing test environment...')

-- Set up essential settings
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = false
vim.opt.verbose = 1

-- Set up package path for:
-- 1. lua/?.lua - Main plugin source code
-- 2. test/?.lua - Mock modules (like job.lua)
-- 3. test/.deps/?.lua - Test dependencies (luaunit)
package.path = 'lua/?.lua;test/?.lua;test/.deps/?.lua;' .. package.path
vim.opt.runtimepath:prepend('.')

-- Create temporary test directory
local test_dir = vim.fn.tempname() .. '_flygrep_nvim_test'
vim.fn.mkdir(test_dir, 'p')

-- Load plugin with test configuration
local ok, err = pcall(function()
  require('flygrep').setup({
    timeout = 100,
    enable_preview = false,
  })
end)

if not ok then
  print('Error initializing test environment: ' .. err)
else
  print('Test environment initialized successfully')
  print('Test directory: ' .. test_dir)
end

