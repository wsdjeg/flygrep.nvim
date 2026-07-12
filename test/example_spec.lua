local lu = require('luaunit')

-- Test the config module
local config = require('flygrep.config')

TestConfig = {}

function TestConfig:setUp()
  -- Reset to default config before each test
  self.default = config.setup()
end

function TestConfig:test_default_timeout()
  lu.assertEquals(self.default.timeout, 200)
end

function TestConfig:test_default_command_execute()
  lu.assertEquals(self.default.command.execute, 'rg')
end

function TestConfig:test_default_enable_preview()
  lu.assertEquals(self.default.enable_preview, false)
end

function TestConfig:test_setup_with_override()
  local cfg = config.setup({
    timeout = 500,
    enable_preview = true,
  })
  lu.assertEquals(cfg.timeout, 500)
  lu.assertEquals(cfg.enable_preview, true)
end

function TestConfig:test_setup_preserves_nested_defaults()
  local cfg = config.setup({})
  lu.assertEquals(cfg.mappings.next_item, '<Tab>')
  lu.assertEquals(cfg.mappings.open_item_edit, '<Enter>')
  lu.assertEquals(cfg.command.default_opts[1], '--no-heading')
end

function TestConfig:test_setup_merges_nested()
  local cfg = config.setup({
    mappings = {
      next_item = '<C-n>',
    },
  })
  lu.assertEquals(cfg.mappings.next_item, '<C-n>')
  -- other mappings should be preserved
  lu.assertEquals(cfg.mappings.previous_item, '<S-Tab>')
  lu.assertEquals(cfg.mappings.open_item_edit, '<Enter>')
end

function TestConfig:test_setup_with_nil()
  local cfg = config.setup(nil)
  lu.assertEquals(cfg.timeout, 200)
end

-- Test the util module
local util = require('flygrep.util')

TestUtil = {}

function TestUtil:test_group2dict_returns_table()
  local result = util.group2dict('Normal')
  lu.assertNotNil(result)
  lu.assertEquals(type(result), 'table')
end

function TestUtil:test_group2dict_invalid_name()
  local result = util.group2dict('NonExistentHighlightGroup12345')
  lu.assertEquals(result.name, '')
end

-- Test the logger module
local logger = require('flygrep.logger')

TestLogger = {}

function TestLogger:test_logger_has_methods()
  lu.assertEquals(type(logger.info), 'function')
  lu.assertEquals(type(logger.debug), 'function')
  lu.assertEquals(type(logger.warn), 'function')
  lu.assertEquals(type(logger.error), 'function')
end

function TestLogger:test_logger_info_no_error()
  -- Should not throw even when logger dependency is not available
  logger.info('test message')
  logger.debug('test debug')
  logger.warn('test warn')
  logger.error('test error')
end

-- Simple sanity test
TestExample = {}

function TestExample:test_arithmetic()
  lu.assertEquals(1 + 1, 2)
end

function TestExample:test_string_operations()
  lu.assertEquals(string.upper('hello'), 'HELLO')
  lu.assertEquals(string.len('flygrep'), 7)
end

return TestExample

