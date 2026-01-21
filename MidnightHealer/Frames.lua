-- Author: Fatalcaleb
-- Frames.lua
local ADDON, NS = ...

local Driver = CreateFrame("Frame", "MidnightHealerDriver", UIParent)
NS.Driver = Driver

local Header
local GroupLabels = {}

local function ApplyDriverPosition(); if NS.UpdateMoveHandle then NS.UpdateMoveHandle() end
  local db = NS.DB.frame
  t:ClearAllPoints()
  Driver:SetPoint(db.point or "CENTER", UIParent, db.point or "CENTER", db.x or 0, db.y or 0)
  Driver:SetScale(db.scale)
end

local function MakeMovable()
  Driver:SetSize(10, 10)
  Driver:EnableMouse(false)
  -- Driver drag via MoveHandle (see EnsureMoveHandle)
  Driver:SetMovable(true)

  Driver:SetScript("OnDragStart", function(self)
    if NS.DB.frame.locked then return end
    if InCombatLockdown() then return end
    self:StartMoving()
  end)

  Driver:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local db = NS.DB.frame
    local point, _, _, x, y = self:GetPoint(1)
    db.point, db.x, db.y = point, math.floor(x + 0.5), math.floor(y + 0.5)
  end)
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
  EnsureGroupLabels()

  local mode = NS.DB.frame.layoutMode
  local db = NS.DB.frame

  if mode == "GROUPS_8" then
    local colSpacing = 10
    local colStep = db.unitWidth + colSpacing
    for i = 1, 8 do
      GroupLabels[i]:ClearAllPoints()
      GroupLabels[i]:SetPoint("TOPLEFT", Driver, "TOPLEFT", (i - 1) * colStep + 2, 14)
      GroupLabels[i]:Show()
    end
  else
    for i = 1, 8 do
      GroupLabels[i]:Hide()
    end
  end
end


local function Snap(v, grid)
  grid = grid or 10
  return math.floor((v / grid) + 0.5) * grid
end

local MoveHandle

local function EnsureMoveHandle()
  if MoveHandle then return end
  MoveHandle = CreateFrame("Button", "MidnightHealerMoveHandle", UIParent, "BackdropTemplate")
  MoveHandle:SetFrameStrata("DIALOG")
  MoveHandle:SetSize(220, 18)
  MoveHandle:SetBackdrop({
    bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
    tile=true, tileSize=8, edgeSize=12,
    insets={left=2,right=2,top=2,bottom=2}
  })
  MoveHandle:SetBackdropColor(0,0,0,0.6)
  MoveHandle.text = MoveHandle:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  MoveHandle.text:SetPoint("CENTER")
  MoveHandle.text:SetText("MidnightHealer: Drag to move (Unlocked)")
  MoveHandle:EnableMouse(true)
  MoveHandle:RegisterForDrag("LeftButton")
  MoveHandle:SetMovable(true)

  MoveHandle:SetScript("OnDragStart", function(self)
    if NS.DB.frame.locked then return end
    if InCombatLockdown() then return end
    local t = (NS.DB.testMode and NS.DB.testMode.enabled and NS.GetTestRoot and NS.GetTestRoot()) or Driver
    t:StartMoving()
  end)

  MoveHandle:SetScript("OnDragStop", function(self)
    local t = (NS.DB.testMode and NS.DB.testMode.enabled and NS.GetTestRoot and NS.GetTestRoot()) or Driver
    t:StopMovingOrSizing()
    local db = NS.DB.frame
    local t = (NS.DB.testMode and NS.DB.testMode.enabled and NS.GetTestRoot and NS.GetTestRoot()) or Driver
    local point, _, _, x, y = t:GetPoint(1)
    if db.snapToGrid then
      x = Snap(x, db.gridSize)
      y = Snap(y, db.gridSize)
      t:ClearAllPoints()
      t:SetPoint(point, UIParent, point, x, y)
    end
    db.point, db.x, db.y = point, math.floor(x + 0.5), math.floor(y + 0.5)
    ApplyDriverPosition()
    NS.UpdateMoveHandle()
  end)
end

function NS.UpdateMoveHandle()
  EnsureMoveHandle()
  local db = NS.DB.frame
  if db.locked or InCombatLockdown() then
    MoveHandle:Hide()
    return
  end
  -- anchor above the header (or driver if header missing)
  local anchor = ((NS.DB.testMode and NS.DB.testMode.enabled and NS.GetTestRoot and NS.GetTestRoot()) or Header or Driver)
  MoveHandle:ClearAllPoints()
  MoveHandle:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 6)
  MoveHandle:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", 0, 6)
  MoveHandle:Show()
