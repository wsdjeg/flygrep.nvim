--=============================================================================
-- flygrep.lua
-- Copyright 2025 Eric Wong
-- Author: Eric Wong < wsdjeg@outlook.com >
-- URL: https://spacevim.org
-- License: GPLv3
--=============================================================================

local M = {}
local conf = require('flygrep.config')
local job = require('spacevim.api.job')
local ok, cmp = pcall(require, 'cmp')
if not ok then
  vim.cmd('doautocmd InsertEnter')
  ok, cmp = pcall(require, 'cmp')
end

local grep_timer_id = -1
local grep_input = ''
local search_jobid = -1
local search_hi_id = -1
local fix_string = false

-- all buffers
local result_bufid = -1
local result_winid = -1
local prompt_bufid = -1
local prompt_winid = -1
local preview_winid = -1
local preview_bufid = -1
local preview_timer_id = -1

local prompt_count_id
local extns = vim.api.nvim_create_namespace('floatgrep_ext')

local function update_result_count()
  local count = vim.api.nvim_buf_line_count(result_bufid)
  local line = vim.api.nvim_win_get_cursor(result_winid)[1]
  prompt_count_id = vim.api.nvim_buf_set_extmark(prompt_bufid, extns, 0, 0, {
    id = prompt_count_id,
    virt_text = { { string.format('%d/%d', line, count), 'Comment' } },
    virt_text_pos = 'right_align',
  })
end

local function build_grep_command()
  local cmd = { conf.command.execute }
  for _, v in ipairs(conf.command.default_opts) do
    table.insert(cmd, v)
  end
  if fix_string then
    table.insert(cmd, conf.command.fixed_string_opt)
  else
    table.insert(cmd, conf.command.expr_opt)
  end
  table.insert(cmd, grep_input)
  table.insert(cmd, '.')
  return cmd
end

-- 搜索结果行转换成文件名、光标位置
local function get_file_pos(line)
  local filename = vim.fn.fnameescape(vim.fn.split(line, [[:\d\+:]])[1])
  local linenr = vim.fn.str2nr(string.sub(vim.fn.matchstr(line, [[:\d\+:]]), 2, -2))
  local colum = vim.fn.str2nr(string.sub(vim.fn.matchstr(line, [[\(:\d\+\)\@<=:\d\+:]]), 2, -2))
  return filename, linenr, colum
end
local function preview_timer(t)
  -- if preview win does exists, return
  if not vim.api.nvim_win_is_valid(preview_winid) then
    return
  end
  local cursor = vim.api.nvim_win_get_cursor(result_winid)
  local line = vim.api.nvim_buf_get_lines(result_bufid, cursor[1] - 1, cursor[1], false)[1]
  if line == '' then
    return
  end
  local filename, liner, colum = get_file_pos(line)
  vim.api.nvim_buf_set_lines(preview_bufid, 0, -1, false, vim.fn.readfile(filename, ''))
  local ft = vim.filetype.match({ filename = filename })
  if ft then
    vim.api.nvim_buf_set_option(preview_bufid, 'syntax', ft)
  else
    local ftdetect_autocmd = vim.api.nvim_get_autocmds({
      group = 'filetypedetect',
      event = 'BufRead',
      pattern = '*.' .. vim.fn.fnamemodify(filename, ':e'),
    })
    -- logger.info(vim.inspect(ftdetect_autocmd))
    if ftdetect_autocmd[1] then
      if
        ftdetect_autocmd[1].command and vim.startswith(ftdetect_autocmd[1].command, 'set filetype=')
      then
        ft = ftdetect_autocmd[1].command:gsub('set filetype=', '')
        vim.api.nvim_buf_set_option(preview_bufid, 'syntax', ft)
      end
    end
  end
  vim.api.nvim_win_set_cursor(preview_winid, { liner, colum })
end

