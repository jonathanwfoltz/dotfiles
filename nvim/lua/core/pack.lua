-- vim.pack.add with the confirmation prompt off. The plugin list *is* this
-- repository and is reviewed in git, so asking again at startup adds nothing and
-- blocks any unattended or headless launch -- including the verification recipe.
-- Everything else is left at the vim.pack defaults, notably `load`, which is
-- false while init.lua is sourcing and true afterwards.
return function(specs)
  vim.pack.add(specs, { confirm = false })
end
