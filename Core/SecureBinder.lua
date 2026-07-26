local HC = _G.HoverCast
if not HC then HC = {}; _G.HoverCast = HC end
HC.SecureBinder = HC.SecureBinder or {}
local SB = HC.SecureBinder

-- The filter suffix inside a condition: help/harm append ",help"/",harm".
local function suffix(filter)
  if filter == "help" then return ",help" end
  if filter == "harm" then return ",harm" end
  return ""  -- both: no filter
end

-- Builds the /cast macrotext from {name, filter, fallback}.
-- Always an @mouseover condition, then the fallback chain (per the option),
-- then the spell name.
function SB.buildMacrotext(cfg)
  local f = suffix(cfg.filter)
  local cond = "[@mouseover" .. f .. "]"
  if cfg.fallback == "target" then
    cond = cond .. "[@target" .. f .. "]"
  elseif cfg.fallback == "targetself" then
    cond = cond .. "[@target" .. f .. "][@player]"
  end
  -- fallback == "mouseonly": no extra chain
  return "/cast " .. cond .. " " .. cfg.name
end

-- Frame that owns the override bindings (created lazily, not at load time).
function SB.owner()
  if not SB._owner then
    SB._owner = CreateFrame("Frame", "HoverCastBinder", UIParent)
  end
  return SB._owner
end

-- The i-th reusable secure button (created lazily).
function SB.button(i)
  SB._buttons = SB._buttons or {}
  if not SB._buttons[i] then
    local b = CreateFrame("Button", "HoverCastButton" .. i, UIParent,
      "SecureActionButtonTemplate")
    b:Hide()
    SB._buttons[i] = b
  end
  return SB._buttons[i]
end

-- Removes all of our override bindings.
function SB.clear()
  if SB._owner then ClearOverrideBindings(SB._owner) end
end

-- Rebuilds buttons and override bindings for every enabled spell.
-- ONLY out of combat; while in combat it flags itself pending and returns.
function SB.apply()
  if InCombatLockdown() then SB.pending = true; return end
  SB.pending = false
  local owner = SB.owner()
  ClearOverrideBindings(owner)
  local db = HC.EnsureDB()
  local i, conflicts = 0, {}
  for name, cfg in pairs(db.spells) do
    if cfg.enabled then
      local key = cfg.key
      if not key or key == "" then key = HC.BindDetect.keyForSpell(name) end
      if key and key ~= "" then
        if conflicts[key] then
          HC.Log("warning: key '" .. key .. "' is used by multiple spells ("
            .. conflicts[key] .. " and " .. name .. "); last one wins.")
        end
        conflicts[key] = name
        i = i + 1
        local btn = SB.button(i)
        btn:SetAttribute("type", "macro")
        btn:SetAttribute("macrotext", SB.buildMacrotext({
          name = name, filter = cfg.filter, fallback = cfg.fallback }))
        SetOverrideBindingClick(owner, false, key, btn:GetName(), "LeftButton")
      end
    end
  end
  SB.usedButtons = i
end

-- Combat-safe entry point: apply now, or queue for PLAYER_REGEN_ENABLED.
function SB.request()
  if InCombatLockdown() then SB.pending = true else SB.apply() end
end

-- Registers the events that force the bindings to be reapplied.
function SB.hook()
  local reapply = function() SB.request() end
  HC.RegisterEvent("PLAYER_ENTERING_WORLD", reapply)
  HC.RegisterEvent("UPDATE_BINDINGS", reapply)
  HC.RegisterEvent("ACTIONBAR_SLOT_CHANGED", reapply)
  HC.RegisterEvent("LEARNED_SPELL_IN_TAB", reapply)
  HC.RegisterEvent("SPELLS_CHANGED", reapply)
  HC.RegisterEvent("PLAYER_REGEN_ENABLED", function()
    if SB.pending then SB.apply() end
  end)
end