local function grep_timer(t)
  vim.api.nvim_buf_set_lines(result_bufid, 0, -1, false, {})
  if prompt_count_id then
    pcall(vim.api.nvim_buf_del_extmark, prompt_bufid, extns, prompt_count_id)
    prompt_count_id = nil
  end
  search_jobid = job.start(build_grep_command(), {
    on_stdout = function(id, data)
      if
        id == search_jobid
        and vim.api.nvim_buf_is_valid(prompt_bufid)
        and vim.api.nvim_win_is_valid(prompt_winid)
      then
        if vim.fn.getbufline(result_bufid, 1)[1] == '' then
          vim.api.nvim_buf_set_lines(result_bufid, 0, -1, false, data)
          if conf.enable_preview then
            vim.fn.timer_stop(preview_timer_id)
            preview_timer_id = vim.fn.timer_start(500, preview_timer, { ['repeat'] = 1 })
          end
        else
          vim.api.nvim_buf_set_lines(result_bufid, -1, -1, false, data)
        end
        update_result_count()
      end
    end,
  })
end

local function build_prompt_title()
  local t = {}
  table.insert(t, { ' FlyGrep ', 'FlyGrep_a' })
  table.insert(t, { '', 'FlyGrep_a_FlyGrep_b' })
  if not fix_string then
    table.insert(t, { ' expr ', 'FlyGrep_b' })
  else
    table.insert(t, { ' string ', 'FlyGrep_b' })
  end
  table.insert(t, { '', 'FlyGrep_b' })
  table.insert(t, { ' ' .. vim.fn.getcwd() .. ' ', 'FlyGrep_b' })
  table.insert(t, { '', 'FlyGrep_b_Normal' })
  -- return {{}, {}, {}}
  return t
end

local function toggle_fix_string()
  fix_string = not fix_string
  vim.cmd('doautocmd TextChangedI')
  local conf = vim.api.nvim_win_get_config(prompt_winid)
  conf.title = build_prompt_title()
  vim.api.nvim_win_set_config(prompt_winid, conf)
end

local function toggle_preview_win()
  conf.enable_preview = not conf.enable_preview
  local screen_width = math.floor(vim.o.columns * 0.8)
  -- 起始位位置： lines * 10%, columns * 10%
  local start_col = math.floor(vim.o.columns * 0.1)
  local start_row = math.floor(vim.o.lines * 0.1)
  -- 整体高度：lines 的 80%
  local screen_height = math.floor(vim.o.lines * 0.8)
  if conf.enable_preview then
    if not vim.api.nvim_buf_is_valid(preview_bufid) then
      preview_bufid = vim.api.nvim_create_buf(false, true)
    end
    preview_winid = vim.api.nvim_open_win(preview_bufid, false, {
      relative = 'editor',
      width = screen_width,
      height = math.floor((screen_height - 5) / 2),
      col = start_col,
      row = start_row,
      focusable = false,
      border = 'rounded',
      -- title = 'Result',
      -- title_pos = 'center',
      -- noautocmd = true,
    })
    vim.api.nvim_set_option_value('cursorline', true, { win = preview_winid })
    local winopt = vim.api.nvim_win_get_config(result_winid)
    winopt.row = start_row + math.floor((screen_height - 5) / 2) + 2
    winopt.height = screen_height - 5 - math.floor((screen_height - 5) / 2) - 2
    vim.api.nvim_win_set_config(result_winid, winopt)
    vim.fn.timer_stop(preview_timer_id)
    preview_timer_id = vim.fn.timer_start(500, preview_timer, { ['repeat'] = 1 })
  else
    vim.api.nvim_win_close(preview_winid, true)
    local winopt = vim.api.nvim_win_get_config(result_winid)
    winopt.row = start_row
    winopt.height = screen_height - 5
    vim.api.nvim_win_set_config(result_winid, winopt)
  end
end

