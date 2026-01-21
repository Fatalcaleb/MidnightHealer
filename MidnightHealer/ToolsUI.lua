-- Author: Fatalcaleb
-- ToolsUI.lua
local ADDON, NS = ...

local function CreateToolsCanvas()
  local canvas = CreateFrame("Frame")
  canvas:SetSize(1, 1)

  local title = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("Tools")

  local sub = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  sub:SetText("Profiles, one-click saves, lock controls, and test mode.")

  local function Btn(text, x, y, w, onClick)
    local b = CreateFrame("Button", nil, canvas, "UIPanelButtonTemplate")
    b:SetSize(w or 210, 24)
    b:SetPoint("TOPLEFT", x, y)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
  end

  local function Label(text, x, y)
    local fs = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetText(text)
    return fs
  end

  -- Profiles
  Label("Profiles", 16, -60)

  local profDD = CreateFrame("Frame", nil, canvas, "UIDropDownMenuTemplate")
  profDD:SetPoint("TOPLEFT", 16, -80)
  UIDropDownMenu_SetWidth(profDD, 220)

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
        end
        UIDropDownMenu_AddButton(info, level)
      end
    end)
    UIDropDownMenu_SetSelectedValue(profDD, current)
  end

  RefreshProfileDropdown()

  local nameBox = CreateFrame("EditBox", nil, canvas, "InputBoxTemplate")
  nameBox:SetSize(200, 22)
  nameBox:SetPoint("TOPLEFT", 260, -80)
  nameBox:SetAutoFocus(false)
  nameBox:SetText("")

  local status = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  status:SetPoint("TOPLEFT", 16, -112)
  status:SetText("Active: " .. ((NS.GetActiveProfileName and NS.GetActiveProfileName()) or "Default"))

  local function UpdateStatus(msg)
    status:SetText(msg or ("Active: " .. ((NS.GetActiveProfileName and NS.GetActiveProfileName()) or "Default")))
  end

  Btn("Create", 470, -80, 90, function()
    local n = nameBox:GetText():gsub("^%s+",""):gsub("%s+$","")
    if n == "" then UpdateStatus("Type a profile name first.") return end
    if NS.CreateProfile and NS.CreateProfile(n, nil, false) then
      RefreshProfileDropdown()
      NS.SetProfile(n, true)
      RefreshProfileDropdown()
      UpdateStatus("Created & switched to: " .. n)
    else
      UpdateStatus("Couldn't create profile (name taken?).")
    end
  end)

  Btn("Copy From Current", 16, -140, 210, function()
    local n = nameBox:GetText():gsub("^%s+",""):gsub("%s+$","")
    if n == "" then UpdateStatus("Type a profile name first.") return end
    local cur = NS.GetActiveProfileName and NS.GetActiveProfileName() or "Default"
    if NS.CreateProfile and NS.CreateProfile(n, cur, false) then
      RefreshProfileDropdown()
      NS.SetProfile(n, true)
      RefreshProfileDropdown()
      UpdateStatus("Copied from " .. cur .. " -> " .. n)
    else
      UpdateStatus("Couldn't copy (name taken?).")
    end
  end)

  Btn("Delete Selected", 250, -140, 210, function()
    local cur = UIDropDownMenu_GetSelectedValue(profDD) or (NS.GetActiveProfileName and NS.GetActiveProfileName()) or "Default"
    if cur == "Default" then UpdateStatus("Default can't be deleted.") return end
    if NS.DeleteProfile and NS.DeleteProfile(cur, false) then
      RefreshProfileDropdown()
      UpdateStatus("Deleted: " .. cur .. " (switched to Default where needed)")
    else
      UpdateStatus("Couldn't delete profile.")
    end
  end)

  Btn("Refresh List", 470, -140, 90, function()
    RefreshProfileDropdown()
    UpdateStatus()
  end)

  -- Preset quick actions
  Label("Layout Presets", 16, -190)
  Btn("Apply: Classic", 16, -215, 210, function() if NS.ApplyLayoutPreset then NS.ApplyLayoutPreset("CLASSIC") end end)
  Btn("Apply: VuhDo", 250, -215, 210, function() if NS.ApplyLayoutPreset then NS.ApplyLayoutPreset("VUHDO") end end)
  Btn("Apply: Minimal", 470, -215, 210, function() if NS.ApplyLayoutPreset then NS.ApplyLayoutPreset("MINIMAL") end end)

