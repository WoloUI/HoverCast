local HC = _G.HoverCast
if not HC then HC = {}; _G.HoverCast = HC end
HC.BindDetect = HC.BindDetect or {}
local BD = HC.BindDetect

-- Maps an action slot (1..120) to its default Blizzard binding name.
-- Page 2 (slots 13..24) has no binding of its own -> nil.
function BD.slotBinding(slot)
  if slot >= 1  and slot <= 12 then return "ACTIONBUTTON" .. slot end
  if slot >= 25 and slot <= 36 then return "MULTIACTIONBAR3BUTTON" .. (slot - 24) end  -- Right
  if slot >= 37 and slot <= 48 then return "MULTIACTIONBAR4BUTTON" .. (slot - 36) end  -- Left
  if slot >= 49 and slot <= 60 then return "MULTIACTIONBAR2BUTTON" .. (slot - 48) end  -- Bottom Right
  if slot >= 61 and slot <= 72 then return "MULTIACTIONBAR1BUTTON" .. (slot - 60) end  -- Bottom Left
  return nil
end

-- Scans ElvUI (when present): looks through its bars for a button holding the
-- spell and returns its key via "CLICK <button>:LeftButton". Best-effort; may
-- need adjusting in-game depending on the ElvUI version.
local function elvuiKey(spellName)
  if not _G.ElvUI then return nil end
  for bar = 1, 10 do
    for i = 1, 12 do
      local btnName = "ElvUI_Bar" .. bar .. "Button" .. i
      local btn = _G[btnName]
      if btn then
        local action = btn.GetAttribute and btn:GetAttribute("action")
        if action then
          local t, id, _, spellID = GetActionInfo(action)
          local sid = spellID or id
          if t == "spell" and sid and GetSpellInfo(sid) == spellName then
            local k = GetBindingKey("CLICK " .. btnName .. ":LeftButton")
            if k then return k end
          end
        end
      end
    end
  end
  return nil
end

-- Returns the key bound to a spell, scanning the Blizzard bars first and
-- falling back to the ElvUI bars. nil when the spell is on no bar at all.
-- GetActionInfo returns (type, id, subType, spellID): we prefer spellID (or id).
function BD.keyForSpell(spellName)
  for slot = 1, 120 do
    local t, id, _, spellID = GetActionInfo(slot)
    local sid = spellID or id
    if t == "spell" and sid and GetSpellInfo(sid) == spellName then
      local binding = BD.slotBinding(slot)
      if binding then
        local k = GetBindingKey(binding)
        if k then return k end
      end
    end
  end
  return elvuiKey(spellName)
end
