-- Author: Fatalcaleb
-- TestMode.lua
local ADDON, NS = ...

local Root

function NS.GetTestRoot()
  return Root
end

local Buttons = {}
local ticker

local function EnsureRoot()
  if Root then return end
  Root = CreateFrame("Frame", "MidnightHealerTestRoot", UIParent)
  Root:SetFrameStrata("DIALOG")
  Root:Hide()
end

local function Clear()
  for _, b in ipairs(Buttons) do
    b:Hide()
    b:SetParent(nil)
  end
  wipe(Buttons)
end

local function MakeButton(i)
  EnsureRoot()
  local b = CreateFrame("Frame", nil, Root, "BackdropTemplate")
  b:SetBackdrop({ bgFile="Interface\\DialogFrame\\UI-DialogBox-Background" })
  b:SetBackdropColor(0,0,0,0.35)
  b:SetSize(NS.DB.frame.unitWidth, NS.DB.frame.unitHeight)

  b.bar = CreateFrame("StatusBar", nil, b)
  b.bar:SetPoint("TOPLEFT", 2, -2)
  b.bar:SetPoint("BOTTOMRIGHT", -2, 2)
  b.bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
  b.bar:SetMinMaxValues(0, 100)
  b.bar:SetValue(100)

  b.name = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  b.name:SetPoint("LEFT", 24, 0)
  b.name:SetText("Test "..i)

  b.hp = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  b.hp:SetPoint("RIGHT", -6, 0)
  b.hp:SetText("100%")

  b.low = b:CreateTexture(nil, "OVERLAY")
  b.low:SetAllPoints(true)
  b.low:SetColorTexture(1,0,0,0)

  b.group = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.group:SetPoint("TOPRIGHT", -4, -3)
  if kind == "PARTY" then b.group:SetText("P") else b.group:SetText("G"..(math.floor((i-1)/5)+1)) end

  return b
end

local function Snap(v, grid)
  grid = grid or 10
  return math.floor((v / grid) + 0.5) * grid
end

local function Layout()
  EnsureRoot()
  local db = NS.DB.frame
  local mode = db.layoutMode
  local tmode = NS.DB.testMode or {}
  local count = tmode.count or 20
  local kind = tmode.mode or "RAID"

  for i = 1, count do
    Buttons[i] = Buttons[i] or MakeButton(i)
    Buttons[i]:SetSize(db.unitWidth, db.unitHeight)
    Buttons[i]:Show()
  end
  for i = count + 1, #Buttons do
    if Buttons[i] then Buttons[i]:Hide() end
  end

  Root:ClearAllPoints()
  Root:SetPoint(db.point or "CENTER", UIParent, db.point or "CENTER", db.x or 0, db.y or 0)
  Root:SetScale(db.scale or 1)

  local colSpacing = (mode == "GROUPS_8") and (db.groupColumnSpacing or 10) or (db.columnsColumnSpacing or 14)
  local rowSpacing = (mode == "GROUPS_8") and (db.groupRowSpacing or 8) or (db.columnsRowSpacing or 10)
  local unitsPerColumn, maxColumns
  if kind == "PARTY" then
    unitsPerColumn = 5
    maxColumns = 1
  else
    unitsPerColumn = (mode == "GROUPS_8") and 5 or 20
    maxColumns = (mode == "GROUPS_8") and 8 or 2
  end

  for i = 1, count do
    local b = Buttons[i]
    b:ClearAllPoints()
    local idx0 = i - 1
    local col = math.floor(idx0 / unitsPerColumn)
    local row = idx0 % unitsPerColumn
    if col >= maxColumns then col = maxColumns - 1 end
    local x = col * (db.unitWidth + colSpacing)
    local y = -row * (db.unitHeight + rowSpacing)
    b:SetPoint("TOPLEFT", Root, "TOPLEFT", x, y)
    if kind == "PARTY" then b.group:SetText("P") else b.group:SetText("G"..(math.floor((i-1)/5)+1)) end
  end
end

local function Tick()
  for i, b in ipairs(Buttons) do
    if b:IsShown() then
      local v = math.random(25, 100)
      b.bar:SetValue(v)
      b.hp:SetText(v.."%")
      if v <= 35 then b.low:SetAlpha(0.18)
      elseif v <= 55 then b.low:SetAlpha(0.10)
      else b.low:SetAlpha(0) end
    end
  end
end

function NS.RefreshTestLayout()
  if NS.DB.testMode and NS.DB.testMode.enabled then
    Layout()
  end
end

function NS.SetTestMode(enabled)
  EnsureRoot()
  NS.DB.testMode.enabled = enabled and true or false

  local header = _G["MidnightHealerHeader"]
  if enabled then
    if header then header:Hide() end
    Root:Show()
    Layout()
    if ticker then ticker:Cancel() end
    ticker = C_Timer.NewTicker(0.35, Tick)
  else
    if ticker then ticker:Cancel(); ticker=nil end
    Root:Hide()
    if header then header:Show() end
    if NS.RebuildFrames and not InCombatLockdown() then NS.RebuildFrames() end
  end

  if NS.UpdateMoveHandle then NS.UpdateMoveHandle() end
end

function NS.ToggleTestMode(forceOn)
  local on = NS.DB.testMode and NS.DB.testMode.enabled
  if forceOn ~= nil then on = not forceOn end
  NS.SetTestMode(not on)
  if NS.Print then NS.Print("Test mode " .. ((NS.DB.testMode.enabled and "ON") or "OFF") .. ".") end
end
