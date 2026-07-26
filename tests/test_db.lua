-- SavedVariables defaults, per-spell config and the spellbook scan.
local stub = dofile("tests/wow_stub.lua")
stub.install(_G)

stub.loadAddonFile("Core/Log.lua")
stub.loadAddonFile("Core/Init.lua")
stub.loadAddonFile("Core/SpellScan.lua")

local T = {}
local function check(name, cond)
  T[#T + 1] = { name = name, ok = cond and true or false }
  print((cond and "  ok  " or "  FAIL") .. " " .. name)
end

print("test_db")

local HC = _G.HoverCast

-- EnsureDB materialises the whole shape from nothing.
_G.HoverCastDB = nil
local db = HC.EnsureDB()
check("db is created", type(db) == "table")
check("spells table exists", type(db.spells) == "table")
check("minimap is shown by default", db.minimap.hide == false)
check("minimap has a default angle", db.minimap.angle == 210)

-- It repairs a partially-written DB instead of overwriting it.
_G.HoverCastDB = { spells = { Rejuvenation = { enabled = true } }, minimap = { angle = "bad" } }
db = HC.EnsureDB()
check("existing spells survive", db.spells.Rejuvenation.enabled == true)
check("bad angle type is replaced", db.minimap.angle == 210)
check("missing hide flag is filled in", db.minimap.hide == false)

-- SpellConfig hands out defaults on first touch, then the same table.
_G.HoverCastDB = nil
local cfg = HC.SpellConfig("Regrowth")
check("new spell starts disabled", cfg.enabled == false)
check("new spell defaults to any target", cfg.filter == "both")
check("new spell defaults to mouseover only", cfg.fallback == "mouseonly")
check("new spell has no key override", cfg.key == nil)
cfg.enabled = true
check("config is persisted, not rebuilt", HC.SpellConfig("Regrowth").enabled == true)
check("config is stored in the db", _G.HoverCastDB.spells.Regrowth.enabled == true)

-- Defaults must be copied per spell, never shared by reference.
local a = HC.SpellConfig("Rejuvenation")
local b = HC.SpellConfig("Wrath")
a.filter = "help"
check("spell configs are independent", b.filter == "both")
check("the default table is not mutated", HC.DEFAULT_SPELL.filter == "both")

-- SpellScan: walks every tab, drops passives and duplicates, sorts by name.
_G.__numTabs = 2
_G.__tabs = {
  { name = "General", offset = 0, numSpells = 3 },
  { name = "Class",   offset = 3, numSpells = 2 },
}
_G.__book = { [1] = "Wrath", [2] = "Aura Mastery", [3] = "Rejuvenation",
              [4] = "Regrowth", [5] = "Wrath" }
_G.__passive = { [2] = true }

local list = HC.SpellScan.list()
check("scan spans every tab", #list == 3)
check("scan is sorted by name", list[1].name == "Regrowth")
check("scan keeps the second entry sorted", list[2].name == "Rejuvenation")
check("scan keeps the third entry sorted", list[3].name == "Wrath")
check("scan carries an icon", list[1].icon ~= nil)

local names = {}
for _, sp in ipairs(list) do names[sp.name] = (names[sp.name] or 0) + 1 end
check("duplicates are collapsed", names.Wrath == 1)
check("passives are excluded", names["Aura Mastery"] == nil)

-- An empty spellbook is not an error.
_G.__numTabs = 0
check("empty spellbook yields an empty list", #HC.SpellScan.list() == 0)

-- The event dispatcher runs registered handlers and survives a throwing one.
local hits = 0
HC.on = {}
HC.RegisterEvent("UNIT_AURA", function() hits = hits + 1 end)
HC.RegisterEvent("UNIT_AURA", function() error("boom") end)
HC.RegisterEvent("UNIT_AURA", function() hits = hits + 1 end)
HC.dispatch("UNIT_AURA")
check("all handlers run despite one erroring", hits == 2)
check("an unregistered event dispatches harmlessly",
  select(1, pcall(HC.dispatch, "NOPE")) == true)

return T
