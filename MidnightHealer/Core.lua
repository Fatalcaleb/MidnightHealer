-- Author: Fatalcaleb
-- Core.lua
local ADDON, NS = ...

local defaults = {
  preset = "DRUID_RESTO",

  frame = {
    point = "CENTER", x = 0, y = 0,
    scale = 1.15,
    layoutMode = "COLUMNS_2",
    unitWidth = 220,
    unitHeight = 44,
    locked = false,
    snapToGrid = true,
    gridSize = 10,
    groupColumnSpacing = 10,
    groupRowSpacing = 8,
    columnsColumnSpacing = 14,
    columnsRowSpacing = 10,
  },

  features = {
    showHots = true,
    showDebuff = true,
    showRoleIcon = true,
    showAggro = true,
    showStateText = true,
    showHpText = false,
    showCluster = false,
    showGroupLabels = true,

    hpTextMode = "NONE",

    -- Kept for profile compatibility. Health-derived decision logic is disabled
    -- in 0.13.0 because Midnight 12.1 may return secret combat values.
    incomingHeals = {
      enabled = false,
      warnPct = 0.25,
      tankBoost = true,
      normal = { r=0.20, g=1.00, b=0.20, a=0.35 },
      warn = { r=1.00, g=0.85, b=0.20, a=0.55 },
    },

    combatIndicator = { enabled = true, a = 0.20 },

    colorMode = "CLASS",
    colorTargets = { bar = true, name = false, border = false },
    colorSource = {
      bar = "CLASS",
      name = "NONE",
      border = "NONE",
    },
    customColors = {
      bar = { r=0.10, g=0.80, b=0.10 },
      name = { r=1.00, g=1.00, b=1.00 },
      border = { r=0.90, g=0.90, b=0.90 },
    },
    roleColors = {
      TANK = { r=0.20, g=0.55, b=1.00 },
      HEALER = { r=0.15, g=1.00, b=0.40 },
      DAMAGER = { r=1.00, g=0.25, b=0.25 },
      NONE = { r=0.85, g=0.85, b=0.85 },
    },
    classColors = {},
    debuffTypeColors = {
      Magic = { r=0.20, g=0.60, b=1.00 },
      Curse = { r=0.60, g=0.20, b=1.00 },
      Disease = { r=0.60, g=0.40, b=0.20 },
      Poison = { r=0.10, g=1.00, b=0.10 },
      None = { r=0.90, g=0.90, b=0.90 },
    },
  },

  bindings = {},
  hotSpellIds = {},
  stackTracker = { spellId = 0, squareIndex = 0 },
  custom = { bindings = {}, hotSpellIds = {}, stackTracker = { spellId = 0, squareIndex = 0 } },
  customBySpec = {},
  specProfiles = { enabled = true, remember = true, data = {} },

  -- Retained so old profiles import without losing data. The old injured-player
  -- cluster analyzer is disabled under the 12.1 secret-value model.
  cluster = { enabled = false, radius = 10, hpThreshold = 0.85, minCount = 4, showNumber = true },

  testMode = { enabled = false, count = 20, mode = "RAID" },
}

local function CopyDefaults(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" then
      if type(dst[k]) ~= "table" then dst[k] = {} end
      CopyDefaults(dst[k], v)
    elseif dst[k] == nil then
      dst[k] = v
    end
  end
end

function NS.ApplyDefaults(profile)
  if profile then CopyDefaults(profile, defaults) end
end

local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffMidnightHealer:|r " .. tostring(msg))
end
NS.Print = Print

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, _, name)
  if name ~= ADDON then return end

  if NS.GetActiveProfile then
    local profile = NS.GetActiveProfile()
    NS.DB = profile
  end

  if not NS.DB then
    MidnightHealerDB = MidnightHealerDB or {}
    NS.DB = MidnightHealerDB
  end

  CopyDefaults(NS.DB, defaults)

  if ((not next(NS.DB.bindings)) or (not next(NS.DB.hotSpellIds))) and NS.ApplyPreset then
    NS.ApplyPreset(NS.DB.preset or "DRUID_RESTO", true)
  end

  Print("Loaded v0.13.0 for WoW 12.1. /mh opens settings.")
end)

SLASH_MIDNIGHTHEALER1 = "/mh"
SLASH_MIDNIGHTHEALER2 = "/midnighthealer"
SlashCmdList["MIDNIGHTHEALER"] = function(msg)
  msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
  local lower = msg:lower()

  if lower == "savecustom" then
    if NS.SaveCurrentAsCustom then NS.SaveCurrentAsCustom(false) end
    return
  elseif lower == "savecustomspec" then
    if NS.SaveCurrentAsCustomForSpec then NS.SaveCurrentAsCustomForSpec(false) end
    return
  elseif lower == "test" then
    if NS.ToggleTestMode then NS.ToggleTestMode(nil) end
    return
  elseif lower == "lock" then
    if NS.DB and NS.DB.frame then NS.DB.frame.locked = true end
    if NS.UpdateMoveHandle then NS.UpdateMoveHandle() end
    Print("Frames locked.")
    return
  elseif lower == "unlock" then
    if NS.DB and NS.DB.frame then NS.DB.frame.locked = false end
    if NS.UpdateMoveHandle then NS.UpdateMoveHandle() end
    Print("Frames unlocked.")
    return
  elseif lower:match("^profile%s+") then
    local name = msg:gsub("^[Pp][Rr][Oo][Ff][Ii][Ll][Ee]%s+", "")
    if NS.SetProfile then NS.SetProfile(name, true) end
    Print("Profile: " .. name)
    return
  end

  if Settings and Settings.OpenToCategory then
    Settings.OpenToCategory("MidnightHealer")
  end

  Print("Commands: /mh test | /mh lock | /mh unlock | /mh profile <name> | /mh savecustom | /mh savecustomspec")
end
