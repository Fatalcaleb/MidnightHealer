-- Author: Fatalcaleb
-- Cluster.lua
--
-- Midnight 12.1 compatibility note:
-- The previous implementation combined UnitHealth/UnitHealthMax with distance
-- data to count nearby injured players and highlight an AoE-heal opportunity.
-- In restricted content those health values may be secret, and deriving a
-- recommendation from them is no longer a safe addon pattern.
--
-- The profile keys are intentionally retained in Core.lua for migration, but
-- this analyzer is disabled in 0.13.0.
local ADDON, NS = ...

local function ClearClusterIndicators()
  local header = _G["MidnightHealerHeader"]
  if not header then return end

  local children = { header:GetChildren() }
  for _, btn in ipairs(children) do
    if btn.ClusterGlow then btn.ClusterGlow:SetAlpha(0) end
    if btn.ClusterText then btn.ClusterText:SetText("") end
  end
end

function NS.UpdateClusters()
  ClearClusterIndicators()
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:SetScript("OnEvent", ClearClusterIndicators)
