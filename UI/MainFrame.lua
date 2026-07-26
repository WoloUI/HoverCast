local HC = _G.HoverCast
if not HC then HC = {}; _G.HoverCast = HC end
HC.MainFrame = HC.MainFrame or {}
local MF = HC.MainFrame

local SOLID = "Interface\\ChatFrame\\ChatFrameBackground"
local ROW_H, MAX_ROWS = 26, 12
local frame

-- Applies the ElvUI skin to a frame when ElvUI is present (optional).
local function skinIfElvUI(f)
  local E = _G.ElvUI and _G.ElvUI[1]
  if E and E.GetModule then
    local S = E:GetModule("Skins", true)
    if S and S.HandleFrame then pcall(S.HandleFrame, S, f) end
  end
end

-- Builds the window once: title, close button, search box and scrollable list.
local function build()
  frame = CreateFrame("Frame", "HoverCastFrame", UIParent)
  frame:SetWidth(520); frame:SetHeight(ROW_H * MAX_ROWS + 84)
  frame:SetPoint("CENTER")
  frame:SetBackdrop({ bgFile = SOLID, edgeFile = SOLID, tile = false, edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 } })
  frame:SetBackdropColor(0.05, 0.05, 0.07, 0.96)
  frame:SetBackdropBorderColor(0.16, 0.16, 0.20, 1)
  frame:SetFrameStrata("HIGH")
  frame:SetMovable(true); frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", frame, "TOP", 0, -8)
  title:SetText("HoverCast")

  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

  -- Search box.
  local search = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
  search:SetWidth(200); search:SetHeight(20)
  search:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -36)
  search:SetAutoFocus(false)
  frame.search = search

  -- "Only enabled" filter: when checked, the list shows enabled spells only.
  local onlyEnabled = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
  onlyEnabled:SetWidth(22); onlyEnabled:SetHeight(22)
  onlyEnabled:SetPoint("LEFT", search, "RIGHT", 14, 0)
  local oeLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  oeLabel:SetPoint("LEFT", onlyEnabled, "RIGHT", 2, 0)
  oeLabel:SetText("Only enabled")
  onlyEnabled:SetScript("OnClick", function()
    local sb = _G["HoverCastScrollScrollBar"]
    if sb then sb:SetValue(0) end
    frame:Populate()
  end)
  frame.onlyEnabled = onlyEnabled

  -- Row container.
  local list = CreateFrame("Frame", nil, frame)
  list:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -62)
  list:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 12)
  frame.list = list

  -- FauxScrollFrame: the standard 3.3.5a scrollbar. Reuses a fixed row pool
  -- (only the data shown changes, driven by the scroll offset).
  local scroll = CreateFrame("ScrollFrame", "HoverCastScroll", list,
    "FauxScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", list, "TOPLEFT", 0, 0)
  scroll:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -28, 0)
  frame.scroll = scroll

  frame.rows = {}
  for i = 1, MAX_ROWS do
    local row = HC.SpellRow.create(list)
    row:SetWidth(462)  -- leaves ~28px on the right for the scrollbar
    row:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -(i - 1) * ROW_H)
    row:Hide()
    frame.rows[i] = row
  end

  -- Paints the visible window (per the scroll offset) onto the rows.
  function frame:Refresh()
    local items = self.filtered or {}
    local offset = FauxScrollFrame_GetOffset(self.scroll)
    for i = 1, MAX_ROWS do
      local sp = items[offset + i]
      local row = self.rows[i]
      if sp then row:SetData(sp); row:Show() else row:Hide() end
    end
    FauxScrollFrame_Update(self.scroll, #items, MAX_ROWS, ROW_H)
  end

  -- Recomputes the list filtered by the search box and by "only enabled", then
  -- refreshes. Reads db.spells directly (not HC.SpellConfig) so merely browsing
  -- does not create a config entry for every spell you own.
  function frame:Populate()
    local all = HC.SpellScan.list()
    local q = (self.search:GetText() or ""):lower()
    local db = HC.EnsureDB()
    local onlyEnabled = self.onlyEnabled and self.onlyEnabled:GetChecked()
    local filtered = {}
    for _, sp in ipairs(all) do
      local matchesText = (q == "" or sp.name:lower():find(q, 1, true))
      local cfg = db.spells[sp.name]
      local matchesEnabled = (not onlyEnabled) or (cfg and cfg.enabled and true or false)
      if matchesText and matchesEnabled then
        filtered[#filtered + 1] = sp
      end
    end
    self.filtered = filtered
    self:Refresh()
  end

  -- Dragging the scrollbar: only repaint the visible window.
  scroll:SetScript("OnVerticalScroll", function(self, offset)
    FauxScrollFrame_OnVerticalScroll(self, offset, ROW_H, function() frame:Refresh() end)
  end)

  -- Mouse-wheel scrolling (one row per notch).
  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel", function(self, delta)
    local sb = _G[self:GetName() .. "ScrollBar"]
    if sb then sb:SetValue(sb:GetValue() - delta * ROW_H) end
  end)

  -- On filter change, jump back to the top and repopulate.
  search:SetScript("OnTextChanged", function()
    local sb = _G["HoverCastScrollScrollBar"]
    if sb then sb:SetValue(0) end
    frame:Populate()
  end)
  skinIfElvUI(frame)
  frame:Hide()
end

-- Reapplies the current filter/list if the window exists and is visible.
-- Called by the rows when a spell is (un)checked so "only enabled" reflects the
-- change instantly (keeps the scroll position).
function MF.Repopulate()
  if frame and frame:IsShown() then frame:Populate() end
end

-- Shows/hides the window (building it the first time) and refreshes the list.
function MF.Toggle()
  if not frame then build() end
  if frame:IsShown() then
    frame:Hide()
  else
    frame:Populate()
    frame:Show()
  end
end
