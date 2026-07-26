-- Action-slot to binding-name mapping, and key detection for a spell.
local stub = dofile("tests/wow_stub.lua")
stub.install(_G)

stub.loadAddonFile("Core/Log.lua")
stub.loadAddonFile("Core/Init.lua")
stub.loadAddonFile("Core/BindDetect.lua")

local T = {}
local function check(name, cond)
  T[#T + 1] = { name = name, ok = cond and true or false }
  print((cond and "  ok  " or "  FAIL") .. " " .. name)
end

print("test_binddetect")

local BD = _G.HoverCast.BindDetect

-- Main bar and the four multi-action bars map to their Blizzard binding names.
check("slot 1 is ACTIONBUTTON1", BD.slotBinding(1) == "ACTIONBUTTON1")
check("slot 12 is ACTIONBUTTON12", BD.slotBinding(12) == "ACTIONBUTTON12")
check("slot 25 is right bar button 1", BD.slotBinding(25) == "MULTIACTIONBAR3BUTTON1")
check("slot 36 is right bar button 12", BD.slotBinding(36) == "MULTIACTIONBAR3BUTTON12")
check("slot 37 is left bar button 1", BD.slotBinding(37) == "MULTIACTIONBAR4BUTTON1")
check("slot 49 is bottom right button 1", BD.slotBinding(49) == "MULTIACTIONBAR2BUTTON1")
check("slot 61 is bottom left button 1", BD.slotBinding(61) == "MULTIACTIONBAR1BUTTON1")
check("slot 72 is bottom left button 12", BD.slotBinding(72) == "MULTIACTIONBAR1BUTTON12")

-- Page 2 (13..24) has no binding of its own on 3.3.5.
check("slot 13 has no binding", BD.slotBinding(13) == nil)
check("slot 24 has no binding", BD.slotBinding(24) == nil)
-- Slots past the bindable bars (pet/stance/extra pages) have none either.
check("slot 73 has no binding", BD.slotBinding(73) == nil)
check("slot 120 has no binding", BD.slotBinding(120) == nil)

-- keyForSpell: find the spell on a bar, then read that slot's bound key.
_G.__spells = { [774] = "Rejuvenation", [8936] = "Regrowth", [5185] = "Healing Touch" }
_G.__actions = { [1] = 774, [26] = 8936, [13] = 5185 }
_G.__keys = { ACTIONBUTTON1 = "Q", MULTIACTIONBAR3BUTTON2 = "SHIFT-E" }

check("finds the key on the main bar", BD.keyForSpell("Rejuvenation") == "Q")
check("finds the key on a multi-action bar", BD.keyForSpell("Regrowth") == "SHIFT-E")
check("spell on an unbindable page yields no key", BD.keyForSpell("Healing Touch") == nil)
check("spell on no bar at all yields no key", BD.keyForSpell("Wrath") == nil)

-- A slot holding the spell but with nothing bound to it must not resolve.
_G.__keys = {}
check("no key bound means no key found", BD.keyForSpell("Rejuvenation") == nil)

return T