Label("Presets", 16, -255)
  local y0 = -275
  Btn("Save Global Custom", 16, y0, 210, function() if NS.SaveCurrentAsCustom then NS.SaveCurrentAsCustom(false) end end)
  Btn("Load Global Custom", 16, y0-30, 210, function() if NS.ApplyPreset then NS.ApplyPreset("CUSTOM", false) end end)

  Btn("Save Custom (This Spec)", 250, y0, 210, function() if NS.SaveCurrentAsCustomForSpec then NS.SaveCurrentAsCustomForSpec(false) end end)
  Btn("Load Custom (This Spec)", 250, y0-30, 210, function() if NS.ApplyPreset then NS.ApplyPreset("CUSTOM_SPEC", false) end end)

  Btn("Save Spec Profile Now", 16, y0-75, 210, function() if NS.SaveSpecProfileNow then NS.SaveSpecProfileNow() end end)
  Btn("Clear Spec Profile Now", 250, y0-75, 210, function() if NS.ClearSpecProfileNow then NS.ClearSpecProfileNow() end end)

  -- Lock controls
  Label("Frame Position", 16, y0-120)
  Btn("Unlock Frames", 16, y0-145, 210, function() NS.DB.frame.locked = false; if NS.UpdateMoveHandle then NS.UpdateMoveHandle() end end)
  Btn("Lock Frames", 250, y0-145, 210, function() NS.DB.frame.locked = true; if NS.UpdateMoveHandle then NS.UpdateMoveHandle() end end)

  -- Test mode
  Label("Test Mode", 16, y0-190)
  Btn("Toggle Test Mode", 16, y0-215, 210, function() if NS.ToggleTestMode then NS.ToggleTestMode(nil) end end)
  Btn("Test: 20 Raid", 250, y0-215, 210, function() NS.DB.testMode.mode="RAID"; NS.DB.testMode.count=20; if NS.RefreshTestLayout then NS.RefreshTestLayout() end end)
  Btn("Test: 40 Raid", 250, y0-245, 210, function() NS.DB.testMode.mode="RAID"; NS.DB.testMode.count=40; if NS.RefreshTestLayout then NS.RefreshTestLayout() end end)
  Btn("Test: Party (5)", 250, y0-275, 210, function() NS.DB.testMode.mode="PARTY"; NS.DB.testMode.count=5; if NS.RefreshTestLayout then NS.RefreshTestLayout() end end)

  
  -- Profile sharing (Import/Export)
  Label("Profile Sharing (Import / Export)", 16, y0-345)

  local shareBox = CreateFrame("EditBox", nil, canvas, "InputBoxTemplate")
  shareBox:SetAutoFocus(false)
  shareBox:SetMultiLine(true)
  shareBox:SetSize(670, 120)
  shareBox:SetPoint("TOPLEFT", 16, y0-370)
  shareBox:SetText("")

  local scroll = CreateFrame("ScrollFrame", nil, canvas, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 16, y0-370)
  scroll:SetSize(690, 120)
  scroll:SetScrollChild(shareBox)

  Btn("Export Current Profile", 16, y0-500, 210, function()
    if NS.ExportActiveProfile then
      shareBox:SetText(NS.ExportActiveProfile() or "")
      shareBox:HighlightText()
    end
  end)

  Btn("Import Into Current Profile", 250, y0-500, 230, function()
    local s = shareBox:GetText()
    if NS.ImportProfile and NS.ImportProfile(s) then
      UpdateStatus("Imported into current profile.")
      RefreshProfileDropdown()
    else
      UpdateStatus("Import failed (bad string?).")
    end
  end)

  Btn("Clear Box", 500, y0-500, 110, function()
    shareBox:SetText("")
  end)

  local note = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  note:SetPoint("TOPLEFT", 16, y0-315)
  note:SetWidth(680)
  note:SetJustifyH("LEFT")
  note:SetText("Profiles are per-character assignment, shared across your account. Create once, then select it on each toon to reuse the exact same settings.")

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
