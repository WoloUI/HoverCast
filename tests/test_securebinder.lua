-- Macrotext construction and override-binding application.
local stub = dofile("tests/wow_stub.lua")
stub.install(_G)

stub.loadAddonFile("Core/Log.lua")
stub.loadAddonFile("Core/Init.lua")
stub.loadAddonFile("Core/BindDetect.lua")
stub.loadAddonFile("Core/SecureBinder.lua")

local T = {}
local function check(name, cond)
  T[#T + 1] = { name = name, ok = cond and true or false }
  print((cond and "  ok  " or "  FAIL") .. " " .. name)
end

print("test_securebinder")

local HC = _G.HoverCast
local SB = HC.SecureBinder

-- Macrotext: the @mouseover condition is always first, then the fallback chain.
check("mouseover only, any target",
  SB.buildMacrotext({ name = "Rejuvenation", filter = "both", fallback = "mouseonly" })
    == "/cast [@mouseover] Rejuvenation")

check("friendly filter adds ,help",
  SB.buildMacrotext({ name = "Rejuvenation", filter = "help", fallback = "mouseonly" })
    == "/cast [@mouseover,help] Rejuvenation")

check("hostile filter adds ,harm",
  SB.buildMacrotext({ name = "Shadow Bolt", filter = "harm", fallback = "mouseonly" })
    == "/cast [@mouseover,harm] Shadow Bolt")

check("target fallback appends @target",
  SB.buildMacrotext({ name = "Regrowth", filter = "help", fallback = "target" })
    == "/cast [@mouseover,help][@target,help] Regrowth")

check("target+self fallback appends @target then @player",
  SB.buildMacrotext({ name = "Regrowth", filter = "help", fallback = "targetself" })
    == "/cast [@mouseover,help][@target,help][@player] Regrowth")

check("filter carries into the fallback chain, not the @player leg",
  SB.buildMacrotext({ name = "Heal", filter = "harm", fallback = "targetself" })
    == "/cast [@mouseover,harm][@target,harm][@player] Heal")

-- Apply: only enabled spells get bound, and only when a key resolves.
_G.__inCombat = false
_G.__spells = { [774] = "Rejuvenation", [8936] = "Regrowth" }
_G.__actions = { [1] = 774, [2] = 8936 }
_G.__keys = { ACTIONBUTTON1 = "Q", ACTIONBUTTON2 = "E" }
_G.HoverCastDB = nil

HC.SpellConfig("Rejuvenation").enabled = true
HC.SpellConfig("Regrowth").enabled = false
SB.apply()
check("enabled spell is bound to its detected key", _G.__bindings["Q"] ~= nil)
check("disabled spell is not bound", _G.__bindings["E"] == nil)
check("one secure button used", SB.usedButtons == 1)

-- The bound button carries the macro, so the click actually casts.
local btn = SB.button(1)
check("button type is macro", btn:GetAttribute("type") == "macro")
check("button macrotext targets mouseover",
  btn:GetAttribute("macrotext") == "/cast [@mouseover] Rejuvenation")

-- A manual key override wins over auto-detection.
HC.SpellConfig("Rejuvenation").key = "F1"
SB.apply()
check("manual key override is used", _G.__bindings["F1"] ~= nil)
check("auto-detected key is dropped when overridden", _G.__bindings["Q"] == nil)

-- A spell that is on no action bar and has no override cannot be bound.
HC.SpellConfig("Rejuvenation").key = nil
_G.__actions = {}
SB.apply()
check("unbindable spell binds nothing", next(_G.__bindings) == nil)
check("no secure buttons used", SB.usedButtons == 0)

-- Combat safety: apply must never touch bindings mid-combat, but must remember.
_G.__actions = { [1] = 774 }
SB.apply()
check("bound again out of combat", _G.__bindings["Q"] ~= nil)
_G.__inCombat = true
_G.__bindings = {}
SB.apply()
check("apply is a no-op in combat", next(_G.__bindings) == nil)
check("apply flags itself pending in combat", SB.pending == true)
SB.request()
check("request stays pending in combat", SB.pending == true)
_G.__inCombat = false
SB.request()
check("request applies once combat ends", _G.__bindings["Q"] ~= nil)
check("pending cleared after applying", SB.pending == false)

return T
