--=============================================================================
-- flygrep.lua
-- Copyright 2025 Eric Wong
-- Author: Eric Wong < wsdjeg@outlook.com >
-- URL: https://spacevim.org
-- License: GPLv3
--=============================================================================

local M = {}

-- setup done?
local setup_done = false

local config
local job = require('job')
local ok, cmp = pcall(require, 'cmp')
if not ok then
    vim.cmd('doautocmd InsertEnter')
    ok, cmp = pcall(require, 'cmp')
end

local log = require('flygrep.logger')

local grep_root_dir = '.'

local grep_timer_id = -1
local grep_input = ''
local search_jobid = 0
local search_hi_id = -1
local fix_string = false
local include_hidden_file = false

local saved_mouse_opt = ''

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
    return prompt_count_id
end

local function build_grep_command()
    local cmd = { config.command.execute }
    for _, v in ipairs(config.command.default_opts) do
        table.insert(cmd, v)
    end
    if include_hidden_file then
        table.insert(cmd, config.command.hidden_opt)
    end
    if fix_string then
        table.insert(cmd, config.command.fixed_string_opt)
    else
        table.insert(cmd, config.command.expr_opt)
    end
    table.insert(cmd, grep_input)
    table.insert(cmd, '.')
    return cmd
end

-- 搜索结果行转换成文件名、光标位置
local function get_file_pos(line)
    local filename = vim.fn.fnamemodify(vim.fn.fnameescape(vim.fn.split(line, [[:\d\+:]])[1]), ':p')
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
                ftdetect_autocmd[1].command
                and vim.startswith(ftdetect_autocmd[1].command, 'set filetype=')
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
        prompt_count_id = update_result_count()
    end
    local cmd = build_grep_command()
    log.debug('cmd is:' .. vim.inspect(cmd))
    search_jobid = job.start(cmd, {
        on_stdout = function(id, data)
            if
                id == search_jobid
                and vim.api.nvim_buf_is_valid(prompt_bufid)
                and vim.api.nvim_win_is_valid(prompt_winid)
            then
                if vim.fn.getbufline(result_bufid, 1)[1] == '' then
                    vim.api.nvim_buf_set_lines(result_bufid, 0, -1, false, data)
                    if config.enable_preview then
                        vim.fn.timer_stop(preview_timer_id)
                        preview_timer_id =
                            vim.fn.timer_start(500, preview_timer, { ['repeat'] = 1 })
                    end
                else
                    vim.api.nvim_buf_set_lines(result_bufid, -1, -1, false, data)
                end
                update_result_count()
            end
        end,
        cwd = grep_root_dir,
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
    table.insert(t, { ' ' .. grep_root_dir .. ' ', 'FlyGrep_b' })
    table.insert(t, { '', 'FlyGrep_b_Normal' })
    -- return {{}, {}, {}}
    return t
end

local function toggle_hidden_file()
    include_hidden_file = not include_hidden_file
    vim.cmd('doautocmd TextChangedI')
end
local function apply_to_quickfix()
    vim.cmd('noautocmd stopinsert')
    local searching_result = vim.api.nvim_buf_get_lines(result_bufid, 0, -1, false)
    local searching_partten = vim.api.nvim_buf_get_lines(prompt_bufid, 0, -1, false)[1] or ''
    vim.api.nvim_win_close(prompt_winid, true)
    vim.api.nvim_buf_set_lines(prompt_bufid, 0, -1, false, {})
    vim.api.nvim_win_close(result_winid, true)
    vim.api.nvim_buf_set_lines(result_bufid, 0, -1, false, {})
    if config.enable_preview then
        vim.api.nvim_win_close(preview_winid, true)
        vim.api.nvim_buf_set_lines(preview_bufid, 0, -1, false, {})
    end
    vim.o.mouse = saved_mouse_opt
    vim.fn.setqflist({}, 'r', {
        title = 'flygrep partten:' .. searching_partten,
        lines = searching_result,
    })
    vim.cmd('botright copen')
end

local function toggle_fix_string()
    fix_string = not fix_string
    vim.cmd('doautocmd TextChangedI')
    local win_conf = vim.api.nvim_win_get_config(prompt_winid)
    win_conf.title = build_prompt_title()
    vim.api.nvim_win_set_config(prompt_winid, win_conf)
end

local function toggle_preview_win()
    config.enable_preview = not config.enable_preview
    local screen_width = math.floor(vim.o.columns * config.window.width)
    -- 起始位位置： lines * 10%, columns * 10%
    local start_col = math.floor(vim.o.columns * config.window.col)
    local start_row = math.floor(vim.o.lines * config.window.row)
    -- 整体高度：lines 的 80%
    local screen_height = math.floor(vim.o.lines * config.window.height)
    if config.enable_preview then
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

local function next_item()
    local line_number = vim.api.nvim_win_get_cursor(result_winid)[1]
    if line_number == vim.api.nvim_buf_line_count(result_bufid) then
        pcall(vim.api.nvim_win_set_cursor, result_winid, { 1, 0 })
    else
        pcall(vim.api.nvim_win_set_cursor, result_winid, { line_number + 1, 0 })
    end
    if config.enable_preview then
        vim.fn.timer_stop(preview_timer_id)
        preview_timer_id = vim.fn.timer_start(500, preview_timer, { ['repeat'] = 1 })
    end
    update_result_count()
end

local function previous_item()
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
    if config.enable_preview then
        vim.fn.timer_stop(preview_timer_id)
        preview_timer_id = vim.fn.timer_start(500, preview_timer, { ['repeat'] = 1 })
    end
    update_result_count()
end

local function open_win()
    require('flygrep.highlight').def_higroup(config.color_templete)
    -- 窗口位置
    -- 宽度： columns 的 80%
    local screen_width = math.floor(vim.o.columns * config.window.width)
    -- 起始位位置： lines * 10%, columns * 10%
    local start_col = math.floor(vim.o.columns * config.window.col)
    local start_row = math.floor(vim.o.lines * config.window.row)
    -- 整体高度：lines 的 80%
    local screen_height = math.floor(vim.o.lines * config.window.height)

    prompt_bufid = vim.api.nvim_create_buf(false, true)
    vim.b[prompt_bufid].completion = false -- https://github.com/Saghen/blink.cmp/commit/79545c371ab08cf4563fffb9f5c7a7c9e8fbc786
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

    if config.enable_preview then
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
    vim.api.nvim_set_option_value('cursorlineopt', 'both', { win = result_winid })
    if ok then
        cmp.setup.buffer({
            completion = {
                autocomplete = false,
            },
        })
    end
    if grep_root_dir ~= vim.fn.getcwd() then
        vim.cmd('cd ' .. grep_root_dir)
    end
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
                pcall(job.stop, search_jobid)
                search_hi_id = pcall(
                    vim.fn.matchadd,
                    config.matched_higroup,
                    grep_input:gsub('~', '\\~'),
                    10,
                    -1,
                    { window = result_winid }
                )
                grep_timer_id = vim.fn.timer_start(config.timeout, grep_timer, { ['repeat'] = 1 })
            else
                pcall(vim.fn.matchdelete, search_hi_id, result_winid)
                pcall(vim.fn.timer_stop, grep_timer_id)
                job.stop(search_jobid)
                search_jobid = 0
                vim.api.nvim_buf_set_lines(result_bufid, 0, -1, false, {})
                if config.enable_preview and vim.api.nvim_buf_is_valid(preview_bufid) then
                    vim.api.nvim_buf_set_lines(preview_bufid, 0, -1, false, {})
                end
            end
            update_result_count()
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
            if config.enable_preview then
                vim.api.nvim_win_close(preview_winid, true)
                vim.api.nvim_buf_set_lines(preview_bufid, 0, -1, false, {})
            end
            vim.o.mouse = saved_mouse_opt
        end, { buffer = prompt_bufid })
    end

    -- 使用回车键打开光标所在的搜索结果，同时关闭界面
    local function open_item(cmd)
        vim.cmd('noautocmd stopinsert')
        -- 获取搜索结果光表行
        local line_number = vim.api.nvim_win_get_cursor(result_winid)[1]
        local filename, linenr, colum = get_file_pos(
            vim.api.nvim_buf_get_lines(result_bufid, line_number - 1, line_number, false)[1]
        )
        if not filename or not linenr or not colum then
            return
        end
        vim.api.nvim_win_close(prompt_winid, true)
        vim.api.nvim_buf_set_lines(prompt_bufid, 0, -1, false, {})
        vim.api.nvim_win_close(result_winid, true)
        vim.api.nvim_buf_set_lines(result_bufid, 0, -1, false, {})
        if config.enable_preview then
            vim.api.nvim_win_close(preview_winid, true)
            vim.api.nvim_buf_set_lines(preview_bufid, 0, -1, false, {})
        end
        vim.cmd(cmd .. ' ' .. filename)
        vim.api.nvim_win_set_cursor(0, { linenr, colum })
        vim.o.mouse = saved_mouse_opt
    end
    vim.keymap.set('i', config.mappings.open_item_edit, function()
        open_item('edit')
    end, { buffer = prompt_bufid })
    vim.keymap.set('i', config.mappings.open_item_vsplit, function()
        open_item('vsplit')
    end, { buffer = prompt_bufid })
    vim.keymap.set('i', config.mappings.open_item_split, function()
        open_item('split')
    end, { buffer = prompt_bufid })
    vim.keymap.set('i', config.mappings.open_item_tabedit, function()
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

    -- 使用 Tab/Shift-Tab and Ctrl-jk 上下移动搜素结果
    vim.keymap.set('i', config.mappings.next_item, next_item, { buffer = prompt_bufid })
    vim.keymap.set('i', config.mappings.previous_item, previous_item, { buffer = prompt_bufid })
    vim.keymap.set('i', config.mappings.toggle_fix_string, function()
        toggle_fix_string()
        update_result_count()
    end, { buffer = prompt_bufid })
    vim.keymap.set('i', config.mappings.toggle_hidden_file, function()
        toggle_hidden_file()
        update_result_count()
    end, { buffer = prompt_bufid })
    vim.keymap.set(
        'i',
        config.mappings.apply_quickfix,
        apply_to_quickfix,
        { buffer = prompt_bufid }
    )
    vim.keymap.set('i', config.mappings.toggle_preview_win, function()
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
    if grep_input ~= '' then
        vim.api.nvim_buf_set_lines(prompt_bufid, 0, -1, false, { grep_input })
    end
    vim.cmd('noautocmd startinsert!')
end

function M.open(opt)
    if not setup_done then
        M.setup()
    end
    if not opt then
        opt = {}
    end
    saved_mouse_opt = vim.o.mouse
    grep_input = opt.input or ''
    if opt.cwd and vim.fn.isdirectory(opt.cwd) == 1 then
        grep_root_dir = vim.fn.fnamemodify(opt.cwd, ':p')
    else
        grep_root_dir = vim.fn.getcwd()
    end
    log.info('flygrep cwd:' .. grep_root_dir)
    open_win()
end

function M.setup(opt)
    config = require('flygrep.config').setup(opt)
    setup_done = true
end

return M
