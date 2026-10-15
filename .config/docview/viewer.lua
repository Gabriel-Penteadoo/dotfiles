-- Read-only markdown viewer for ~/.local/bin/docs (nvim --clean -R -M, floating foot popup).
-- render-markdown.nvim comes from LazyVim's install; without it the raw markdown shows.
vim.opt.rtp:prepend(vim.fn.expand("~/.local/share/nvim/lazy/render-markdown.nvim"))
vim.o.termguicolors = true
vim.o.laststatus = 0
vim.o.ruler = false
vim.o.showmode = false

-- Monochrome palette (waybar/fuzzel/mako/foot): text #2c2c2c on #efefef, grays
-- #565656 #8a8a8a #bababa. Heading bands step from #bababa toward the background.
local function mono()
    local hl = function(name, val) vim.api.nvim_set_hl(0, name, val) end
    hl("Normal", { fg = "#2c2c2c", bg = "NONE" })
    hl("RenderMarkdownH1",   { fg = "#2c2c2c", bold = true })
    hl("RenderMarkdownH2",   { fg = "#2c2c2c", bold = true })
    hl("RenderMarkdownH3",   { fg = "#2c2c2c", bold = true })
    hl("RenderMarkdownH4",   { fg = "#565656", bold = true })
    hl("RenderMarkdownH5",   { fg = "#565656", bold = true })
    hl("RenderMarkdownH6",   { fg = "#8a8a8a", bold = true })
    hl("RenderMarkdownH1Bg", { bg = "#bababa" })
    hl("RenderMarkdownH2Bg", { bg = "#cecece" })
    hl("RenderMarkdownH3Bg", { bg = "#dedede" })
    hl("RenderMarkdownH4Bg", { bg = "NONE" })
    hl("RenderMarkdownH5Bg", { bg = "NONE" })
    hl("RenderMarkdownH6Bg", { bg = "NONE" })
    hl("RenderMarkdownTableHead", { fg = "#2c2c2c", bold = true })
end

pcall(function()
    require("render-markdown").setup({ anti_conceal = { enabled = false } })
end)
mono()
vim.api.nvim_create_autocmd("ColorScheme", { callback = mono })

vim.api.nvim_create_autocmd("BufWinEnter", {
    callback = function()
        vim.bo.filetype = "markdown"
        vim.wo.wrap, vim.wo.linebreak, vim.wo.number = true, true, false
        vim.wo.conceallevel = 2
        pcall(vim.treesitter.start)
    end,
})

-- Esc / q close (why nvim and not less: less can't bind a lone Esc without breaking arrows)
vim.keymap.set("n", "<Esc>", "<Cmd>qa!<CR>", { silent = true })
vim.keymap.set("n", "q", "<Cmd>qa!<CR>", { silent = true })
