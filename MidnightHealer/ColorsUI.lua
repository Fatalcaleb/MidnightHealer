-- Author: Fatalcaleb
-- ColorsUI.lua
local ADDON, NS = ...

local CLASSES = {
  "WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","DEATHKNIGHT","SHAMAN","MAGE","WARLOCK","MONK","DRUID","DEMONHUNTER","EVOKER",
}
local ROLES = { "TANK", "HEALER", "DAMAGER", "NONE" }
local DEBUFF_TYPES = { "Magic", "Curse", "Disease", "Poison", "None" }

local function Clamp01(x)
  if x < 0 then return 0 elseif x > 1 then return 1 else return x end
end

local function EnsureTables()
  NS.DB.features = NS.DB.features or {}
  local f = NS.DB.features
  f.colorTargets = f.colorTargets or { bar=true, name=false, border=false }
  f.colorSource = f.colorSource or { bar="CLASS", name="NONE", border="NONE" }
  f.customColors = f.customColors or {
    bar = { r=0.10, g=0.80, b=0.10 },
    name = { r=1.00, g=1.00, b=1.00 },
    border = { r=0.90, g=0.90, b=0.90 },
  }
  f.roleColors = f.roleColors or {
    TANK = { r=0.20, g=0.55, b=1.00 },
    HEALER = { r=0.15, g=1.00, b=0.40 },
    DAMAGER = { r=1.00, g=0.25, b=0.25 },
    NONE = { r=0.85, g=0.85, b=0.85 },
  }
  f.classColors = f.classColors or {}
  f.debuffTypeColors = f.debuffTypeColors or {
    Magic = { r=0.20, g=0.60, b=1.00 },
    Curse = { r=0.60, g=0.20, b=1.00 },
    Disease = { r=0.60, g=0.40, b=0.20 },
    Poison = { r=0.10, g=1.00, b=0.10 },
    None = { r=0.90, g=0.90, b=0.90 },
  }
end

local function Repaint()
  if NS.RebuildFrames and not InCombatLockdown() then NS.RebuildFrames() end
  if NS.RefreshTestLayout then NS.RefreshTestLayout() end
end

local function OpenColorPicker(tbl)
  local function Apply()
    local r, g, b = ColorPickerFrame:GetColorRGB()
    tbl.r, tbl.g, tbl.b = Clamp01(r), Clamp01(g), Clamp01(b)
    Repaint()
  end
  ColorPickerFrame.func = Apply
  ColorPickerFrame.hasOpacity = false
  ColorPickerFrame.opacityFunc = nil
  ColorPickerFrame.cancelFunc = Apply
  ColorPickerFrame:SetColorRGB(tbl.r, tbl.g, tbl.b)
  ColorPickerFrame:Hide()
  ColorPickerFrame:Show()
end

local function MakeDropdown(parent, label, x, y, width, values, getVal, setVal)
  local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  fs:SetPoint("TOPLEFT", x, y)
  fs:SetText(label)

  local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
  dd:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", -16, -4)
  UIDropDownMenu_SetWidth(dd, width)

  UIDropDownMenu_Initialize(dd, function(self, level)
    for _, v in ipairs(values) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = v.text
      info.value = v.value
      info.func = function()
        UIDropDownMenu_SetSelectedValue(dd, v.value)
        setVal(v.value)
        Repaint()
      end
      UIDropDownMenu_AddButton(info, level)
    end
  end)

  UIDropDownMenu_SetSelectedValue(dd, getVal())
  return dd
end

local function MakeCheck(parent, label, x, y, getVal, setVal)
  local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  cb:SetPoint("TOPLEFT", x, y)
  cb.text = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  cb.text:SetPoint("LEFT", cb, "RIGHT", 6, 0)
  cb.text:SetText(label)
  cb:SetChecked(getVal())
  cb:SetScript("OnClick", function(self)
    setVal(self:GetChecked() and true or false)
    Repaint()
  end)
  return cb
end

local function MakeButton(parent, label, x, y, onClick)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(200, 22)
  b:SetPoint("TOPLEFT", x, y)
  b:SetText(label)
  b:SetScript("OnClick", onClick)
  return b
end

