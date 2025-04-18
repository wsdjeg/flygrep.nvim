local M = {}

local default_config = {
    timeout = 200,
    color_templete = {
        a = {
            fg = '#2c323c',
            bg = '#98c379',
            ctermfg = 16,
            ctermbg = 114,
            bold = true,
        },
        b = {
            fg = '#abb2bf',
            bg = '#3b4048',
            ctermfg = 145,
            ctermbg = 16,
            bold = false,
        },
    },

    command = {
        execute = 'rg',
        default_opts = {
            '--no-heading',
            '--color=never',
            '--with-filename',
            '--line-number',
            '--column',
            '-g',
            '!.git',
        },
        expr_opt = '-e',
        fixed_string_opt = '-F',
        default_fopts = { '-N' },
        smart_case = '-S',
        ignore_case = '-i',
        hidden_opt = '--hidden',
    },

    matched_higroup = 'IncSearch',

    enable_preview = false,
}

M.setup = function(opt)
    return vim.tbl_deep_extend('force', default_config, opt or {})
end

return M
