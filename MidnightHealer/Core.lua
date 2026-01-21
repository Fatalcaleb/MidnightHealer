-- Author: Fatalcaleb
-- Core.lua
local ADDON, NS = ...

-- MidnightHealerDB is now a ROOT table with profiles.
-- NS.DB points to the ACTIVE profile table.

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
    showHpText = true,
    showCluster = true,
    showGroupLabels = true,

    hpTextMode = "PERCENT", -- PERCENT | VALUE | BOTH | NONE

    incomingHeals = {
      enabled = true,
      warnPct = 0.25, -- incoming heals / maxHP threshold
      tankBoost = true,
      normal = { r=0.20, g=1.00, b=0.20, a=0.35 },
      warn = { r=1.00, g=0.85, b=0.20, a=0.55 },
    },

    combatIndicator = { enabled = true, a = 0.20 },

    -- Coloring
  -- Backward compatible: colorMode still exists, but advanced sources below take precedence per-target.
  colorMode = "CLASS", -- CLASS | CUSTOM | NONE (legacy)
  colorTargets = { bar = true, name = false, border = false },

  -- Advanced: choose where each target's color comes from
  colorSource = {
    bar = "CLASS",    -- CLASS | ROLE | CUSTOM | NONE
    name = "NONE",    -- CLASS | ROLE | CUSTOM | NONE
    border = "NONE",  -- CLASS | ROLE | CUSTOM | DEBUFF | NONE
  },

  -- Custom colors (when source=CUSTOM)
  customColors = {
    bar = { r=0.10, g=0.80, b=0.10 },
    name = { r=1.00, g=1.00, b=1.00 },
    border = { r=0.90, g=0.90, b=0.90 },
  },

  -- Role colors (when source=ROLE)
  roleColors = {
    TANK = { r=0.20, g=0.55, b=1.00 },
    HEALER = { r=0.15, g=1.00, b=0.40 },
    DAMAGER = { r=1.00, g=0.25, b=0.25 },
    NONE = { r=0.85, g=0.85, b=0.85 },
  },

  -- Class overrides (when source=CLASS). Any missing class falls back to Blizzard class colors.
  classColors = {
    -- Example: ["DRUID"] = { r=1.0, g=0.49, b=0.04 }
  },

  -- Debuff dispel type colors (when border source=DEBUFF)
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

  cluster = { enabled = true, radius = 10, hpThreshold = 0.85, minCount = 4, showNumber = true },

  testMode = { enabled = false, count = 20, mode = "RAID" },
}

function NS.ApplyDefaults(profile)
  if profile then CopyDefaults(profile, defaults) end
end

local function CopyDefaults(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" then
      dst[k] = dst[k] or {}
      CopyDefaults(dst[k], v)
    elseif dst[k] == nil then
      dst[k] = v
    end
  end
end

local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffMidnightHealer:|r " .. tostring(msg))
end
NS.Print = Print

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, _, name)
  if name ~= ADDON then return end

  -- Profiles.lua sets NS.DB on PLAYER_LOGIN, but we want defaults before Settings panels build.
  if NS.GetActiveProfile then
    local profile = NS.GetActiveProfile()
    NS.DB = profile
  end

  if NS.DB then
    CopyDefaults(NS.DB, defaults)
  end

  -- Initialize from preset if empty
  if NS.DB and ((not next(NS.DB.bindings)) or (not next(NS.DB.hotSpellIds))) then
    if NS.ApplyPreset then
      NS.ApplyPreset(NS.DB.preset or "DRUID_RESTO", true)
    end
  end

  Print("Loaded. /mh opens settings. /mh lock | unlock | test | profile <name>")
end)

    return
  elseif lower == "savecustomspec" then
    if NS.SaveCurrentAsCustomForSpec then NS.SaveCurrentAsCustomForSpec(false) end
    return
  elseif lower == "test" then
    if NS.ToggleTestMode then NS.ToggleTestMode(nil) end
    return
  elseif lower == "lock" then
    NS.DB.frame.locked = true
    if NS.UpdateMoveHandle then NS.UpdateMoveHandle() end
    if NS.Print then NS.Print("Frames locked.") end
    return
  elseif lower == "unlock" then
    NS.DB.frame.locked = false
    if NS.UpdateMoveHandle then NS.UpdateMoveHandle() end
    if NS.Print then NS.Print("Frames unlocked.") end
    return
  end

  local prof = msg:match("^profile%s+(.+)$")
  if prof and prof ~= "" then
    if NS.SetProfile then NS.SetProfile(prof, false) end
    return
  end

  if Settings and Settings.OpenToCategory then
    Settings.OpenToCategory("MidnightHealer")
  else
    Print("Open Settings and search for MidnightHealer.")
  end
end


-- Slash commands (use unique key to avoid conflicts with other addons)
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
    NS.DB.frame.locked = true
    if NS.UpdateMoveHandle then NS.UpdateMoveHandle() end
    if NS.Print then NS.Print("Frames locked.") end
    return
  elseif lower == "unlock" then
    NS.DB.frame.locked = false
    if NS.UpdateMoveHandle then NS.UpdateMoveHandle() end
    if NS.Print then NS.Print("Frames unlocked.") end
    return
  elseif lower:match("^profile%s+") then
    local name = lower:gsub("^profile%s+", "")
    if NS.SetProfile then NS.SetProfile(name, true) end
    if NS.Print then NS.Print("Profile: " .. name) end
    return
  end

  if Settings and Settings.OpenToCategory then
    Settings.OpenToCategory("MidnightHealer")
  end
  if NS.Print then
    NS.Print("Commands: /mh test | /mh lock | /mh unlock | /mh profile <name> | /mh savecustom | /mh savecustomspec")
  end
end
