-- Minimal WoW API stub for out-of-game tests (lua5.1).
local M = {}

-- Universal frame stub: any method call is a no-op returning nil, except the
-- handful of getters the addon actually reads back.
local function MakeFrame(name)
  local frame = { __name = name, __scripts = {}, __attributes = {}, __events = {} }
  setmetatable(frame, {
    __index = function(self, key)
      if key == "GetName" then return function() return self.__name end end
      if key == "CreateTexture" or key == "CreateFontString" then
        return function() return MakeFrame() end
      end
      if key == "SetScript" then
        return function(_, script, fn) self.__scripts[script] = fn end
      end
      if key == "GetScript" then
        return function(_, script) return self.__scripts[script] end
      end
      if key == "SetAttribute" then
        return function(_, k, v) self.__attributes[k] = v end
      end
      if key == "GetAttribute" then
        return function(_, k) return self.__attributes[k] end
      end
      if key == "RegisterEvent" then
        return function(_, event) self.__events[event] = true end
      end
      if key == "IsShown" or key == "IsVisible" then
        return function() return self.__shown and true or false end
      end
      if key == "Show" then return function() self.__shown = true end end
      if key == "Hide" then return function() self.__shown = false end end
      if key == "GetChecked" then return function() return self.__checked end end
      if key == "SetChecked" then
        return function(_, v) self.__checked = v end
      end
      return function() end
    end,
  })
  return frame
end
M.MakeFrame = MakeFrame

function M.install(env)
  env = env or _G

  env.CreateFrame = function(_, name) return MakeFrame(name) end
  env.DEFAULT_CHAT_FRAME = { AddMessage = function(_, msg) env.__chat = msg end }
  env.UIParent = MakeFrame("UIParent")
  env.Minimap = MakeFrame("Minimap")
  env.SlashCmdList = {}
  env.GameTooltip = MakeFrame("GameTooltip")
  env.BOOKTYPE_SPELL = "spell"

  -- Combat lockdown: tests flip env.__inCombat.
  env.InCombatLockdown = function() return env.__inCombat and true or false end

  -- Override-binding bookkeeping so tests can assert what got bound.
  env.__bindings = {}
  env.ClearOverrideBindings = function() env.__bindings = {} end
  env.SetOverrideBindingClick = function(_, _, key, button)
    env.__bindings[key] = button
  end

  -- Key bindings: env.__keys maps a binding name -> key.
  env.__keys = env.__keys or {}
  env.GetBindingKey = function(binding) return env.__keys[binding] end

  -- Action bars: env.__actions maps a slot -> spellID.
  env.__actions = env.__actions or {}
  env.GetActionInfo = function(slot)
    local id = env.__actions[slot]
    if not id then return nil end
    return "spell", id, nil, id
  end

  -- Spellbook: env.__spells maps a spellID -> name.
  env.__spells = env.__spells or {}
  env.GetSpellInfo = function(id) return env.__spells[id] end

  -- Spellbook scan surface (SpellScan).
  env.GetNumSpellTabs = function() return env.__numTabs or 0 end
  env.GetSpellTabInfo = function(tab)
    local t = (env.__tabs or {})[tab]
    if not t then return nil end
    return t.name, t.texture, t.offset, t.numSpells
  end
  env.GetSpellName = function(i) return (env.__book or {})[i] end
  env.GetSpellTexture = function(i) return "icon" .. tostring(i) end
  env.IsPassiveSpell = function(i) return (env.__passive or {})[i] and true or false end

  return env
end

-- Loads an addon file relative to the addon root (tests run from the root).
function M.loadAddonFile(path)
  local chunk, err = loadfile(path)
  if not chunk then error("cannot load " .. path .. ": " .. tostring(err)) end
  return chunk()
end

return M
