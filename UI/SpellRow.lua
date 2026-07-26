local HC = _G.HoverCast
if not HC then HC = {}; _G.HoverCast = HC end
HC.SpellRow = HC.SpellRow or {}
local SR = HC.SpellRow

local SOLID = "Interface\\ChatFrame\\ChatFrameBackground"
local ROW_H = 26

-- Short labels for the filter and fallback cycles.
local FILTERS  = { "help", "harm", "both" }
local FILTER_LABEL = { help = "Friendly", harm = "Hostile", both = "Any" }
local FALLBACKS = { "target", "targetself", "mouseonly" }
local FALLBACK_LABEL = { target = "Target", targetself = "Target+Self", mouseonly = "Mouseover only" }

-- Advances to the next value of a circular list.
local function nextIn(list, cur)
  for i, v in ipairs(list) do
    if v == cur then return list[(i % #list) + 1] end
  end
  return list[1]
end

-- Text button with a dark backdrop (internal helper).
local function makeButton(parent, w, text)
  local b = CreateFrame("Button", nil, parent)
  b:SetWidth(w); b:SetHeight(20)
  b:SetBackdrop({ bgFile = SOLID, edgeFile = SOLID, tile = false, edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 } })
  b:SetBackdropColor(0.12, 0.12, 0.16, 1)
  b:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
  b.txt = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  b.txt:SetAllPoints(b)
  b.txt:SetText(text)
  return b
end

-- Creates a configurable row. Fill it with row:SetData(spell) + row:Refresh().
function SR.create(parent)
  local row = CreateFrame("Frame", nil, parent)
  row:SetHeight(ROW_H)

  local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
  check:SetWidth(20); check:SetHeight(20)
  check:SetPoint("LEFT", row, "LEFT", 2, 0)
  row.check = check

  local icon = row:CreateTexture(nil, "ARTWORK")
  icon:SetWidth(18); icon:SetHeight(18)
  icon:SetPoint("LEFT", check, "RIGHT", 4, 0)
  row.icon = icon

  local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  name:SetPoint("LEFT", icon, "RIGHT", 6, 0)
  name:SetWidth(150); name:SetJustifyH("LEFT")
  row.name = name

  local filterBtn   = makeButton(row, 64, "Friendly")
  filterBtn:SetPoint("LEFT", name, "RIGHT", 6, 0)
  row.filterBtn = filterBtn

  local fallbackBtn = makeButton(row, 104, "Target")
  fallbackBtn:SetPoint("LEFT", filterBtn, "RIGHT", 4, 0)
  row.fallbackBtn = fallbackBtn

  local keyBtn = makeButton(row, 70, "-")
  keyBtn:SetPoint("LEFT", fallbackBtn, "RIGHT", 4, 0)
  row.keyBtn = keyBtn
  keyBtn:EnableKeyboard(false)

  -- Refreshes the texts from the current spell's saved config.
  function row:Refresh()
    local cfg = HC.SpellConfig(self.spellName)
    self.check:SetChecked(cfg.enabled)
    self.filterBtn.txt:SetText(FILTER_LABEL[cfg.filter])
    self.fallbackBtn.txt:SetText(FALLBACK_LABEL[cfg.fallback])
    local key = cfg.key
    if not key or key == "" then key = HC.BindDetect.keyForSpell(self.spellName) end
    self.keyBtn.txt:SetText(key and key ~= "" and key or "set key")
  end

  -- Binds a spell to the row and refreshes it.
  function row:SetData(spell)
    self.spellName = spell.name
    self.name:SetText(spell.name)
    if spell.icon then self.icon:SetTexture(spell.icon) end
    self:Refresh()
  end

  -- Interaction: every control mutates the DB and asks for a reapply.
  check:SetScript("OnClick", function(self)
    HC.SpellConfig(row.spellName).enabled = self:GetChecked() and true or false
    HC.SecureBinder.request()
    -- Refresh the window so the "only enabled" filter reacts on the fly.
    if HC.MainFrame and HC.MainFrame.Repopulate then HC.MainFrame.Repopulate() end
  end)
  filterBtn:SetScript("OnClick", function()
    local cfg = HC.SpellConfig(row.spellName)
    cfg.filter = nextIn(FILTERS, cfg.filter)
    row:Refresh(); HC.SecureBinder.request()
  end)
  fallbackBtn:SetScript("OnClick", function()
    local cfg = HC.SpellConfig(row.spellName)
    cfg.fallback = nextIn(FALLBACKS, cfg.fallback)
    row:Refresh(); HC.SecureBinder.request()
  end)
  -- keyBtn: a click starts capture mode and the next key pressed is saved as the
  -- override. Right-click clears it (back to auto-detection).
  keyBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  keyBtn:SetScript("OnClick", function(self, button)
    if button == "RightButton" then
      HC.SpellConfig(row.spellName).key = nil
      row:Refresh(); HC.SecureBinder.request()
      return
    end
    self.txt:SetText("press a key...")
    self:EnableKeyboard(true)
    self:SetPropagateKeyboardInput(false)
  end)
  keyBtn:SetScript("OnKeyDown", function(self, key)
    self:EnableKeyboard(false)
    if key ~= "ESCAPE" then HC.SpellConfig(row.spellName).key = key end
    row:Refresh(); HC.SecureBinder.request()
  end)

  return row
end