local function open_win()
  require('flygrep.highlight').def_higroup()
  -- 窗口位置
  -- 宽度： columns 的 80%
  local screen_width = math.floor(vim.o.columns * 0.8)
  -- 起始位位置： lines * 10%, columns * 10%
  local start_col = math.floor(vim.o.columns * 0.1)
  local start_row = math.floor(vim.o.lines * 0.1)
  -- 整体高度：lines 的 80%
  local screen_height = math.floor(vim.o.lines * 0.8)

  prompt_bufid = vim.api.nvim_create_buf(false, true)
  prompt_winid = vim.api.nvim_open_win(prompt_bufid, true, {
    relative = 'editor',
    width = screen_width,
    height = 1,
    col = start_col,
    row = start_row + screen_height - 3,
    focusable = true,
    border = 'rounded',
    title = build_prompt_title(),
    title_pos = 'left',
    -- noautocmd = true,
  })

  vim.api.nvim_set_option_value(
    'winhighlight',
    'NormalFloat:Normal,FloatBorder:WinSeparator',
    { win = prompt_winid }
  )
  vim.api.nvim_set_option_value('number', false, { win = prompt_winid })
  vim.api.nvim_set_option_value('relativenumber', false, { win = prompt_winid })
  vim.api.nvim_set_option_value('cursorline', false, { win = prompt_winid })
  vim.api.nvim_set_option_value('signcolumn', 'yes', { win = prompt_winid })
  vim.api.nvim_buf_set_extmark(prompt_bufid, extns, 0, 0, {
    sign_text = '>',
    sign_hl_group = 'Error',
  })

  if conf.enable_preview then
    if not vim.api.nvim_buf_is_valid(preview_bufid) then
      preview_bufid = vim.api.nvim_create_buf(false, true)
    end
    preview_winid = vim.api.nvim_open_win(preview_bufid, false, {
      relative = 'editor',
      width = screen_width,
      height = math.floor((screen_height - 5) / 2),
      col = start_col,
      row = start_row,
      focusable = false,
      border = 'rounded',
      -- title = 'Result',
      -- title_pos = 'center',
      -- noautocmd = true,
    })
    vim.api.nvim_set_option_value('cursorline', true, { win = preview_winid })
    result_bufid = vim.api.nvim_create_buf(false, true)
    result_winid = vim.api.nvim_open_win(result_bufid, false, {
      relative = 'editor',
      width = screen_width,
      height = screen_height - 5 - math.floor((screen_height - 5) / 2) - 2,
      col = start_col,
      row = start_row + math.floor((screen_height - 5) / 2) + 2,
      focusable = false,
      border = 'rounded',
      -- title = 'Result',
      -- title_pos = 'center',
      -- noautocmd = true,
    })
  else
    result_bufid = vim.api.nvim_create_buf(false, true)
    result_winid = vim.api.nvim_open_win(result_bufid, false, {
      relative = 'editor',
      width = screen_width,
      height = screen_height - 5,
      col = start_col,
      row = start_row,
      focusable = false,
      border = 'rounded',
      -- title = 'Result',
      -- title_pos = 'center',
      -- noautocmd = true,
    })
  end
  vim.api.nvim_set_option_value(
    'winhighlight',
    'NormalFloat:Normal,FloatBorder:WinSeparator',
    { win = result_winid }
  )
  vim.api.nvim_set_option_value('cursorline', true, { win = result_winid })
  cmp.setup.buffer({
    completion = {
      autocomplete = false,
    },
  })
  vim.cmd('noautocmd startinsert')

  local augroup = vim.api.nvim_create_augroup('floatgrep', {
    clear = true,
  })

  vim.api.nvim_create_autocmd({ 'TextChangedI' }, {
    group = augroup,
    buffer = prompt_bufid,
    callback = function(ev)
      grep_input = vim.api.nvim_buf_get_lines(prompt_bufid, 0, 1, false)[1]
      if grep_input ~= '' then
        pcall(vim.fn.matchdelete, search_hi_id, result_winid)
        pcall(vim.fn.timer_stop, grep_timer_id)
        search_hi_id =
          vim.fn.matchadd(conf.matched_higroup, grep_input, 10, -1, { window = result_winid })
        grep_timer_id = vim.fn.timer_start(conf.timeout, grep_timer, { ['repeat'] = 1 })
      else
        pcall(vim.fn.matchdelete, search_hi_id, result_winid)
        pcall(vim.fn.timer_stop, grep_timer_id)
        job.stop(search_jobid)
        search_jobid = 0
        vim.api.nvim_buf_set_lines(result_bufid, 0, -1, false, {})
        if conf.enable_preview and vim.api.nvim_buf_is_valid(preview_bufid) then
          vim.api.nvim_buf_set_lines(preview_bufid, 0, -1, false, {})
        end
      end
    end,
  })

  -- 使用 Esc/C-c 关闭整个界面
  for _, k in ipairs({ '<Esc>', '<C-c>' }) do
    vim.keymap.set('i', k, function()
      vim.cmd('noautocmd stopinsert')
      vim.api.nvim_win_close(prompt_winid, true)
      vim.api.nvim_buf_set_lines(prompt_bufid, 0, -1, false, {})
      vim.api.nvim_win_close(result_winid, true)
      vim.api.nvim_buf_set_lines(result_bufid, 0, -1, false, {})
      if conf.enable_preview then
        vim.api.nvim_win_close(preview_winid, true)
        vim.api.nvim_buf_set_lines(preview_bufid, 0, -1, false, {})
      end
    end, { buffer = prompt_bufid })
  end

  -- 使用回车键打开光标所在的搜索结果，同时关闭界面
  local function open_item(cmd)
    vim.cmd('noautocmd stopinsert')
    -- 获取搜索结果光表行
    local line_number = vim.api.nvim_win_get_cursor(result_winid)[1]
    local filename, linenr, colum =
      get_file_pos(vim.api.nvim_buf_get_lines(result_bufid, line_number - 1, line_number, false)[1])
    vim.api.nvim_win_close(prompt_winid, true)
    vim.api.nvim_buf_set_lines(prompt_bufid, 0, -1, false, {})
    vim.api.nvim_win_close(result_winid, true)
    vim.api.nvim_buf_set_lines(result_bufid, 0, -1, false, {})
    if conf.enable_preview then
      vim.api.nvim_win_close(preview_winid, true)
      vim.api.nvim_buf_set_lines(preview_bufid, 0, -1, false, {})
    end
    vim.cmd(cmd .. ' ' .. filename)
    vim.api.nvim_win_set_cursor(0, { linenr, colum })
  end
  vim.keymap.set('i', '<Enter>', function()
    open_item('edit')
  end, { buffer = prompt_bufid })
  vim.keymap.set('i', '<C-v>', function()
    open_item('vsplit')
  end, { buffer = prompt_bufid })
  vim.keymap.set('i', '<C-s>', function()
    open_item('split')
  end, { buffer = prompt_bufid })
  vim.keymap.set('i', '<C-t>', function()
    open_item('tabedit')
  end, { buffer = prompt_bufid })

  -- 避免使用 jk 切换到 normal 模式
  -- https://github.com/neovim/neovim/discussions/32208
  -- vim.keymap.del('i', 'jk', {buffer = prompt_bufid})
  if vim.fn.hasmapto('j', 'i') == 1 then
    vim.keymap.set('i', 'j', 'j', {
      nowait = true,
      buffer = prompt_bufid,
    })
  end

  -- 使用 Tab/Shift-Tab 上下移动搜素结果
  vim.keymap.set('i', '<Tab>', function()
    local line_number = vim.api.nvim_win_get_cursor(result_winid)[1]
    if line_number == vim.api.nvim_buf_line_count(result_bufid) then
      pcall(vim.api.nvim_win_set_cursor, result_winid, { 1, 0 })
    else
      pcall(vim.api.nvim_win_set_cursor, result_winid, { line_number + 1, 0 })
    end
    if conf.enable_preview then
      vim.fn.timer_stop(preview_timer_id)
      preview_timer_id = vim.fn.timer_start(500, preview_timer, { ['repeat'] = 1 })
    end
    update_result_count()
  end, { buffer = prompt_bufid })

  vim.keymap.set('i', '<S-Tab>', function()
    local line_number = vim.api.nvim_win_get_cursor(result_winid)[1]
    if line_number == 1 then
      pcall(
        vim.api.nvim_win_set_cursor,
        result_winid,
        { vim.api.nvim_buf_line_count(result_bufid), 0 }
      )
    else
      pcall(vim.api.nvim_win_set_cursor, result_winid, { line_number - 1, 0 })
    end
    if conf.enable_preview then
      vim.fn.timer_stop(preview_timer_id)
      preview_timer_id = vim.fn.timer_start(500, preview_timer, { ['repeat'] = 1 })
    end
    update_result_count()
  end, { buffer = prompt_bufid })
  vim.keymap.set('i', '<C-e>', function()
    toggle_fix_string()
    update_result_count()
  end, { buffer = prompt_bufid })
  vim.keymap.set('i', '<C-p>', function()
    toggle_preview_win()
  end, { buffer = prompt_bufid })

  -- 高亮文件名及位置
  vim.fn.matchadd(
    'Comment',
    [[\([A-Z]:\)\?[^:]*:\d\+:\(\d\+:\)\?]],
    11,
    -1,
    { window = result_winid }
  )
end

function M.open()
  open_win()
end

function M.setup(conf)
  require('flygrep.config').setup(conf)
end

return M
