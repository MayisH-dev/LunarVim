local M = {}
local u = require "utils"
function M.config()
  require("lsp.kind").setup()
  require("lsp.handlers").setup()
  require("lsp.signs").setup()
end

local function lsp_highlight_document(client)
  if lvim.lsp.document_highlight == false then
    return -- we don't need further
  end
  -- Set autocommands conditional on server_capabilities
  if client.resolved_capabilities.document_highlight then
    vim.api.nvim_exec(
      [[
      hi LspReferenceRead cterm=bold ctermbg=red guibg=#464646
      hi LspReferenceText cterm=bold ctermbg=red guibg=#464646
      hi LspReferenceWrite cterm=bold ctermbg=red guibg=#464646
      augroup lsp_document_highlight
        autocmd! * <buffer>
        autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
        autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
      augroup END
    ]],
      false
    )
  end
end

local function formatter_handler(client)
  formatter_exe = lvim.lang[vim.bo.filetype].formatters[1].exe
  if formatter_exe and formatter_exe ~= "" then
    client.resolved_capabilities.document_formatting = false
    __FORMATTER_OVERRIDE = true
    u.lvim_log(
      string.format("Overriding [%s] formatting if exists, Using provider [%s] instead", client.name, ext_provider)
    )
  end
end

function M.common_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = {
      "documentation",
      "detail",
      "additionalTextEdits",
    },
  }
  return capabilities
end

function M.common_on_init(client, bufnr)
  if lvim.lsp.on_init_callback then
    lvim.lsp.on_init_callback(client, bufnr)
    return
  end
  formatter_handler(client)
end

function M.common_on_attach(client, bufnr)
  if lvim.lsp.on_attach_callback then
    lvim.lsp.on_attach_callback(client, bufnr)
  end
  lsp_highlight_document(client)
  require("lsp.keybinds").setup()
  require("lsp.null-ls").setup(vim.bo.filetype)
end

function M.setup(lang)
  local lang_server = lvim.lang[lang].lsp
  local provider = lang_server.provider
  if require("utils").check_lsp_client_active(provider) then
    return
  end

  require("lspconfig")[provider].setup(lang_server.setup)
end

return M