end

function NS.ApplyDriverPosition()
  ApplyDriverPosition()
  if NS.GetTestRoot and NS.DB.testMode and NS.DB.testMode.enabled then
    local r = NS.GetTestRoot()
    if r then
      r:ClearAllPoints()
      r:SetPoint(NS.DB.frame.point or "CENTER", UIParent, NS.DB.frame.point or "CENTER", NS.DB.frame.x or 0, NS.DB.frame.y or 0)
      r:SetScale(NS.DB.frame.scale or 1)
    end
  end
  if NS.UpdateMoveHandle then NS.UpdateMoveHandle() end
end

local function CreateOrRebuildHeader()
  if InCombatLockdown() then return end

  if Header then
    Header:Hide()
    Header:SetParent(nil)
    Header = nil
  end

  local db = NS.DB.frame
  Header = CreateFrame("Frame", "MidnightHealerHeader", Driver, "SecureGroupHeaderTemplate")

  Header:SetAttribute("showParty", true)
  Header:SetAttribute("showRaid", true)
  Header:SetAttribute("showSolo", false)
  Header:SetAttribute("showPlayer", true)

  -- Grouped by raid group
  Header:SetAttribute("groupFilter", "1,2,3,4,5,6,7,8")
  Header:SetAttribute("groupBy", "GROUP")
  Header:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
  Header:SetAttribute("sortMethod", "INDEX")

  -- Layout (switchable)
  local mode = db.layoutMode

  Header:SetAttribute("point", "TOPLEFT")
  Header:SetAttribute("columnAnchorPoint", "TOPLEFT")
  Header:SetAttribute("xOffset", 0)

  if mode == "GROUPS_8" then
    Header:SetAttribute("unitsPerColumn", 5)
    Header:SetAttribute("maxColumns", 8)
    Header:SetAttribute("columnSpacing", 10)
    Header:SetAttribute("yOffset", -8)
  else
    Header:SetAttribute("unitsPerColumn", 20)
    Header:SetAttribute("maxColumns", 2)
    Header:SetAttribute("columnSpacing", 14)
    Header:SetAttribute("yOffset", -10)
  end

  Header:SetAttribute("template", "MidnightHealerUnitButtonTemplate")

  Header:ClearAllPoints()
  Header:SetPoint("TOPLEFT", Driver, "TOPLEFT", 0, 0)
  Header:Show()

  PositionGroupLabels()
end

local function ForEachUnitButton(callback)
  if not Header then return end
  local i = 1
  while true do
    local child = select(i, Header:GetChildren())
    if not child then break end
    callback(child)
    i = i + 1
  end
end


local function MH_Abbrev(n)
  if not n then return "0" end
  if n >= 10000000 then return string.format("%.0fm", n/1000000)
  elseif n >= 1000000 then return string.format("%.1fm", n/1000000)
  elseif n >= 10000 then return string.format("%.0fk", n/1000)
  elseif n >= 1000 then return string.format("%.1fk", n/1000)
  else return tostring(n) end
end

local function MH_FormatHP(unit)
  local feats = NS.DB.features or {}
  if feats.showHpText == false then return "" end
  local mode = feats.hpTextMode or "PERCENT"
  if mode == "NONE" then return "" end
  local hp = UnitHealth(unit) or 0
  local maxhp = UnitHealthMax(unit) or 1
  local pct = (maxhp > 0) and (hp / maxhp) or 0
  local pctTxt = string.format("%d%%", math.floor(pct*100 + 0.5))
  local valTxt = MH_Abbrev(hp)
  if mode == "PERCENT" then return pctTxt
  elseif mode == "VALUE" then return valTxt
  else return pctTxt .. " (" .. valTxt .. ")" end
