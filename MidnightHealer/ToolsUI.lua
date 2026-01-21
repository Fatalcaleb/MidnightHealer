-- Author: Fatalcaleb
-- ToolsUI.lua
local ADDON, NS = ...

local function CreateToolsCanvas()
  local canvas = CreateFrame("Frame")
  canvas:SetSize(1, 1)

  -- Scroll container
  local scroll = CreateFrame("ScrollFrame", nil, canvas, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 0, 0)
  scroll:SetPoint("BOTTOMRIGHT", -28, 0)

  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(1, 1400)
  scroll:SetScrollChild(content)

  local function Btn(parent, text, x, y, w, h, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w or 210, h or 24)
    b:SetPoint("TOPLEFT", x, y)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
  end

  local function Label(parent, text, x, y, font)
    local fs = parent:CreateFontString(nil, "ARTWORK", font or "GameFontNormal")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetText(text)
    return fs
  end

  local function Small(parent, text, x, y, width)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetText(text)
    if width then
      fs:SetWidth(width)
      fs:SetJustifyH("LEFT")
    end
    return fs
  end

  -- Header
  local title = Label(content, "Tools", 16, -16, "GameFontNormalLarge")
  Small(content, "Collapsible sections. Less cockpit, more control.", 16, -42, 720)

  local sections = {}
  local function MakeSection(name, defaultOpen)
    local s = CreateFrame("Frame", nil, content)
    s.name = name
    s.open = defaultOpen and true or false

    s.header = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    s.header:SetSize(690, 24)
    s.header:SetText("")
    s.header:SetScript("OnClick", function()
      s.open = not s.open
      s.body:SetShown(s.open)
      if s.ind then s.ind:SetText(s.open and "▼" or "►") end
      if s._onToggle then s._onToggle(s.open) end
      if s.relayout then s.relayout() end
    end)

    s.ind = s.header:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    s.ind:SetPoint("LEFT", 8, 0)
    s.ind:SetText(s.open and "▼" or "►")

    s.title = s.header:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    s.title:SetPoint("LEFT", 26, 0)
    s.title:SetText(name)

    s.body = CreateFrame("Frame", nil, content)
    s.body:SetSize(690, 1)
    s.body:SetShown(s.open)
    s.body:SetClipsChildren(false)

    sections[#sections+1] = s
    return s
  end

  local function LayoutSections()
    local y = -75
    for _, s in ipairs(sections) do
      s.header:ClearAllPoints()
      s.header:SetPoint("TOPLEFT", 16, y)
      y = y - 30

      if s.open then
        s.body:ClearAllPoints()
        s.body:SetPoint("TOPLEFT", 16, y)
        local h = s.body._height or 0
        s.body:SetSize(690, h)
        s.body:Show()
        y = y - h - 16
      end
    end
    content:SetHeight(-y + 40)
  end

  -- Expose relayout to each section
  local function HookRelayout(s)
    s.relayout = LayoutSections
  end

  -- -------------------
  -- Profiles
  -- -------------------
  local SProfiles = MakeSection("Profiles", true); HookRelayout(SProfiles)
  do
    local p = SProfiles.body
    local y = 0

    local profDD = CreateFrame("Frame", nil, p, "UIDropDownMenuTemplate")
    profDD:SetPoint("TOPLEFT", 0, -6)
    UIDropDownMenu_SetWidth(profDD, 220)

    local nameBox = CreateFrame("EditBox", nil, p, "InputBoxTemplate")
    nameBox:SetSize(200, 22)
    nameBox:SetPoint("TOPLEFT", 244, -6)
    nameBox:SetAutoFocus(false)
    nameBox:SetText("")

    local status = Small(p, "", 0, -40, 680)

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

    Btn(p, "Create", 460, -6, 90, 22, function()
      local n = nameBox:GetText():gsub("^%s+",""):gsub("%s+$","")
      if n == "" then UpdateStatus("Type a profile name first.") return end
      if NS.CreateProfile and NS.CreateProfile(n, nil, false) then
        if NS.SetProfile then NS.SetProfile(n, true) end
        RefreshProfileDropdown()
        UpdateStatus("Created & switched to: " .. n)
      else
        UpdateStatus("Couldn't create profile (name taken?).")
      end
    end)

    Btn(p, "Copy From Current", 0, -68, 210, 24, function()
      local n = nameBox:GetText():gsub("^%s+",""):gsub("%s+$","")
      if n == "" then UpdateStatus("Type a profile name first.") return end
      local cur = (NS.GetActiveProfileName and NS.GetActiveProfileName()) or "Default"
      if NS.CreateProfile and NS.CreateProfile(n, cur, false) then
        if NS.SetProfile then NS.SetProfile(n, true) end
        RefreshProfileDropdown()
        UpdateStatus("Copied from " .. cur .. " -> " .. n)
      else
        UpdateStatus("Couldn't copy (name taken?).")
      end
    end)

    Btn(p, "Delete Selected", 230, -68, 210, 24, function()
      local cur = UIDropDownMenu_GetSelectedValue(profDD) or ((NS.GetActiveProfileName and NS.GetActiveProfileName()) or "Default")
      if cur == "Default" then UpdateStatus("Default can't be deleted.") return end
      if NS.DeleteProfile and NS.DeleteProfile(cur, false) then
        RefreshProfileDropdown()
        UpdateStatus("Deleted: " .. cur)
      else
        UpdateStatus("Couldn't delete profile.")
      end
    end)

    Btn(p, "Refresh List", 460, -68, 90, 24, function()
      RefreshProfileDropdown()
      UpdateStatus()
    end)

    Small(p, "Profiles are shared across your account. Select a profile on each toon to reuse the same settings.", 0, -104, 680)

    p._height = 130
  end

  -- -------------------
  -- Presets / Layout
  -- -------------------
  local SPresets = MakeSection("Presets & Layout", true); HookRelayout(SPresets)
  do
    local p = SPresets.body

    Label(p, "Layout Presets", 0, -2)
    Btn(p, "Apply: Classic", 0, -28, 210, 24, function() if NS.ApplyLayoutPreset then NS.ApplyLayoutPreset("CLASSIC") end end)
    Btn(p, "Apply: VuhDo", 230, -28, 210, 24, function() if NS.ApplyLayoutPreset then NS.ApplyLayoutPreset("VUHDO") end end)
    Btn(p, "Apply: Minimal", 460, -28, 210, 24, function() if NS.ApplyLayoutPreset then NS.ApplyLayoutPreset("MINIMAL") end end)

    Label(p, "Preset Quick Actions", 0, -70)
    Btn(p, "Save Global Custom", 0, -96, 210, 24, function() if NS.SaveCurrentAsCustom then NS.SaveCurrentAsCustom(false) end end)
    Btn(p, "Load Global Custom", 0, -126, 210, 24, function() if NS.ApplyPreset then NS.ApplyPreset("CUSTOM", false) end end)

    Btn(p, "Save Custom (This Spec)", 230, -96, 210, 24, function() if NS.SaveCurrentAsCustomForSpec then NS.SaveCurrentAsCustomForSpec(false) end end)
    Btn(p, "Load Custom (This Spec)", 230, -126, 210, 24, function() if NS.ApplyPreset then NS.ApplyPreset("CUSTOM_SPEC", false) end end)

    Btn(p, "Save Spec Profile Now", 0, -162, 210, 24, function() if NS.SaveSpecProfileNow then NS.SaveSpecProfileNow() end end)
    Btn(p, "Clear Spec Profile Now", 230, -162, 210, 24, function() if NS.ClearSpecProfileNow then NS.ClearSpecProfileNow() end end)

    Label(p, "Frame Position", 0, -206)
    Btn(p, "Unlock Frames", 0, -232, 210, 24, function() NS.DB.frame.locked = false; if NS.UpdateMoveHandle then NS.UpdateMoveHandle() end end)
    Btn(p, "Lock Frames", 230, -232, 210, 24, function() NS.DB.frame.locked = true; if NS.UpdateMoveHandle then NS.UpdateMoveHandle() end end)

    p._height = 270
  end

  -- -------------------
  -- Test Mode
  -- -------------------
  local STest = MakeSection("Test Mode", true); HookRelayout(STest)
  do
    local p = STest.body
    Small(p, "The Test buttons enable Test Mode automatically.", 0, -2, 680)

    Btn(p, "Toggle Test Mode", 0, -28, 210, 24, function() if NS.ToggleTestMode then NS.ToggleTestMode(nil) end end)

    local function EnsureTestOn()
      if NS.DB and NS.DB.testMode and NS.DB.testMode.enabled then return end
      if NS.SetTestMode then NS.SetTestMode(true) elseif NS.ToggleTestMode then NS.ToggleTestMode(true) end
    end

    Btn(p, "Test: 20 Raid", 230, -28, 210, 24, function()
      NS.DB.testMode.mode="RAID"; NS.DB.testMode.count=20
      EnsureTestOn()
      if NS.RefreshTestLayout then NS.RefreshTestLayout() end
    end)

    Btn(p, "Test: 40 Raid", 230, -58, 210, 24, function()
      NS.DB.testMode.mode="RAID"; NS.DB.testMode.count=40
      EnsureTestOn()
      if NS.RefreshTestLayout then NS.RefreshTestLayout() end
    end)

    Btn(p, "Test: Party (5)", 460, -28, 210, 24, function()
      NS.DB.testMode.mode="PARTY"; NS.DB.testMode.count=5
      EnsureTestOn()
      if NS.RefreshTestLayout then NS.RefreshTestLayout() end
    end)

    p._height = 90
  end

  -- -------------------
  -- Profile Sharing
  -- -------------------
  local SShare = MakeSection("Profile Sharing (Import / Export)", false); HookRelayout(SShare)
  do
    local p = SShare.body

    Small(p, "Export creates a copy/paste string. Import overwrites the current profile's settings.", 0, -2, 680)

    local shareScroll = CreateFrame("ScrollFrame", nil, p, "UIPanelScrollFrameTemplate")
    shareScroll:SetPoint("TOPLEFT", 0, -26)
    shareScroll:SetSize(670, 130)

    local shareBox = CreateFrame("EditBox", nil, p, "InputBoxTemplate")
    shareBox:SetAutoFocus(false)
    shareBox:SetMultiLine(true)
    shareBox:SetSize(650, 130)
    shareBox:SetText("")
    shareScroll:SetScrollChild(shareBox)

    Btn(p, "Export Current Profile", 0, -166, 210, 24, function()
      if NS.ExportActiveProfile then
        shareBox:SetText(NS.ExportActiveProfile() or "")
        shareBox:HighlightText()
      end
    end)

    Btn(p, "Import Into Current Profile", 230, -166, 230, 24, function()
      local s = shareBox:GetText()
      if NS.ImportProfile and NS.ImportProfile(s) then
        -- no status line here; keep simple
      else
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffMidnightHealer:|r Import failed (bad string?).")
      end
    end)

    Btn(p, "Clear Box", 480, -166, 110, 24, function() shareBox:SetText("") end)

    p._height = 210
  end

  -- Final note
  local foot = Small(content, "Tip: Collapse sections you don't use for a cleaner look.", 16, -1300, 720)
  foot:Hide() -- (kept for future)

  LayoutSections()
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
