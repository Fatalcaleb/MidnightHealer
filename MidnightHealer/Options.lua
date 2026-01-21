-- Author: Fatalcaleb
-- Options.lua
local ADDON, NS = ...

local MODS = { "NONE", "SHIFT", "CTRL", "ALT" }
local BUTTONS = {
  { key="BUTTON1", label="Left" },
  { key="BUTTON2", label="Right" },
  { key="BUTTON3", label="Middle" },
  { key="BUTTON4", label="Button4" },
  { key="BUTTON5", label="Button5" },
  { key="MOUSEWHEELUP", label="WheelUp" },
  { key="MOUSEWHEELDOWN", label="WheelDown" },
}

local function MakeKey(mod, buttonKey)
  if mod == "NONE" then return buttonKey end
  return mod .. "-" .. buttonKey
end

local function NormalizeSpellText(s)
  s = (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if s == "" then return nil end
  return s
end

local function ApplyBindingsNowOrQueue()
  if NS.RequestSecureApply and not NS.RequestSecureApply() then return end
  if NS.ReapplyClickCast then NS.ReapplyClickCast() end
end

-- ---------- Bindings (typing grid) ----------
local function CreateBindingsCanvas()
  local canvas = CreateFrame("Frame")
  canvas:SetSize(1, 1)

  local title = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("Bindings (VuhDo-style)")

  local sub = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  sub:SetText("Type spell names. Leave blank to clear. Secure changes apply out of combat.")

  local startX, startY = 16, -70
  local colW = 160
  local rowH = 30

  local function AddHeader(text, x, y)
    local fs = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetText(text)
    return fs
  end

  AddHeader("Mouse", startX, startY)
  for i, mod in ipairs(MODS) do
    AddHeader(mod, startX + (i * colW), startY)
  end

  local inputs = {}

  local function CreateEditBox(x, y, initial)
    local eb = CreateFrame("EditBox", nil, canvas, "InputBoxTemplate")
    eb:SetSize(colW - 18, 20)
    eb:SetPoint("TOPLEFT", x, y)
    eb:SetAutoFocus(false)
    eb:SetText(initial or "")
    eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    return eb
  end

  local function CreateRow(rowIndex, button)
    local y = startY - 10 - (rowIndex * rowH)
    local label = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("TOPLEFT", startX, y)
    label:SetText(button.label)

    inputs[button.key] = inputs[button.key] or {}
    for i, mod in ipairs(MODS) do
      local key = MakeKey(mod, button.key)
      local val = NS.DB.bindings[key] or ""
      local eb = CreateEditBox(startX + (i * colW), y + 2, val)
      inputs[button.key][mod] = eb

      eb:SetScript("OnEditFocusLost", function(self)
        local newVal = NormalizeSpellText(self:GetText())
        if newVal then NS.DB.bindings[key] = newVal else NS.DB.bindings[key] = nil end
        ApplyBindingsNowOrQueue()
      end)
    end
  end

  for idx, btn in ipairs(BUTTONS) do CreateRow(idx, btn) end
  return canvas
end

-- ---------- Bind Picker (dropdown spell selection) ----------
local function BuildKnownSpellList()
  local spells, seen = {}, {}
  for tab = 1, GetNumSpellTabs() do
    local _, _, offset, numSpells = GetSpellTabInfo(tab)
    for i = 1, numSpells do
      local spellBookIndex = offset + i
      local spellType, spellID = GetSpellBookItemInfo(spellBookIndex, BOOKTYPE_SPELL)
      if spellType == "SPELL" and spellID then
        local name = GetSpellInfo(spellID)
        if name and not seen[name] then
          seen[name] = true
          spells[#spells+1] = name
        end
      end
    end
  end
  table.sort(spells)
  return spells
end

local function CreateBindPickerCanvas()
  local canvas = CreateFrame("Frame")
  canvas:SetSize(1, 1)

  local title = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("Bind Picker")

  local sub = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  sub:SetText("Select a modifier + mouse input + spell from your spellbook, then Assign.")

  local known = BuildKnownSpellList()

  local function MakeDropdown(label, x, y, width, getValuesFn)
    local fs = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetText(label)

    local dd = CreateFrame("Frame", nil, canvas, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", -16, -4)
    UIDropDownMenu_SetWidth(dd, width)

    dd.selected = nil
    dd.getValues = getValuesFn

    UIDropDownMenu_Initialize(dd, function(self, level)
      local values = dd.getValues()
      for _, v in ipairs(values) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = v.text
        info.value = v.value
        info.func = function()
          dd.selected = v.value
          UIDropDownMenu_SetSelectedValue(dd, v.value)
        end
        UIDropDownMenu_AddButton(info, level)
      end
    end)

    return dd
  end

  local modDD = MakeDropdown("Modifier", 16, -80, 140, function()
    local t = {}
    for _, m in ipairs(MODS) do t[#t+1] = { value=m, text=m } end
    return t
  end)

  local btnDD = MakeDropdown("Mouse input", 250, -80, 140, function()
    local t = {}
    for _, b in ipairs(BUTTONS) do t[#t+1] = { value=b.key, text=b.label } end
    return t
  end)

  local spellDD = MakeDropdown("Spell", 480, -80, 240, function()
    local t = { { value="__NONE__", text="(clear binding)" } }
    for _, n in ipairs(known) do t[#t+1] = { value=n, text=n } end
    return t
  end)

  UIDropDownMenu_SetSelectedValue(modDD, "NONE"); modDD.selected = "NONE"
  UIDropDownMenu_SetSelectedValue(btnDD, "BUTTON1"); btnDD.selected = "BUTTON1"
  UIDropDownMenu_SetSelectedValue(spellDD, "__NONE__"); spellDD.selected = "__NONE__"

  local assignBtn = CreateFrame("Button", nil, canvas, "UIPanelButtonTemplate")
  assignBtn:SetSize(140, 24)
  assignBtn:SetPoint("TOPLEFT", 16, -160)
  assignBtn:SetText("Assign")

  local status = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  status:SetPoint("LEFT", assignBtn, "RIGHT", 10, 0)
  status:SetText("")

  local refreshBtn = CreateFrame("Button", nil, canvas, "UIPanelButtonTemplate")
  refreshBtn:SetSize(160, 24)
  refreshBtn:SetPoint("TOPLEFT", assignBtn, "BOTTOMLEFT", 0, -10)
  refreshBtn:SetText("Refresh Spell List")

  local function KeyFor(mod, btn)
    if mod == "NONE" then return btn end
    return mod .. "-" .. btn
  end

  assignBtn:SetScript("OnClick", function()
    local mod = modDD.selected or "NONE"
    local btn = btnDD.selected or "BUTTON1"
    local spell = spellDD.selected or "__NONE__"
    local key = KeyFor(mod, btn)

    if spell == "__NONE__" then
      NS.DB.bindings[key] = nil
      status:SetText("Cleared: " .. key)
    else
      NS.DB.bindings[key] = spell
      status:SetText("Set: " .. key .. " = " .. spell)
    end
    ApplyBindingsNowOrQueue()
  end)

  refreshBtn:SetScript("OnClick", function()
    known = BuildKnownSpellList()
    UIDropDownMenu_Initialize(spellDD, function(self, level)
      local values = { { value="__NONE__", text="(clear binding)" } }
      for _, n in ipairs(known) do values[#values+1] = { value=n, text=n } end
      for _, v in ipairs(values) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = v.text
        info.value = v.value
        info.func = function()
          spellDD.selected = v.value
          UIDropDownMenu_SetSelectedValue(spellDD, v.value)
        end
        UIDropDownMenu_AddButton(info, level)
      end
    end)
    UIDropDownMenu_SetSelectedValue(spellDD, "__NONE__"); spellDD.selected = "__NONE__"
    status:SetText("Spell list refreshed.")
  end)

  return canvas
end

-- ---------- Main Settings ----------
local function RegisterMainCategory()
  local category = Settings.RegisterVerticalLayoutCategory("MidnightHealer")

  local function AddCheckbox(tbl, field, label, tooltip, onChanged)
    local setting = Settings.RegisterAddOnSetting(category, field, field, tbl, "boolean", label, tbl[field])
    Settings.CreateCheckbox(category, setting, tooltip)
    setting:SetValueChangedCallback(function()
      tbl[field] = setting:GetValue()
      if onChanged then onChanged(setting:GetValue()) end
    end)
  end

  local function AddSlider(tbl, field, label, tooltip, minV, maxV, step, onChanged)
    local setting = Settings.RegisterAddOnSetting(category, field, field, tbl, "number", label, tbl[field])
    local opts = Settings.CreateSliderOptions(minV, maxV, step)
    Settings.CreateSlider(category, setting, opts, tooltip)
    setting:SetValueChangedCallback(function()
      tbl[field] = setting:GetValue()
      if onChanged then onChanged(setting:GetValue()) end
    end)
  end

  local function AddDropdown(tbl, field, label, tooltip, options, onChanged)
    local setting = Settings.RegisterAddOnSetting(category, field, field, tbl, "string", label, tbl[field])
    local opts = Settings.CreateDropdownOptions()
    for _, o in ipairs(options) do opts:AddOption(o.value, o.text) end
    Settings.CreateDropdown(category, setting, opts, tooltip)
    setting:SetValueChangedCallback(function()
      tbl[field] = setting:GetValue()
      if onChanged then onChanged(setting:GetValue()) end
    end)
  end

  -- Preset
  do
    local presetSetting = Settings.RegisterAddOnSetting(category, "preset", "preset", NS.DB, "string", "Healing preset", NS.DB.preset)
    local presetOpts = Settings.CreateDropdownOptions()
    for _, o in ipairs(NS.GetPresetOptions()) do presetOpts:AddOption(o.value, o.text) end
    Settings.CreateDropdown(category, presetSetting, presetOpts, "Loads a class/spec preset (bindings + HoT tracking). Custom presets are in Tools.")
    presetSetting:SetValueChangedCallback(function()
      NS.DB.preset = presetSetting:GetValue()
      if NS.ApplyPreset then NS.ApplyPreset(NS.DB.preset, false) end
    end)
  end

  -- Lock + snap + numeric position
  AddCheckbox(NS.DB.frame, "locked", "Lock frames", "Locks the frame position. Unlock shows a drag bar above frames.", function()
    if NS.UpdateMoveHandle then NS.UpdateMoveHandle() end
  end)

  AddCheckbox(NS.DB.frame, "snapToGrid", "Snap to grid", "Snaps moved frames to a grid when dragging.", nil)
  AddSlider(NS.DB.frame, "gridSize", "Grid size", "Snap size (pixels).", 2, 50, 1, nil)

  AddSlider(NS.DB.frame, "x", "Position X", "Numerically move the frames left/right.", -2000, 2000, 1, function()
    if NS.ApplyDriverPosition then NS.ApplyDriverPosition() end
    if NS.RefreshTestLayout then NS.RefreshTestLayout() end
  end)
  AddSlider(NS.DB.frame, "y", "Position Y", "Numerically move the frames up/down.", -2000, 2000, 1, function()
    if NS.ApplyDriverPosition then NS.ApplyDriverPosition() end
    if NS.RefreshTestLayout then NS.RefreshTestLayout() end
  end)

  AddDropdown(NS.DB.frame, "layoutMode", "Layout mode",
    "Choose 8 groups across or 2 big columns (applies out of combat).",
    {
      { value="GROUPS_8", text="8 groups across" },
      { value="COLUMNS_2", text="2 big columns" },
    },
    function()
      if NS.RequestSecureApply and NS.RequestSecureApply() then
        if NS.RebuildFrames then NS.RebuildFrames() end
      end
      if NS.RefreshTestLayout then NS.RefreshTestLayout() end
    end
  )

  AddCheckbox(NS.DB.frame, "locked_dummy", "", "", nil) -- harmless spacer (Settings UI likes fields unique)

  AddSlider(NS.DB.frame, "scale", "Scale", "Overall size.", 0.6, 1.8, 0.05, function()
    if NS.ApplyDriverPosition then NS.ApplyDriverPosition() end
    if NS.RefreshTestLayout then NS.RefreshTestLayout() end
  end)

  AddSlider(NS.DB.frame, "unitWidth", "Unit width", "Big triage bars.", 120, 340, 1, function()
    if NS.RequestSecureApply and NS.RequestSecureApply() then if NS.RebuildFrames then NS.RebuildFrames() end end
    if NS.RefreshTestLayout then NS.RefreshTestLayout() end
  end)
  AddSlider(NS.DB.frame, "unitHeight", "Unit height", "Bigger = clearer triage.", 24, 80, 1, function()
    if NS.RequestSecureApply and NS.RequestSecureApply() then if NS.RebuildFrames then NS.RebuildFrames() end end
    if NS.RefreshTestLayout then NS.RefreshTestLayout() end
  end)

  -- Spacing
  AddSlider(NS.DB.frame, "groupColumnSpacing", "Group column spacing", "Spacing between raid groups (GROUPS_8).", 0, 30, 1, function()
    if NS.RequestSecureApply and NS.RequestSecureApply() then if NS.RebuildFrames then NS.RebuildFrames() end end
    if NS.RefreshTestLayout then NS.RefreshTestLayout() end
  end)
  AddSlider(NS.DB.frame, "groupRowSpacing", "Group row spacing", "Vertical spacing (GROUPS_8).", 0, 30, 1, function()
    if NS.RequestSecureApply and NS.RequestSecureApply() then if NS.RebuildFrames then NS.RebuildFrames() end end
    if NS.RefreshTestLayout then NS.RefreshTestLayout() end
  end)
  AddSlider(NS.DB.frame, "columnsColumnSpacing", "Column spacing", "Spacing between columns (COLUMNS_2).", 0, 40, 1, function()
    if NS.RequestSecureApply and NS.RequestSecureApply() then if NS.RebuildFrames then NS.RebuildFrames() end end
    if NS.RefreshTestLayout then NS.RefreshTestLayout() end
  end)
  AddSlider(NS.DB.frame, "columnsRowSpacing", "Row spacing", "Vertical spacing (COLUMNS_2).", 0, 30, 1, function()
    if NS.RequestSecureApply and NS.RequestSecureApply() then if NS.RebuildFrames then NS.RebuildFrames() end end
    if NS.RefreshTestLayout then NS.RefreshTestLayout() end
  end)

  -- Feature toggles
  local feats = NS.DB.features
  AddCheckbox(feats, "showHots", "Show HoT squares", "Shows your tracked HoTs.", nil)
  AddCheckbox(feats, "showDebuff", "Show debuff box", "Shows a priority debuff icon.", nil)
  AddCheckbox(feats, "showRoleIcon", "Show role icon", "Shows tank/healer/dps.", nil)
  AddCheckbox(feats, "showAggro", "Show aggro highlight", "Highlights high threat.", nil)
  AddCheckbox(feats, "showStateText", "Show OFFLINE/DEAD text", "Shows status text.", nil)
  AddCheckbox(feats, "showHpText", "Show health text", "Shows health text on frames (see mode below).", nil)

AddDropdown(feats, "hpTextMode", "Health text mode",
  "Choose percentage, numeric value, or both.",
  {
    { value="PERCENT", text="Percent" },
    { value="VALUE", text="Numeric" },
    { value="BOTH", text="Both" },
    { value="NONE", text="Off" },
  },
  function()
    -- immediate visual update
    if NS.RebuildFrames and not InCombatLockdown() then NS.RebuildFrames() end
    if NS.RefreshTestLayout then NS.RefreshTestLayout() end
  end
)

AddDropdown(feats, "colorMode", "Color mode",
  "Choose class colors, custom colors, or disable coloring.",
  {
    { value="CLASS", text="Class colors" },
    { value="CUSTOM", text="Custom colors" },
    { value="NONE", text="Off" },
  },
  function()
    if NS.RebuildFrames and not InCombatLockdown() then NS.RebuildFrames() end
    if NS.RefreshTestLayout then NS.RefreshTestLayout() end
  end
)

-- Choose what is colored in 'MidnightHealer - Colors'
AddCheckbox(feats, "dummy_color_note", "Color targets & picker",
  "Open Settings: MidnightHealer - Colors to select targets (bar/name/border) and pick custom colors.",
  nil
)

AddCheckbox(feats, "classColorBars", "Legacy class-color toggle",
  "Deprecated: use 'Color mode' above. (Kept for backward compatibility.)",
  nil
)

AddCheckbox(feats, "classColorBars", "Class-colored health bars", "Color unit bars by class (raid/party).", function()
  if NS.RebuildFrames and not InCombatLockdown() then NS.RebuildFrames() end
  if NS.RefreshTestLayout then NS.RefreshTestLayout() end
end)
  AddCheckbox(feats, "showCluster", "Show cluster help", "Shows cluster glow/count.", nil)

  -- Combat indicator + incoming heal prediction
  AddCheckbox(feats.combatIndicator, "enabled", "Combat indicator", "Red overlay when unit is in combat.", function()
    if NS.RebuildFrames and not InCombatLockdown() then NS.RebuildFrames() end
    if NS.RefreshTestLayout then NS.RefreshTestLayout() end
  end)

  AddCheckbox(feats.incomingHeals, "enabled", "Incoming heal prediction", "Shows predicted incoming heals on the health bar.", function()
    if NS.RebuildFrames and not InCombatLockdown() then NS.RebuildFrames() end
  end)
  AddSlider(feats.incomingHeals, "warnPct", "Incoming heal warn threshold", "If incoming heals exceed this fraction of max HP, show warning color.", 0.05, 1.0, 0.05, function()
    if NS.RebuildFrames and not InCombatLockdown() then NS.RebuildFrames() end
  end)
  AddCheckbox(feats.incomingHeals, "tankBoost", "Tank emphasis", "Make incoming-heal bar more visible for tanks.", function()
    if NS.RebuildFrames and not InCombatLockdown() then NS.RebuildFrames() end
  end)

  AddCheckbox(feats, "showGroupLabels", "Show group labels", "Shows Group 1-8 labels above frames.", function()
    if NS.RequestSecureApply and NS.RequestSecureApply() then if NS.RebuildFrames then NS.RebuildFrames() end end
    if NS.RefreshTestLayout then NS.RefreshTestLayout() end
  end)

  -- Spec profiles
  local sp = NS.DB.specProfiles
  AddCheckbox(sp, "enabled", "Auto-switch by spec", "Automatically load your setup when you change specialization.", nil)
  AddCheckbox(sp, "remember", "Remember per spec", "Save your current setup to your current spec before switching.", nil)

  Settings.RegisterAddOnCategory(category)
end

local function RegisterBindingsCategory()
  local canvas = CreateBindingsCanvas()
  local category = Settings.RegisterCanvasLayoutCategory(canvas, "MidnightHealer - Bindings")
  Settings.RegisterAddOnCategory(category)
end

local function RegisterBindPickerCategory()
  local canvas = CreateBindPickerCanvas()
  local category = Settings.RegisterCanvasLayoutCategory(canvas, "MidnightHealer - Bind Picker")
  Settings.RegisterAddOnCategory(category)
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, _, name)
  if name ~= ADDON then return end
  if not NS.DB then return end
  RegisterMainCategory()
  RegisterBindingsCategory()
  RegisterBindPickerCategory()
end)
