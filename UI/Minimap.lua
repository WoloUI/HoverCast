local HC = _G.HoverCast
if not HC then HC = {}; _G.HoverCast = HC end
HC.Minimap = HC.Minimap or {}
local MB = HC.Minimap

-- Places the button on the minimap rim at the given angle (degrees).
local function place(btn, angle)
  local rad = math.rad(angle)
  btn:SetPoint("CENTER", Minimap, "CENTER", 80 * math.cos(rad), 80 * math.sin(rad))
end

-- Creates the minimap button (round icon, draggable).
function MB.create()
  if MB.btn then return end
  local db = HC.EnsureDB()
  local btn = CreateFrame("Button", "HoverCastMinimapButton", Minimap)
  btn:SetWidth(31); btn:SetHeight(31)
  btn:SetFrameStrata("MEDIUM")
  btn:SetMovable(true)

  local icon = btn:CreateTexture(nil, "BACKGROUND")
  icon:SetWidth(20); icon:SetHeight(20)
  icon:SetPoint("CENTER")
  icon:SetTexture("Interface\\Icons\\Ability_Hunter_MarkedForDeath")

  local border = btn:CreateTexture(nil, "OVERLAY")
  border:SetWidth(53); border:SetHeight(53)
  border:SetPoint("TOPLEFT")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

  place(btn, db.minimap.angle)

  -- Dragging: recompute the angle relative to the minimap centre.
  btn:RegisterForDrag("LeftButton")
  btn:SetScript("OnDragStart", function(self) self.dragging = true end)
  btn:SetScript("OnDragStop", function(self) self.dragging = false end)
  btn:SetScript("OnUpdate", function(self)
    if not self.dragging then return end
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    px, py = px / scale, py / scale
    local angle = math.deg(math.atan2(py - my, px - mx))
    db.minimap.angle = angle
    place(self, angle)
  end)

  btn:SetScript("OnClick", function() HC.MainFrame.Toggle() end)
  btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("HoverCast")
    GameTooltip:AddLine("Click: open configuration", 1, 1, 1)
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

  if db.minimap.hide then btn:Hide() end
  MB.btn = btn
end

HC.RegisterEvent("PLAYER_LOGIN", function() HC.safe(MB.create) end)

-- Main slash command.
_G.SLASH_HOVERCAST1 = "/hc"
_G.SLASH_HOVERCAST2 = "/hovercast"
_G.SlashCmdList = _G.SlashCmdList or {}
_G.SlashCmdList["HOVERCAST"] = function(msg)
  msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if msg == "dump" then
    HC.safe(HC.Debug.dump)
  else
    HC.safe(HC.MainFrame.Toggle)
  end
end
