local M = {}

function M.setup()
  local cmp = require("cmp")
  local luasnip = require("luasnip")

  luasnip.config.setup({
    history = true,
    update_events = { "TextChanged", "TextChangedI" },
  })

  local has_words_before = function()
    local line, column = unpack(vim.api.nvim_win_get_cursor(0))
    if column == 0 then
      return false
    end
    return vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(column, column):match("%s") == nil
  end

  cmp.setup({
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },
    mapping = {
      ["<C-k>"] = cmp.mapping.select_prev_item(),
      ["<C-j>"] = cmp.mapping.select_next_item(),
      ["<C-b>"] = cmp.mapping.scroll_docs(-1),
      ["<C-f>"] = cmp.mapping.scroll_docs(1),
      ["<C-Space>"] = cmp.mapping.complete(),
      ["<C-e>"] = cmp.mapping.abort(),
      ["<CR>"] = cmp.mapping.confirm({ select = true }),
      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        elseif has_words_before() then
          cmp.complete()
        else
          fallback()
        end
      end, { "i", "s" }),
      ["<S-Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { "i", "s" }),
    },
    formatting = {
      fields = { "kind", "abbr", "menu" },
      format = function(entry, item)
        item.menu = ({
          nvim_lsp = "[LSP]",
          luasnip = "[Snippet]",
          buffer = "[Buffer]",
          path = "[Path]",
        })[entry.source.name]
        return item
      end,
    },
    sources = cmp.config.sources({
      { name = "nvim_lsp" },
      { name = "luasnip" },
      { name = "buffer" },
      { name = "path" },
    }),
    window = {
      documentation = cmp.config.window.bordered(),
    },
    experimental = {
      ghost_text = true,
    },
  })

  vim.g.portable_cmp_initialized = 1
end

return M
