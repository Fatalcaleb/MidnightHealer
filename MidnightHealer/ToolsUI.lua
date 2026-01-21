-- Author: Fatalcaleb
-- ToolsUI.lua
local ADDON, NS = ...

local function CreateToolsCanvas()
  local canvas = CreateFrame("Frame")
  canvas:SetSize(1, 1)

  -- Scroll container (fixes clipping/squish)
  local scroll = CreateFrame("ScrollFrame", nil, canvas, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 0, 0)
  scroll:SetPoint("BOTTOMRIGHT", -28, 0) -- room for scrollbar

  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(1, 1200) -- enough height for all controls
  scroll:SetScrollChild(content)

  local function Btn(text, x, y, w, onClick)
    local b = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    b:SetSize(w or 210, 24)
    b:SetPoint("TOPLEFT", x, y)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
  end

  local function Label(text, x, y)
    local fs = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetText(text)
    return fs
  end

  local function Small(text, x, y, width)
    local fs = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetText(text)
    if width then
      fs:SetWidth(width)
      fs:SetJustifyH("LEFT")
    end
    return fs
  end

  local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("Tools")

  Small("Profiles, one-click saves, lock controls, test mode, and sharing.", 16, -42, 720)

  -- -------------------
  -- Profiles
  -- -------------------
  local y = -75
  Label("Profiles", 16, y)

  local profDD = CreateFrame("Frame", nil, content, "UIDropDownMenuTemplate")
  profDD:SetPoint("TOPLEFT", 16, y-22)
  UIDropDownMenu_SetWidth(profDD, 220)

  local nameBox = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
  nameBox:SetSize(200, 22)
  nameBox:SetPoint("TOPLEFT", 260, y-22)
  nameBox:SetAutoFocus(false)
  nameBox:SetText("")

  local status = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  status:SetPoint("TOPLEFT", 16, y-52)
  status:SetText("")

  local function UpdateStatus(msg)
    local active = (NS.GetActiveProfileName and NS.GetActiveProfileName()) or "Default"
    status:SetText(msg or ("Active: " .. active))
  end

  local function RefreshProfileDropdown()
    local current = (NS.GetActiveProfileName and NS.GetActiveProfileName()) or "Default"
    UIDropDownMenu_Initialize(profDD, function(self, level)
      local names = NS.ListProfiles and NS.ListProfiles() or { "Default" }
      for _, n in ipairs(names) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = n
        info.value = n
        info.func = function()
          UIDropDownMenu_SetSelectedValue(profDD, n)
          if NS.SetProfile then NS.SetProfile(n, false) end
          UpdateStatus()
        end
        UIDropDownMenu_AddButton(info, level)
      end
    end)
    UIDropDownMenu_SetSelectedValue(profDD, current)
    UpdateStatus()
  end

  RefreshProfileDropdown()

  Btn("Create", 470, y-22, 90, function()
    local n = nameBox:GetText():gsub("^%s+",""):gsub("%s+$","")
    if n == "" then UpdateStatus("Type a profile name first.") return end
    if NS.CreateProfile and NS.CreateProfile(n, nil, false) then
      NS.SetProfile(n, true)
      RefreshProfileDropdown()
      UpdateStatus("Created & switched to: " .. n)
    else
      UpdateStatus("Couldn't create profile (name taken?).")
    end
  end)

  Btn("Copy From Current", 16, y-80, 210, function()
    local n = nameBox:GetText():gsub("^%s+",""):gsub("%s+$","")
    if n == "" then UpdateStatus("Type a profile name first.") return end
    local cur = (NS.GetActiveProfileName and NS.GetActiveProfileName()) or "Default"
    if NS.CreateProfile and NS.CreateProfile(n, cur, false) then
      NS.SetProfile(n, true)
      RefreshProfileDropdown()
      UpdateStatus("Copied from " .. cur .. " -> " .. n)
    else
      UpdateStatus("Couldn't copy (name taken?).")
    end
  end)

  Btn("Delete Selected", 250, y-80, 210, function()
    local cur = UIDropDownMenu_GetSelectedValue(profDD) or ((NS.GetActiveProfileName and NS.GetActiveProfileName()) or "Default")
    if cur == "Default" then UpdateStatus("Default can't be deleted.") return end
    if NS.DeleteProfile and NS.DeleteProfile(cur, false) then
      RefreshProfileDropdown()
      UpdateStatus("Deleted: " .. cur)
    else
      UpdateStatus("Couldn't delete profile.")
    end
  end)

  Btn("Refresh List", 470, y-80, 90, function()
    RefreshProfileDropdown()
    UpdateStatus()
  end)

  y = y - 135

  -- -------------------
  -- Layout Presets
  -- -------------------
  Label("Layout Presets", 16, y)
  Btn("Apply: Classic", 16, y-28, 210, function() if NS.ApplyLayoutPreset then NS.ApplyLayoutPreset("CLASSIC") end end)
  Btn("Apply: VuhDo", 250, y-28, 210, function() if NS.ApplyLayoutPreset then NS.ApplyLayoutPreset("VUHDO") end end)
  Btn("Apply: Minimal", 470, y-28, 210, function() if NS.ApplyLayoutPreset then NS.ApplyLayoutPreset("MINIMAL") end end)
  y = y - 80

  -- -------------------
  -- Preset quick actions
  -- -------------------
  Label("Presets", 16, y)
  Btn("Save Global Custom", 16, y-28, 210, function() if NS.SaveCurrentAsCustom then NS.SaveCurrentAsCustom(false) end end)
  Btn("Load Global Custom", 16, y-58, 210, function() if NS.ApplyPreset then NS.ApplyPreset("CUSTOM", false) end end)

  Btn("Save Custom (This Spec)", 250, y-28, 210, function() if NS.SaveCurrentAsCustomForSpec then NS.SaveCurrentAsCustomForSpec(false) end end)
  Btn("Load Custom (This Spec)", 250, y-58, 210, function() if NS.ApplyPreset then NS.ApplyPreset("CUSTOM_SPEC", false) end end)

  Btn("Save Spec Profile Now", 16, y-95, 210, function() if NS.SaveSpecProfileNow then NS.SaveSpecProfileNow() end end)
  Btn("Clear Spec Profile Now", 250, y-95, 210, function() if NS.ClearSpecProfileNow then NS.ClearSpecProfileNow() end end)

  y = y - 145

  -- -------------------
  -- Frame position
  -- -------------------
  Label("Frame Position", 16, y)
  Btn("Unlock Frames", 16, y-28, 210, function() NS.DB.frame.locked = false; if NS.UpdateMoveHandle then NS.UpdateMoveHandle() end end)
  Btn("Lock Frames", 250, y-28, 210, function() NS.DB.frame.locked = true; if NS.UpdateMoveHandle then NS.UpdateMoveHandle() end end)
  y = y - 75

  -- -------------------
  -- Test mode
  -- -------------------
  Label("Test Mode", 16, y)
  Small("Tip: the 'Test' buttons below also turn test mode ON automatically.", 16, y-18, 720)

  Btn("Toggle Test Mode", 16, y-45, 210, function() if NS.ToggleTestMode then NS.ToggleTestMode(nil) end end)

  local function EnsureTestOn()
    if NS.DB and NS.DB.testMode and NS.DB.testMode.enabled then return end
    if NS.SetTestMode then NS.SetTestMode(true) elseif NS.ToggleTestMode then NS.ToggleTestMode(true) end
  end

  Btn("Test: 20 Raid", 250, y-45, 210, function()
    NS.DB.testMode.mode="RAID"; NS.DB.testMode.count=20
    EnsureTestOn()
    if NS.RefreshTestLayout then NS.RefreshTestLayout() end
  end)

  Btn("Test: 40 Raid", 250, y-75, 210, function()
    NS.DB.testMode.mode="RAID"; NS.DB.testMode.count=40
    EnsureTestOn()
    if NS.RefreshTestLayout then NS.RefreshTestLayout() end
  end)

  Btn("Test: Party (5)", 470, y-45, 210, function()
    NS.DB.testMode.mode="PARTY"; NS.DB.testMode.count=5
    EnsureTestOn()
    if NS.RefreshTestLayout then NS.RefreshTestLayout() end
  end)

  y = y - 130

  -- -------------------
  -- Profile sharing (Import/Export)
  -- -------------------
  Label("Profile Sharing (Import / Export)", 16, y)

  local shareScroll = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
  shareScroll:SetPoint("TOPLEFT", 16, y-26)
  shareScroll:SetSize(690, 130)

  local shareBox = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
  shareBox:SetAutoFocus(false)
  shareBox:SetMultiLine(true)
  shareBox:SetSize(670, 130)
  shareBox:SetText("")
  shareScroll:SetScrollChild(shareBox)

  Btn("Export Current Profile", 16, y-165, 210, function()
    if NS.ExportActiveProfile then
      shareBox:SetText(NS.ExportActiveProfile() or "")
      shareBox:HighlightText()
    end
  end)

  Btn("Import Into Current Profile", 250, y-165, 230, function()
    local s = shareBox:GetText()
    if NS.ImportProfile and NS.ImportProfile(s) then
      UpdateStatus("Imported into current profile.")
      RefreshProfileDropdown()
    else
      UpdateStatus("Import failed (bad string?).")
    end
  end)

  Btn("Clear Box", 500, y-165, 110, function()
    shareBox:SetText("")
  end)

  y = y - 215

  local note = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  note:SetPoint("TOPLEFT", 16, y)
  note:SetWidth(720)
  note:SetJustifyH("LEFT")
  note:SetText("Profiles are per-character assignment, shared across your account. Create once, then select it on each toon to reuse the exact same settings.")

  content:SetHeight(1200)
  return canvas
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, _, name)
  if name ~= ADDON then return end
  if not Settings then return end
  local canvas = CreateToolsCanvas()
  local category = Settings.RegisterCanvasLayoutCategory(canvas, "MidnightHealer - Tools")
  Settings.RegisterAddOnCategory(category)
end)
