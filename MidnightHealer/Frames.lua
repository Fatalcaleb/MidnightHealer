-- Author: Fatalcaleb
-- Frames.lua
-- WoW Midnight 12.1 compatibility pass.
local ADDON, NS = ...

local Driver = CreateFrame("Frame", "MidnightHealerDriver", UIParent)
NS.Driver = Driver

local Header
local GroupLabels = {}
local MoveHandle

local function GetFrameDB()
  return NS.DB and NS.DB.frame
end

local function GetButtonUnit(btn)
  if not btn then return nil end
  local unit = btn:GetAttribute("unit") or btn.unit
  if unit then btn.unit = unit end
  return unit
end

local function ApplyDriverPosition()
  local db = GetFrameDB()
  if not db then return end

  Driver:ClearAllPoints()
  Driver:SetPoint(db.point or "CENTER", UIParent, db.point or "CENTER", db.x or 0, db.y or 0)
  Driver:SetScale(db.scale or 1)
end

local function MakeMovable()
  Driver:SetSize(10, 10)
  Driver:SetMovable(true)
  Driver:EnableMouse(false)
end

local function EnsureGroupLabels()
  if GroupLabels[1] then return end
  for i = 1, 8 do
    local fs = Driver:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetText("Group " .. i)
    fs:Hide()
    GroupLabels[i] = fs
  end
end

local function PositionGroupLabels()
  local db = GetFrameDB()
  if not db then return end

  EnsureGroupLabels()
  local showLabels = (NS.DB.features or {}).showGroupLabels ~= false

  if db.layoutMode == "GROUPS_8" and showLabels then
    local colSpacing = db.groupColumnSpacing or 10
    local colStep = (db.unitWidth or 220) + colSpacing
    for i = 1, 8 do
      GroupLabels[i]:ClearAllPoints()
      GroupLabels[i]:SetPoint("TOPLEFT", Driver, "TOPLEFT", (i - 1) * colStep + 2, 14)
      GroupLabels[i]:Show()
    end
  else
    for i = 1, 8 do GroupLabels[i]:Hide() end
  end
end

local function Snap(v, grid)
  grid = grid or 10
  return math.floor((v / grid) + 0.5) * grid
end

local function EnsureMoveHandle()
  if MoveHandle then return end

  MoveHandle = CreateFrame("Button", "MidnightHealerMoveHandle", UIParent, "BackdropTemplate")
  MoveHandle:SetFrameStrata("DIALOG")
  MoveHandle:SetSize(220, 18)
  MoveHandle:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 12,
    insets = { left=2, right=2, top=2, bottom=2 },
  })
  MoveHandle:SetBackdropColor(0, 0, 0, 0.6)
  MoveHandle.text = MoveHandle:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  MoveHandle.text:SetPoint("CENTER")
  MoveHandle.text:SetText("MidnightHealer: Drag to move (Unlocked)")
  MoveHandle:EnableMouse(true)
  MoveHandle:RegisterForDrag("LeftButton")

  MoveHandle:SetScript("OnDragStart", function()
    local db = GetFrameDB()
    if not db or db.locked or InCombatLockdown() then return end
    Driver:StartMoving()
  end)

  MoveHandle:SetScript("OnDragStop", function()
    local db = GetFrameDB()
    if not db then return end

    Driver:StopMovingOrSizing()
    local point, _, _, x, y = Driver:GetPoint(1)
    point = point or "CENTER"
    x, y = x or 0, y or 0

    if db.snapToGrid then
      x = Snap(x, db.gridSize)
      y = Snap(y, db.gridSize)
    end

    db.point = point
    db.x = math.floor(x + 0.5)
    db.y = math.floor(y + 0.5)
    ApplyDriverPosition()
    if NS.UpdateMoveHandle then NS.UpdateMoveHandle() end
  end)
end

