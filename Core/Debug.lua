local HC = _G.HoverCast
if not HC then HC = {}; _G.HoverCast = HC end
HC.Debug = HC.Debug or {}

-- Dumps the current state: enabled spells, the resolved key and the macrotext.
function HC.Debug.dump()
  local db = HC.EnsureDB()
  local n = 0
  for name, cfg in pairs(db.spells) do
    if cfg.enabled then
      n = n + 1
      local key = cfg.key
      if not key or key == "" then key = HC.BindDetect.keyForSpell(name) end
      HC.Log(name .. " | key=" .. tostring(key)
        .. " | " .. HC.SecureBinder.buildMacrotext({
          name = name, filter = cfg.filter, fallback = cfg.fallback }))
    end
  end
  if n == 0 then HC.Log("no spells enabled.") end
end
