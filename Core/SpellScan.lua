local HC = _G.HoverCast
if not HC then HC = {}; _G.HoverCast = HC end
HC.SpellScan = HC.SpellScan or {}
local SS = HC.SpellScan

-- Walks every spellbook tab and returns the player's usable spells as
-- {name, icon}, sorted by name, deduplicated, passives excluded.
-- Uses the native 3.3.5a API (GetSpellName/GetSpellTexture) and never assumes
-- a class (Ascension is classless).
function SS.list()
  local seen, out = {}, {}
  local numTabs = GetNumSpellTabs() or 0
  for tab = 1, numTabs do
    local _, _, offset, numSpells = GetSpellTabInfo(tab)
    offset = offset or 0
    numSpells = numSpells or 0
    for i = offset + 1, offset + numSpells do
      local name = GetSpellName(i, BOOKTYPE_SPELL)
      if name and not seen[name] and not IsPassiveSpell(i, BOOKTYPE_SPELL) then
        seen[name] = true
        out[#out + 1] = { name = name, icon = GetSpellTexture(i, BOOKTYPE_SPELL) }
      end
    end
  end
  table.sort(out, function(a, b) return a.name < b.name end)
  return out
end