function NS.UpdateMoveHandle()
  local db = GetFrameDB()
  if not db then return end

  EnsureMoveHandle()
  if db.locked or InCombatLockdown() then
    MoveHandle:Hide()
    return
  end

  local anchor = Header or Driver
  MoveHandle:ClearAllPoints()
  MoveHandle:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 6)
  MoveHandle:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", 0, 6)
  MoveHandle:Show()
end

function NS.ApplyDriverPosition()
  ApplyDriverPosition()

  if NS.GetTestRoot and NS.DB and NS.DB.testMode and NS.DB.testMode.enabled then
    local r = NS.GetTestRoot()
    if r then
      r:ClearAllPoints()
      r:SetPoint(NS.DB.frame.point or "CENTER", UIParent, NS.DB.frame.point or "CENTER", NS.DB.frame.x or 0, NS.DB.frame.y or 0)
      r:SetScale(NS.DB.frame.scale or 1)
    end
  end

  if NS.UpdateMoveHandle then NS.UpdateMoveHandle() end
end

local function CreateOrConfigureHeader()
  if InCombatLockdown() then return false end
  local db = GetFrameDB()
  if not db then return false end

  if not Header then
    Header = CreateFrame("Frame", "MidnightHealerHeader", Driver, "SecureGroupHeaderTemplate")
  end

  Header:SetAttribute("showParty", true)
  Header:SetAttribute("showRaid", true)
  Header:SetAttribute("showSolo", false)
  Header:SetAttribute("showPlayer", true)
  Header:SetAttribute("groupFilter", "1,2,3,4,5,6,7,8")
  Header:SetAttribute("groupBy", "GROUP")
  Header:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
  Header:SetAttribute("sortMethod", "INDEX")
  Header:SetAttribute("point", "TOPLEFT")
  Header:SetAttribute("columnAnchorPoint", "TOPLEFT")
  Header:SetAttribute("xOffset", 0)

  if db.layoutMode == "GROUPS_8" then
    Header:SetAttribute("unitsPerColumn", 5)
    Header:SetAttribute("maxColumns", 8)
    Header:SetAttribute("columnSpacing", db.groupColumnSpacing or 10)
    Header:SetAttribute("yOffset", -(db.groupRowSpacing or 8))
  else
    Header:SetAttribute("unitsPerColumn", 20)
    Header:SetAttribute("maxColumns", 2)
    Header:SetAttribute("columnSpacing", db.columnsColumnSpacing or 14)
    Header:SetAttribute("yOffset", -(db.columnsRowSpacing or 10))
  end

  Header:SetAttribute("template", "MidnightHealerUnitButtonTemplate")
  Header:ClearAllPoints()
  Header:SetPoint("TOPLEFT", Driver, "TOPLEFT", 0, 0)
  Header:Show()
  PositionGroupLabels()
  return true
end

local function ForEachUnitButton(callback)
  if not Header then return end
  local children = { Header:GetChildren() }
  for _, child in ipairs(children) do
    if child and child.GetAttribute and child:GetAttribute("unit") then
      callback(child)
    end
  end
end

local function GetClassColor(unit)
  local feats = NS.DB.features or {}
  local overrides = feats.classColors or {}
  local _, class = UnitClass(unit)
  if class and overrides[class] then return overrides[class] end
  if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then return RAID_CLASS_COLORS[class] end
  return { r=0.10, g=0.80, b=0.10 }
end

local function GetRoleColor(unit)
  local feats = NS.DB.features or {}
  local roleColors = feats.roleColors or {}
  local role = UnitGroupRolesAssigned(unit) or "NONE"
  return roleColors[role] or roleColors.NONE or { r=0.85, g=0.85, b=0.85 }
end

local function GetCustomColor(key)
  local colors = (NS.DB.features or {}).customColors or {}
  return colors[key] or { r=1, g=1, b=1 }
end

local function ColorFromSource(unit, key, source)
  if source == "NONE" or source == "DEBUFF" then return nil end
  if source == "CUSTOM" then return GetCustomColor(key) end
  if source == "ROLE" then return GetRoleColor(unit) end
  return GetClassColor(unit)
