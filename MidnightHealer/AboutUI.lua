-- Author: Fatalcaleb
-- AboutUI.lua
local ADDON, NS = ...

local function CreateAboutCanvas()
  local canvas = CreateFrame("Frame")
  canvas:SetSize(1, 1)

  local title = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("MidnightHealer")

  local version = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  version:SetText("Version: 0.12.6")

  local author = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  author:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -4)
  author:SetText("Author: Fatalcaleb")

  local desc = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  desc:SetPoint("TOPLEFT", author, "BOTTOMLEFT", 0, -12)
  desc:SetWidth(700)
  desc:SetJustifyH("LEFT")
  desc:SetText(
    "MidnightHealer is a modern, triage-focused raid and party healing addon built for the Midnight expansion.\n\n" ..
    "Design goals:\n" ..
    "• Fast visual triage\n" ..
    "• Minimal but powerful customization\n" ..
    "• Secure click-casting without bloat\n" ..
    "• Profile-based configuration across characters\n\n" ..
    "Inspired by classic tools like VuhDo and Grid, but rebuilt clean for modern WoW."
  )

  local linksTitle = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  linksTitle:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16)
  linksTitle:SetText("Links")

  local links = {
    { label = "GitHub (source & issues)", url = "https://github.com/Fatalcaleb/MidnightHealer" },
    { label = "Wago.io (downloads)", url = "https://wago.io/MidnightHealer" },
    { label = "CurseForge", url = "https://www.curseforge.com/wow/addons/midnighthealer" },
  }

  local y = -1
  for i, l in ipairs(links) do
    local btn = CreateFrame("Button", nil, canvas, "UIPanelButtonTemplate")
    btn:SetSize(260, 22)
    btn:SetPoint("TOPLEFT", linksTitle, "BOTTOMLEFT", 0, y - (i-1)*28)
    btn:SetText(l.label)
    btn:SetScript("OnClick", function()
      if l.url then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffMidnightHealer:|r " .. l.url)
      end
    end)
  end

  local foot = canvas:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  foot:SetPoint("BOTTOMLEFT", 16, 16)
  foot:SetText("© Fatalcaleb — All rights reserved.")

  return canvas
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, _, name)
  if name ~= ADDON then return end
  if not Settings then return end
  local canvas = CreateAboutCanvas()
  local category = Settings.RegisterCanvasLayoutCategory(canvas, "MidnightHealer - About")
  Settings.RegisterAddOnCategory(category)
end)
