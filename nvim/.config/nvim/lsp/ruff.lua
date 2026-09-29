-- NOTE: no settings on purpose -- with 'configuration' unset ruff reads each
-- project's own config, and a rule here would override all of them.
return {
  on_attach = function(client)
    client.server_capabilities.hoverProvider = false -- pyright owns K

    -- NOTE: needs the dynamicRegistration refusal below too -- either half
    -- alone leaves formatting live, bypassing plugins/format.lua's gate.
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,

  capabilities = {
    textDocument = {
      formatting = { dynamicRegistration = false },
      rangeFormatting = { dynamicRegistration = false },
    },
  },
}