end

local function ApplyColors(btn)
  local unit = GetButtonUnit(btn)
  if not unit then return end

  local feats = NS.DB.features or {}
  local targets = feats.colorTargets or { bar=true, name=false, border=false }
  local source = feats.colorSource or { bar=feats.colorMode or "CLASS", name="NONE", border="NONE" }

  if btn.HealthBar then
    local c = targets.bar and ColorFromSource(unit, "bar", source.bar or "CLASS") or nil
    if c then btn.HealthBar:SetStatusBarColor(c.r, c.g, c.b)
    else btn.HealthBar:SetStatusBarColor(0.10, 0.80, 0.10) end
  end

  if btn.NameText then
    local c = targets.name and ColorFromSource(unit, "name", source.name or "NONE") or nil
    if c then btn.NameText:SetTextColor(c.r, c.g, c.b)
    else btn.NameText:SetTextColor(1, 1, 1) end
  end

  if btn.Border then
    local c = targets.border and ColorFromSource(unit, "border", source.border or "NONE") or nil
    if c then btn.Border:SetVertexColor(c.r, c.g, c.b, 0.9)
    else btn.Border:SetVertexColor(0.2, 0.2, 0.2, 0.9) end
  end
end

local function UpdateUnitButton(btn)
  local unit = GetButtonUnit(btn)
  if not unit or not UnitExists(unit) then return end

  -- 12.1 may return secret health values in restricted content. Passing those
  -- values directly into a StatusBar is supported; doing arithmetic/comparisons
  -- on them is not. Do not derive percentages or low-health thresholds here.
  if btn.HealthBar then
    local maxHp = UnitHealthMax(unit)
    local hp = UnitHealth(unit)
    btn.HealthBar:SetMinMaxValues(0, maxHp)
    btn.HealthBar:SetValue(hp)
  end

  if btn.HpText then btn.HpText:SetText("") end
  if btn.LowHpGlow then btn.LowHpGlow:SetAlpha(0) end

  if btn.NameText then
    btn.NameText:SetText(UnitName(unit) or "?")
  end

  ApplyColors(btn)
end

local function SkinUnitButton(btn)
  local unit = GetButtonUnit(btn)
  if not unit then return end

  if not btn.MH_Skinned then
    btn.MH_Skinned = true
    btn:RegisterUnitEvent("UNIT_HEALTH", unit)
    btn:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
    btn:RegisterUnitEvent("UNIT_NAME_UPDATE", unit)
    btn:RegisterUnitEvent("UNIT_FLAGS", unit)
    btn:SetScript("OnEvent", function(self)
      UpdateUnitButton(self)
    end)
  end

  local db = GetFrameDB()
  if db and not InCombatLockdown() then
    btn:SetSize(db.unitWidth or 220, db.unitHeight or 44)
  end

  UpdateUnitButton(btn)
end

local function ApplyFrameSizing()
  if InCombatLockdown() then return end
  ForEachUnitButton(SkinUnitButton)
end

local function RefreshFrames()
  if not NS.DB then return end
  ApplyDriverPosition()

  if not InCombatLockdown() then
    CreateOrConfigureHeader()
    ApplyFrameSizing()
    if NS.ReapplyClickCast then NS.ReapplyClickCast() end
  end

  if NS.UpdateMoveHandle then NS.UpdateMoveHandle() end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:SetScript("OnEvent", function()
  RefreshFrames()
end)

function NS.RebuildFrames()
  if InCombatLockdown() then
    if NS.RequestSecureApply then NS.RequestSecureApply() end
    return
  end
  RefreshFrames()
end

local init = CreateFrame("Frame")
init:RegisterEvent("ADDON_LOADED")
init:SetScript("OnEvent", function(_, _, name)
  if name ~= ADDON then return end
  MakeMovable()
  if NS.DB then RefreshFrames() end
end)
