vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

--[[
  ""    -   Normal, Visual, Select, Operator-pending
  "n"   -   Normal
  "v"   -   Visual and Select
  "s"   -   Select
  "x"   -   Visual
  "o"   -   Operator-pending
  "!"   -   Insert and Command-line
  "i"   -   Insert
  "l"   -   Insert, Command-line, Lang-Arg
  "c"   -   Command-line
  "t"   -   Terminal
]]--

-- jf and fj as <esc>
map({ "!", "t" }, "kj", "<esc>", { remap = true })

map("n", ";", ":")
map("n", ":", ";")

-- force myself to use the home row
map("n", "<left>", "<nop>")
map("n", "<right>", "<nop>")
map("n", "<up>", "<nop>")
map("n", "<down>", "<nop>")

-- make j and k move visual line-wise
map("n", "j", "gj")
map("n", "k", "gk")

-- x and X without yanking
map("n", "x", "\"_x")
map("n", "X", "\"_X")

-- always center the screen after search
map("n", "n", "nzz", { silent = true })
map("n", "N", "Nzz", { silent = true })
map("n", "*", "*zz", { silent = true })
map("n", "#", "#zz", { silent = true })
map("n", "g*", "g*zz", { silent = true })

-- jump to start/end of line using home row keys
map({ "n", "v" }, "<S-h>", "^")
map({ "n", "v" }, "<S-l>", "$")

-- switch between buffers
map("n", "<C-n>", "<cmd>bn<cr>", { silent = true })
map("n", "<C-p>", "<cmd>bp<cr>", { silent = true })

-- make window navigation easier
map("n", "<C-h>", "<C-w><C-h>")
map("n", "<C-l>", "<C-w><C-l>")
map("n", "<C-j>", "<C-w><C-j>")
map("n", "<C-k>", "<C-w><C-k>")

-- open new file adjacent to current buffer
map("n", "<leader>o", ":e <C-R>=expand('%:p:h') . '/' <cr>")

-- use some emacs-like keybindings in insert mode and command-line mode
-- (because I came from emacs...)
map("i", "<C-k>", "<C-o>D")
map("i", "<C-a>", "<C-o>^")
map("i", "<C-e>", "<C-o>$")
map("c", "<C-a>", "<Home>")
map("c", "<C-e>", "<End>")
map("!", "<C-b>", "<Left>")
map("!", "<C-f>", "<Right>")
map("!", "<C-p>", "<Up>")
map("!", "<C-n>", "<Down>")
map("!", "<C-d>", "<Del>")

-- clear search with <esc>
map({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>")

-- "very magic" (less escaping needed) regexes by default
map("n", "?", "?\\v")
map("n", "/", "/\\v")
map("c", "%s/", "%sm/")

-- don't be such an over-pager when paging
map({ "n", "v" }, "<C-f>", "<C-d>", { silent = true })
map({ "n", "v" }, "<C-b>", "<C-u>", { silent = true })