end


    if btn.NameText then btn.NameText:SetTextColor(1,1,1) end
    if btn.MH_Border then btn.MH_Border:SetVertexColor(0,0,0,0) end
    return
  end

  if targets.bar and btn.HealthBar and colors.bar then
    btn.HealthBar:SetStatusBarColor(colors.bar.r, colors.bar.g, colors.bar.b)
  else
    btn.HealthBar:SetStatusBarColor(0.1, 0.8, 0.1)
  end

  if targets.name and btn.NameText and colors.name then
    btn.NameText:SetTextColor(colors.name.r, colors.name.g, colors.name.b)
  else
    btn.NameText:SetTextColor(1,1,1)
  end

  if targets.border and btn.MH_Border and colors.border then
    btn.MH_Border:SetVertexColor(colors.border.r, colors.border.g, colors.border.b, 0.85)
  elseif btn.MH_Border then
    btn.MH_Border:SetVertexColor(0,0,0,0)
  end
end


local function MH_GetClassColor(unit)
  local feats = NS.DB.features or {}
  local overrides = feats.classColors or {}
  local _, class = UnitClass(unit)
  if class and overrides[class] then
    return overrides[class]
  end
  if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
    return RAID_CLASS_COLORS[class]
  end
  return { r=0.85, g=0.85, b=0.85 }
end

local function MH_GetRoleColor(unit)
  local feats = NS.DB.features or {}
  local rc = feats.roleColors or {}
  local role = UnitGroupRolesAssigned(unit) or "NONE"
  return rc[role] or rc.NONE or { r=0.85, g=0.85, b=0.85 }
end

local function MH_GetCustomColor(key)
  local feats = NS.DB.features or {}
  local cc = feats.customColors or {}
  return cc[key] or { r=1, g=1, b=1 }
end

local function MH_GetDebuffColor(btn)
  local feats = NS.DB.features or {}
  local dc = feats.debuffTypeColors or {}
  local dt = btn.MH_DispelType or "None"
  return dc[dt] or dc.None or { r=0.9, g=0.9, b=0.9 }
end

local function MH_ColorFromSource(btn, key, source)
  if source == "NONE" then return nil end
  if source == "CUSTOM" then return MH_GetCustomColor(key) end
  if source == "ROLE" then return MH_GetRoleColor(btn.unit) end
  if source == "DEBUFF" then return MH_GetDebuffColor(btn) end
  -- CLASS (default)
  return MH_GetClassColor(btn.unit)
end

local function MH_ApplyColors(btn)
  local feats = NS.DB.features or {}
  local targets = feats.colorTargets or { bar=true, name=false, border=false }
  local src = feats.colorSource or {}

  -- Legacy fallback: if colorSource missing, derive from colorMode
  if not feats.colorSource then
    local mode = feats.colorMode or "CLASS"
    src = { bar = mode, name = "NONE", border = "NONE" }
  end

  -- BAR
  if btn.HealthBar then
    if targets.bar then
      local c = MH_ColorFromSource(btn, "bar", src.bar or "CLASS")
      if c then btn.HealthBar:SetStatusBarColor(c.r, c.g, c.b) else btn.HealthBar:SetStatusBarColor(0.1, 0.8, 0.1) end
    else
      btn.HealthBar:SetStatusBarColor(0.1, 0.8, 0.1)
    end
  end

  -- NAME
  if btn.NameText then
    if targets.name then
      local c = MH_ColorFromSource(btn, "name", src.name or "NONE")
      if c then btn.NameText:SetTextColor(c.r, c.g, c.b) else btn.NameText:SetTextColor(1,1,1) end
    else
      btn.NameText:SetTextColor(1,1,1)
    end
  end

  -- BORDER
  if btn.MH_Border then
    if targets.border then
      local c = MH_ColorFromSource(btn, "border", src.border or "NONE")
      if c then btn.MH_Border:SetVertexColor(c.r, c.g, c.b, 0.85) else btn.MH_Border:SetVertexColor(0,0,0,0) end
    else
      btn.MH_Border:SetVertexColor(0,0,0,0)
    end
  end
end

