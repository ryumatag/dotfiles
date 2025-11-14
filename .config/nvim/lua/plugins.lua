return {
  -- colorscheme
  {
    "RRethy/nvim-base16",
    lazy = false,
    priority = 1000,
    config = function()
      vim.o.background = "dark"
      vim.cmd.colorscheme("base16-gruvbox-dark-hard")
      local colorscheme = require("base16-colorscheme")
      local c = colorscheme.colors
      local u = require("utils")
      local hi = u.highlight
      hi.LineNr = { guifg = c.base03, ctermfg = c.cterm03 }
      hi.CursorLineNr = { guifg = c.base0D, guibg = "none" }
      hi.CursorLine = { guibg = "none" }
      hi.FloatBorder = { guifg = c.base03 }
      hi.CmpItemAbbr = { guibg = "none" }

      hi.DiagnosticWarn = { guifg = c.base0A }
      hi.DiagnosticUnderlineWarn = { guisp = c.base0A }

      hi.IlluminatedWordText = { guibg = c.base01, gui = "none" }
      hi.IlluminatedWordRead = { guibg = c.base01, gui = "none" }
      hi.IlluminatedWordWrite = { guibg = c.base01, gui = "none" }
    end,
  },

  -- fzf, this is a big one
  {
    "ibhagwan/fzf-lua",
    branch = "main",
    keys = function()
      local fzf = require("fzf-lua")
      return {
        { "<leader>f", fzf.files, desc = "search files" },
        { "<leader>g", fzf.grep_curbuf, desc = "grep current buffer" },
        { "<leader>G", fzf.grep_project, desc = "grep project" },
        { "<leader>sf", fzf.files, desc = "search files" },
        { "<leader>sb", fzf.buffers, desc = "search buffers" },
        { "<leader>sk", fzf.keymaps, desc = "search keymaps" },
        { "<leader>dd", fzf.diagnostics_document, desc = "document diagnostics" },
        { "<leader>wd", fzf.diagnostics_workspace, desc = "workspace diagnostics" },
      }
    end,
    opts = {
      "fzf-native",
      winopts = {
        -- stop putting a giant window over my editor
        height = 0.60,
        width = 0.90,
        row = 1, -- fix to bottom

        border = "single",

        preview = {
          border = "border-sharp", -- equivalent to `fzf --preview=border-sharp`
        },
      },
      keymap = {
        fzf = {
          ["ctrl-f"] = "preview-down",
          ["ctrl-b"] = "preview-up",
        },
      },
      files = {
        fd_opts = "--color=never -t file -H -L --exclude .git"
      },
      grep = {
        rg_opts = "-L -. --column -n --no-heading --color=always --smart-case --max-columns=4096 -e",
      },
    },
    config = function(_, opts)
      local fzf = require("fzf-lua")
      -- fzf.register_ui_select()
      fzf.setup(opts)
    end,
  },

  -- LSP
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- sigunature hint
      {
        "ray-x/lsp_signature.nvim",
        opts = {
          doc_lines = 0,
          handler_opts = { border = "single" },
          hint_prefix = "",
        },
      },
      -- LSP based completion
      { "hrsh7th/cmp-nvim-lsp" },
    },
    config = function(_, opts)
      vim.lsp.config("*", {
        capabilities = require('cmp_nvim_lsp').default_capabilities(),
      })

      -- Rust
      vim.lsp.config("rust_analyzer", {
        settings = {
          ["rust-analyzer"] = {
            cargo = { features = "all" },
            checkOnSave = { enable = true },
            check = { command = "clippy" },
          },
        },
      })
      vim.lsp.enable("rust_analyzer")

      -- Toml
      if vim.fn.executable("taplo") == 1 then
        vim.lsp.enable("taplo")
      end

      -- Go
      vim.lsp.config("gopls", {
        on_attach = function(client, bufnr)
          vim.bo[bufnr].expandtab = false
          vim.bo[bufnr].tabstop = 8
          vim.bo[bufnr].shiftwidth = 8
          vim.bo[bufnr].softtabstop = 8
        end,
        settings = {
          ["gopls"] = {
            analyses = {
              shadow = true,
              unusedvariable = true,
              useany = true,
            },
            staticcheck = true,
            gofumpt = true,
          },
        },
      })
      vim.lsp.enable("gopls")

      -- Bash
      if vim.fn.executable("bash-language-server") == 1 then
        vim.lsp.enable("bashls")
      end

      -- global mappings
      vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
      vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
      vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
      vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)

      -- use LspAttach autocommand to only map the following keys
      -- after the language server attaches to the current buffer
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', {}),
        callback = function(ev)
          -- buffer local mappings
          local map = function(key, fn)
            vim.keymap.set("n", key, fn, { buffer = ev.buf })
          end

          local fzf = require("fzf-lua")
          map("gd", fzf.lsp_definitions)
          map("gD", fzf.lsp_declarations)
          map("gr", fzf.lsp_references)
          map("gi", fzf.lsp_implementations)
          map("gf", fzf.lsp_finder)
          map("<leader>D", fzf.lsp_typedefs)
          map("<leader>ds", fzf.lsp_document_symbols)
          map("<leader>ws", fzf.lsp_workspace_symbols)
          -- use builtin LSP client's code action now, since fzf-lua's code
          -- action function causes some errors and I don't know why
          map("<leader>a", vim.lsp.buf.code_action --[[fzf.lsp_code_actions]])
          map("<leader>wa", vim.lsp.buf.add_workspace_folder)
          map("<leader>wr", vim.lsp.buf.remove_workspace_folder)
          map("<leader>wl", function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end)
          map("<leader>rn", vim.lsp.buf.rename)
          --map("<leader>f", function() vim.lsp.buf.format { async = true } end)
          map("K", function() vim.lsp.buf.hover({ border = "single" }) end)
          map("<C-s>", vim.lsp.buf.signature_help)

          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client.server_capabilities.inlayHintProvider then
            map(
              "<leader>th",
              function()
                vim.lsp.inlay_hint.enable(
                  not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }),
                  { bufnr = ev.buf }
                )
              end
            )
          end

          client.server_capabilities.semanticTokensProvider = nil

          require('lspconfig.ui.windows').default_options.border = "single"

          -- disable inline diagnostic messages
          vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
            vim.lsp.diagnostic.on_publish_diagnostics,
            { virtual_text = false }
          )

          -- set border for textDocument/hover and textDocument/signatureHelp
          vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
            vim.lsp.handlers.hover,
            { border = "single" }
          )
          vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
            vim.lsp.handlers.signature_help,
            { border = "single" }
          )
          vim.diagnostic.config({
            float = { border= "single" },
            severity_sort = true,
          })
        end
      })
    end,
  },

  {
    "hrsh7th/nvim-cmp",
    version = false,
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      'hrsh7th/cmp-cmdline',
    },
    config = function()
      local cmp = require("cmp")

      cmp.event:on(
        'confirm_done',
        require('nvim-autopairs.completion.cmp').on_confirm_done()
      )

      local window_opts = cmp.config.window.bordered({
        border = "single",
        scrollbar = false,
      })

      local select_next_item = {
        i = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
        c = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
      }

      local select_prev_item = {
        i = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
        c = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
      }

      cmp.setup({
        mapping = {
          ["<C-n>"] = select_next_item,
          ["<C-p>"] = select_prev_item,
          ["<C-j>"] = select_next_item,
          ["<C-k>"] = select_prev_item,
          ["<C-b>"] = { i = cmp.mapping.scroll_docs(-4) },
          ["<C-f>"] = { i = cmp.mapping.scroll_docs(4) },
          ['<C-l>'] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<cr>"] = cmp.mapping.confirm({ select = false }),
        },
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
        }, {
          { name = "path" },
          { name = "buffer" },
        }),
        window = {
          completion = window_opts,
          documentation = window_opts,
        },
        experimental = {
          ghost_text = false,
        },
      })

      -- use buffer source for `/` and `?`
      cmp.setup.cmdline({ "/", "?" }, {
        sources = {
          { name = "buffer" }
        }
      })

      -- use cmdline & path source for ':'
      cmp.setup.cmdline(':', {
        sources = cmp.config.sources({
          { name = 'path' }
        }, {
          { name = 'cmdline' }
        }),
        matching = { disallow_symbol_nonprefix_matching = false }
      })
    end,
  },

  -- autopairs
  {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    opts = {
      check_ts = true,
    },
  },

  -- tree-sitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    event = { "BufReadPost", "BufNewFile", "BufWritePre" },
    keys = {
      { "n", desc = "Increment selection", mode = "x" },
      { "<S-n>", desc = "Decrement selection", mode = "x" },
    },
    opts = {
      highlight = { enable = false },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = false,
          node_incremental = "n",
          scope_incremental = false,
          node_decremental = "N",
        },
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile", "BufWritePre" },
    opts = { mode = "cursor", max_lines = 3 },
    keys = {
      {
        "<leader>tc",
        function()
          require("treesitter-context").toggle()
        end,
        desc = "enable/disable treesitter-context",
      },
    },
  },

  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    -- https://github.com/nvim-neo-tree/neo-tree.nvim/issues/1247#issuecomment-1836294270
    init = function()
      vim.api.nvim_create_autocmd('BufEnter', {
        -- make a group to be able to delete it later
        group = vim.api.nvim_create_augroup('NeoTreeInit', { clear = true }),
        callback = function()
          local f = vim.fn.expand('%:p')
          if vim.fn.isdirectory(f) ~= 0 then
            vim.cmd('Neotree current dir=' .. f)
            -- neo-tree is loaded now, delete the init autocmd
            vim.api.nvim_clear_autocmds({ group = 'NeoTreeInit' })
          end
        end
      })
    end,
    keys = {
      {
        "<leader>E",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })
        end,
        desc = "explore",
      },
    },
    opts = {
      sources = { "filesystem" },
      default_component_configs = {
        icon = { enabled = false },
        name = { trailing_slash = true },
      },
      filesystem = {
        filtered_items = {
          visible = false,
          hide_dotfiles = false,
          hide_by_name = { ".git" },
          never_show = { ".DS_Store" },
        },
        bind_to_cwd = false,
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
        hijack_netrw_behavior = "open_current",
        window = { position = "left" },
      },
    },
  },

  -- statusline
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        theme = "gruvbox_dark",
        icons_enabled = false,
        component_separators = { left = "|", right = "|"},
        section_separators = { left = "", right = ""},
        globalstatus = true,
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { { "filename", path = 1 }, "diff", "diagnostics"},
        lualine_c = { },
        lualine_x = { "encoding", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
      inactive_sections = {
        lualine_a = { },
        lualine_b = { { "filename", path = 1 }, "diff", "diagnostics"},
        lualine_c = { },
        lualine_x = { },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
      extensions = { "lazy" },
    },
  },

  -- my friend
  {
    "github/copilot.vim",
    config = function()
      local map = function(key, fn)
        vim.keymap.set("i", key, "<Plug>(" .. fn .. ")")
      end
      map("<M-l>", "copilot-accept-word")
      map("<M-L>", "copilot-accept-line")
      map("<M-j>", "copilot-next")
      map("<M-k>", "copilot-previous")
      map("<M-h>", "copilot-dismiss")
      map("<M-;>", "copilot-suggest")
    end,
  },

  {
    "echasnovski/mini.bufremove",
    keys = {
      {
        "<leader>bd",
        function()
          local bd = require("mini.bufremove").delete
          if vim.bo.modified then
            local choice = vim.fn.confirm(("Save changes to %q?"):format(vim.fn.bufname()), "&Yes\n&No\n&Cancel")
            if choice == 1 then
              vim.cmd.write()
              bd(0)
            elseif choice == 2 then
              bd(0, true)
            end
          else
            bd(0)
          end
        end,
        desc = "delete",
      },
      { "<leader>bD", function() require("mini.bufremove").delete(0, true) end, desc = "delete (force)" },
    },
  },

  -- indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    keys = {
      {
        "<leader>t,",
        function()
          local enabled = require("ibl.config").get_config(0).enabled
          if enabled then
            vim.opt_local.listchars:append({
              tab = "  ", space = " ", eol = " ",
            })
          else
            vim.opt_local.listchars:append({
              tab = "›-", space = "･", eol = "¬",
            })
          end
          require("ibl").setup_buffer(0, {
            enabled = not enabled
          })
        end,
        desc = "show/hide hidden characters",
      },
    },
    opts = {
      -- defaults to false
      enabled = false,
      indent = {
        char = { "", "▏" },
      },
      scope = { enabled = false },
    },
  },

  -- notifications and LSP progress messages
  {
    "j-hui/fidget.nvim",
    event = "VeryLazy",
    opts = {
      notification = {
        override_vim_notify = true,
        window = { x_padding = 0 },
      },
    },
  },

  -- comments
  {
    "numToStr/Comment.nvim",
    dependencies = {
      {
        "JoosepAlviste/nvim-ts-context-commentstring",
        opts = { enable_autocmd = false },
      },
    },
    config = function()
      require("Comment").setup({
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook()
      })
    end,
  },

  -- auto-cd to root of git repo
  {
    "notjedi/nvim-rooter.lua",
    config = function()
      require("nvim-rooter").setup()
    end,
  },

  -- add git status to the sign column
  {
    "lewis6991/gitsigns.nvim",
    opts = {},
  },

  -- quick navigation
  {
    "ggandor/leap.nvim",
    config = function()
      require('leap').create_default_mappings()
    end
  },

  -- even better %
  {
    "andymass/vim-matchup",
    config = function()
      vim.g.matchup_matchparen_offscreen = { method = "popup" }
    end,
  },

  -- ♡ Rust ♡
  {
    "rust-lang/rust.vim",
    ft = { "rust" },
    config = function()
      vim.g.rustfmt_autosave = 1
      vim.g.rustfmt_fail_silently = 0
    end,
  },

  {
    "saecki/crates.nvim",
    tag = "stable",
    event = "BufRead Cargo.toml",
    opts = {
      text = {
        loading = "  Loading...",
        version = "  %s",
        prerelease = "  %s",
        yanked = "  %s yanked",
        nomatch = "  Not found",
        upgrade = "  %s",
        error = "  Error fetching crate",
      },
      popup = {
        text = {
          title = "# %s",
          pill_left = "",
          pill_right = "",
          created_label = "created        ",
          updated_label = "updated        ",
          downloads_label = "downloads      ",
          homepage_label = "homepage       ",
          repository_label = "repository     ",
          documentation_label = "documentation  ",
          crates_io_label = "crates.io      ",
          categories_label = "categories     ",
          keywords_label = "keywords       ",
          version = "%s",
          prerelease = "%s pre-release",
          yanked = "%s yanked",
          enabled = "* s",
          transitive = "~ s",
          normal_dependencies_title = "  Dependencies",
          build_dependencies_title = "  Build dependencies",
          dev_dependencies_title = "  Dev dependencies",
          optional = "? %s",
          loading = " ...",
        },
      },
      src = {
        text = {
          prerelease = " pre-release ",
          yanked = " yanked ",
        },
      },
    },
    config = function(_, opts)
      require('crates').setup(opts)
    end,
  },

  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function() vim.fn["mkdp#util#install"]() end,
  },

  {
    "RRethy/vim-illuminate",
    event = "BufRead",
    opts = { large_file_cutoff = 2000 },
    config = function(_, opts)
      require("illuminate").configure(opts)
    end,
  },

  {
    "petertriho/nvim-scrollbar",
    event = "VeryLazy",
    opts = {
      excluded_filetypes = { "neo-tree" }
    },
    config = function(_, opts)
      require("scrollbar").setup(opts)
      require("scrollbar.handlers.gitsigns").setup()
    end,
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      code = {
        sign = false,
        style = "normal",
        width = "block",
        min_width = 79,
        left_pad = 1,
        right_pad = 1,
        border = "thin",
      },
      heading = {
        sign = false,
        width = "block",
        left_pad = 2,
        right_pad = 2,
        icons = {},
        border = true,
        border_virtual = true,
        backgrounds = {
          "RenderMarkdownH1Bg",
          "RenderMarkdownH1Bg",
          "RenderMarkdownH1Bg",
          "RenderMarkdownH1Bg",
          "RenderMarkdownH1Bg",
          "RenderMarkdownH1Bg",
        },
      },
      checkbox = {
        enabled = false,
      },
    },
    ft = { "markdown", "norg", "rmd", "org", "codecompanion" },
    config = function(_, opts)
      require("render-markdown").setup(opts)
    end,
  },
}