local function CreateCanvas()
  local canvas = CreateFrame("Frame")
  canvas:SetSize(1, 1)

  EnsureTables()
  local f = NS.DB.features

  local title = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("Colors")

  local sub = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  sub:SetText("Pick what to color (bar/name/border), where the color comes from (class/role/custom/debuff), and customize palettes.")

  -- Targets
  local y0 = -70
  MakeCheck(canvas, "Color health bar", 16, y0, function() return f.colorTargets.bar end, function(v) f.colorTargets.bar = v end)
  MakeCheck(canvas, "Color name text", 16, y0-26, function() return f.colorTargets.name end, function(v) f.colorTargets.name = v end)
  MakeCheck(canvas, "Color frame border", 16, y0-52, function() return f.colorTargets.border end, function(v) f.colorTargets.border = v end)

  local srcValsBar = {
    { value="CLASS", text="Class" },
    { value="ROLE", text="Role" },
    { value="CUSTOM", text="Custom" },
    { value="NONE", text="Off" },
  }
  local srcValsName = srcValsBar
  local srcValsBorder = {
    { value="CLASS", text="Class" },
    { value="ROLE", text="Role" },
    { value="CUSTOM", text="Custom" },
    { value="DEBUFF", text="Debuff type" },
    { value="NONE", text="Off" },
  }

  MakeDropdown(canvas, "Bar source", 260, y0+4, 160, srcValsBar, function() return f.colorSource.bar end, function(v) f.colorSource.bar = v end)
  MakeDropdown(canvas, "Name source", 260, y0-22, 160, srcValsName, function() return f.colorSource.name end, function(v) f.colorSource.name = v end)
  MakeDropdown(canvas, "Border source", 260, y0-48, 160, srcValsBorder, function() return f.colorSource.border end, function(v) f.colorSource.border = v end)

  -- Custom color pickers
  MakeButton(canvas, "Pick Bar Custom Color", 450, y0, function() OpenColorPicker(f.customColors.bar) end)
  MakeButton(canvas, "Pick Name Custom Color", 450, y0-28, function() OpenColorPicker(f.customColors.name) end)
  MakeButton(canvas, "Pick Border Custom Color", 450, y0-56, function() OpenColorPicker(f.customColors.border) end)

  -- Role palette
  local roleTitle = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  roleTitle:SetPoint("TOPLEFT", 16, y0-100)
  roleTitle:SetText("Role Colors (used when a source is set to Role)")

  local ry = y0-124
  for i, role in ipairs(ROLES) do
    MakeButton(canvas, "Pick "..role.." Color", 16 + ((i-1)%2)*220, ry - math.floor((i-1)/2)*28, function()
      OpenColorPicker(f.roleColors[role])
    end)
  end

  -- Debuff palette
  local debTitle = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  debTitle:SetPoint("TOPLEFT", 16, ry-70)
  debTitle:SetText("Debuff Type Colors (border source = Debuff type)")

  local dy = ry-94
  for i, dt in ipairs(DEBUFF_TYPES) do
    MakeButton(canvas, "Pick "..dt.." Border", 16 + ((i-1)%2)*220, dy - math.floor((i-1)/2)*28, function()
      OpenColorPicker(f.debuffTypeColors[dt])
    end)
  end

  -- Class overrides
  local classTitle = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  classTitle:SetPoint("TOPLEFT", 16, dy-98)
  classTitle:SetText("Class Overrides (optional): override Blizzard class colors")

  local cy = dy-122
  for i, cls in ipairs(CLASSES) do
    local x = 16 + ((i-1)%3)*220
    local y = cy - math.floor((i-1)/3)*28
    MakeButton(canvas, "Pick "..cls, x, y, function()
      f.classColors[cls] = f.classColors[cls] or { r=1, g=1, b=1 }
      OpenColorPicker(f.classColors[cls])
    end)
  end

  local note = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  note:SetPoint("TOPLEFT", 16, cy - math.ceil(#CLASSES/3)*28 - 18)
  note:SetWidth(700)
  note:SetJustifyH("LEFT")
  note:SetText("Tip: If you don't set a class override, it uses Blizzard's class colors. Border source 'Debuff type' uses the dispel type (Magic/Curse/Disease/Poison).")

  return canvas
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, _, name)
  if name ~= ADDON then return end
  if not Settings then return end
  local canvas = CreateCanvas()
  local category = Settings.RegisterCanvasLayoutCategory(canvas, "MidnightHealer - Colors")
  Settings.RegisterAddOnCategory(category)
end)