local function SkinUnitButton(btn)
  if btn.MH_Skinned then return end
  btn.MH_Skinned = true

  btn:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", btn.unit)
  btn:RegisterUnitEvent("UNIT_MAXHEALTH", btn.unit)
  btn:RegisterUnitEvent("UNIT_NAME_UPDATE", btn.unit)
  btn:RegisterUnitEvent("UNIT_HEAL_PREDICTION", btn.unit)
  btn:RegisterUnitEvent("UNIT_FLAGS", btn.unit)

  btn:SetScript("OnEvent", function(self)
    local unit = self.unit
    if not unit or not UnitExists(unit) then return end

    local hp = UnitHealth(unit)
    local maxHp = UnitHealthMax(unit)
    local pct = 1
    if maxHp and maxHp > 0 then
      self.HealthBar:SetMinMaxValues(0, maxHp)
      self.HealthBar:SetValue(hp)
      if UpdateIncomingHeals then UpdateIncomingHeals(self) end
      if UpdateCombatIndicator then UpdateCombatIndicator(self) end
      if MH_ApplyColors then MH_ApplyColors(self) end
  do
    local feats = NS.DB.features or {}
    if feats.classColorBars ~= false then
      local _, class = UnitClass(self.unit)
      if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
        local c = RAID_CLASS_COLORS[class]
        self.HealthBar:SetStatusBarColor(c.r, c.g, c.b)
      else
        self.HealthBar:SetStatusBarColor(0.1, 0.8, 0.1)
      end
    else
      self.HealthBar:SetStatusBarColor(0.1, 0.8, 0.1)
    end
  end
      pct = hp / maxHp
    end

    MH_ApplyColors(self)
  self.HpText:SetText(MH_FormatHP(self.unit or self:GetAttribute("unit") or "player"))

    if pct <= 0.35 then
      self.LowHpGlow:SetAlpha(1)
    elseif pct <= 0.55 then
      self.LowHpGlow:SetAlpha(0.5)
    else
      self.LowHpGlow:SetAlpha(0)
    end

    local name = UnitName(unit) or "?"
    self.NameText:SetText(name)
  end)

  btn:GetScript("OnEvent")(btn)
end

local function ApplyFrameSizing()
  local db = NS.DB.frame
  ForEachUnitButton(function(btn)
    btn:SetSize(db.unitWidth, db.unitHeight)
    SkinUnitButton(btn)
  end)
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:SetScript("OnEvent", function()
  if not NS.DB then return end
  ApplyDriverPosition()

  if not InCombatLockdown() then
    CreateOrRebuildHeader()
    ApplyFrameSizing()
  end
end)

function NS.RebuildFrames()
  if InCombatLockdown() then return end
  ApplyDriverPosition()
  CreateOrRebuildHeader()
  ApplyFrameSizing()
end

local init = CreateFrame("Frame")
init:RegisterEvent("ADDON_LOADED")
init:SetScript("OnEvent", function(_, _, name)
  if name ~= ADDON then return end
  if not NS.DB then return end
  ApplyDriverPosition()
  MakeMovable()
end)


local function UpdateIncomingHeals(btn)
  local feats = (NS.DB and NS.DB.features) or {}
  local opt = feats.incomingHeals or { enabled=true, warnPct=0.25, tankBoost=true, normal={r=0.2,g=1,b=0.2,a=0.35}, warn={r=1,g=0.85,b=0.2,a=0.55} }
  if not btn.IncomingHealBar then return end
  if opt.enabled == false then
    btn.IncomingHealBar:SetValue(0)
    btn.IncomingHealBar:SetAlpha(0)
    return
  end
  local inc = UnitGetIncomingHeals(btn.unit) or 0
  local hp = UnitHealth(btn.unit) or 0
  local maxhp = UnitHealthMax(btn.unit) or 1
  btn.IncomingHealBar:SetMinMaxValues(0, maxhp)
  local total = math.min(hp + inc, maxhp)
  btn.IncomingHealBar:SetValue(total)
  local incPct = (maxhp > 0) and (inc / maxhp) or 0
  local warn = incPct >= (opt.warnPct or 0.25)
  local c = warn and (opt.warn or {}) or (opt.normal or {})
  local a = c.a or (warn and 0.55 or 0.35)
  if opt.tankBoost and UnitGroupRolesAssigned(btn.unit) == "TANK" then
    a = math.min(1, a + 0.20)
  end
  btn.IncomingHealBar:SetStatusBarColor(c.r or 0.2, c.g or 1.0, c.b or 0.2)
  btn.IncomingHealBar:SetAlpha(a)
end

local function UpdateCombatIndicator(btn)
  if not btn.CombatGlow then return end
  local feats = (NS.DB and NS.DB.features) or {}
  local opt = feats.combatIndicator or { enabled=true, a=0.20 }
  if opt.enabled == false then btn.CombatGlow:SetAlpha(0); return end
  if UnitAffectingCombat(btn.unit) then btn.CombatGlow:SetAlpha(opt.a or 0.20) else btn.CombatGlow:SetAlpha(0) end
end
end
