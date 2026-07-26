local HC = _G.HoverCast
if not HC then HC = {}; _G.HoverCast = HC end

HC.DEFAULT_SPELL = { enabled = false, filter = "both", fallback = "mouseonly", key = nil }

-- Event dispatcher. Modules register callbacks in HC.on[EVENT].
HC.on = HC.on or {}
local dispatcher = CreateFrame("Frame")

-- Invokes the handlers of an event (isolated so it can be driven headless).
function HC.dispatch(event, ...)
  local handlers = HC.on[event]
  if handlers then
    for i = 1, #handlers do HC.safe(handlers[i], ...) end
  end
end

dispatcher:SetScript("OnEvent", function(_, event, ...) HC.dispatch(event, ...) end)
HC.dispatcher = dispatcher

-- Registers a handler for an event and makes sure the frame listens for it.
function HC.RegisterEvent(event, handler)
  HC.on[event] = HC.on[event] or {}
  table.insert(HC.on[event], handler)
  dispatcher:RegisterEvent(event)
end

-- Creates (if missing) the per-character SavedVariable with its defaults, and
-- returns it.
function HC.EnsureDB()
  HoverCastDB = HoverCastDB or {}
  local db = HoverCastDB
  db.spells = db.spells or {}
  db.minimap = db.minimap or {}
  if type(db.minimap.hide) ~= "boolean" then db.minimap.hide = false end
  if type(db.minimap.angle) ~= "number" then db.minimap.angle = 210 end
  return db
end

-- Returns a spell's config, creating it with defaults the first time.
function HC.SpellConfig(name)
  local db = HC.EnsureDB()
  local cfg = db.spells[name]
  if not cfg then
    cfg = {}
    for k, v in pairs(HC.DEFAULT_SPELL) do cfg[k] = v end
    db.spells[name] = cfg
  end
  return cfg
end

-- On login: prepare SavedVariables and bind whatever is already enabled.
HC.RegisterEvent("PLAYER_LOGIN", function()
  HC.EnsureDB()
  HC.SecureBinder.hook()
  HC.SecureBinder.request()
  HC.Log("loaded. Type /hc to configure.")
end)
