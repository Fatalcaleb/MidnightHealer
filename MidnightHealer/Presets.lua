-- Author: Fatalcaleb
-- Presets.lua
local ADDON, NS = ...

NS.LayoutPresets = {
  CLASSIC = {
    frame = { unitWidth = 200, unitHeight = 38, layoutMode="GROUPS_8" },
    features = {
      colorSource = { bar="CLASS", name="NONE", border="NONE" },
      colorTargets = { bar=true, name=false, border=false },
      hpTextMode = "PERCENT",
    },
  },

  VUHDO = {
    frame = { unitWidth = 220, unitHeight = 44, layoutMode="COLUMNS_2" },
    features = {
      colorSource = { bar="CLASS", name="CLASS", border="DEBUFF" },
      colorTargets = { bar=true, name=true, border=true },
      hpTextMode = "BOTH",
    },
  },

  MINIMAL = {
    frame = { unitWidth = 190, unitHeight = 32, layoutMode="COLUMNS_2" },
    features = {
      colorSource = { bar="CUSTOM", name="NONE", border="NONE" },
      colorTargets = { bar=true, name=false, border=false },
      hpTextMode = "NONE",
    },
  },
}

function NS.ApplyLayoutPreset(name)
  local p = NS.LayoutPresets[name]
  if not p then return end

  for k,v in pairs(p.frame or {}) do
    NS.DB.frame[k] = v
  end
  for k,v in pairs(p.features or {}) do
    NS.DB.features[k] = v
  end

  if NS.RebuildFrames and not InCombatLockdown() then
    NS.RebuildFrames()
  end
end
