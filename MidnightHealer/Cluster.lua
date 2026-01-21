-- Author: Fatalcaleb
-- Cluster.lua
local ADDON, NS = ...

-- Cluster help: highlights "stack near you" (player-centric clump).
-- This is intentionally conservative: distance APIs are typically player->unit, not unit->unit.

local function UnitHP(unit)
  local hp = UnitHealth(unit)
  local maxHp = UnitHealthMax(unit)
  if not maxHp or maxHp <= 0 then return 1 end
  return hp / maxHp
end

local function GetButtons()
  local header = _G["MidnightHealerHeader"]
  if not header then return nil end

  local buttons = {}
  local i = 1
  while true do
    local child = select(i, header:GetChildren())
    if not child then break end
    if child.unit and UnitExists(child.unit) then
      buttons[#buttons+1] = child
    end
    i = i + 1
  end
  return buttons
end

local function DistanceSquared(unit)
  local dsq, ok = UnitDistanceSquared(unit)
  if ok ~= true then return nil end
  return dsq
end

local function ClearCluster(btn)
  if btn.ClusterGlow then btn.ClusterGlow:SetAlpha(0) end
  if btn.ClusterText then btn.ClusterText:SetText("") end
end

local function SetCluster(btn, count, hot)
  if btn.ClusterText then
    if NS.DB.cluster.showNumber then
      btn.ClusterText:SetText(count > 0 and tostring(count) or "")
    else
      btn.ClusterText:SetText("")
    end
  end
  if btn.ClusterGlow then
    btn.ClusterGlow:SetAlpha(hot and 1 or 0)
  end
end

local function UpdateClusters()
  if not NS.DB or not NS.DB.cluster or not NS.DB.cluster.enabled or (NS.DB.features or {}).showCluster == false then return end

  local buttons = GetButtons()
  if not buttons or #buttons <= 1 then return end

  local radius = NS.DB.cluster.radius or 10
  local hpTh = NS.DB.cluster.hpThreshold or 0.85
  local minCount = NS.DB.cluster.minCount or 3
  local r2 = radius * radius

  for i = 1, #buttons do
    ClearCluster(buttons[i])
  end

  local inBubble = {}
  for i = 1, #buttons do
    local u = buttons[i].unit
    if UnitIsConnected(u) and not UnitIsDeadOrGhost(u) then
      local dsq = DistanceSquared(u)
      if dsq and dsq <= r2 then
        inBubble[#inBubble+1] = { btn = buttons[i], unit = u, injured = (UnitHP(u) <= hpTh) }
      end
    end
  end

  local injuredCount = 0
  for i = 1, #inBubble do
    if inBubble[i].injured then injuredCount = injuredCount + 1 end
  end

  local hot = (injuredCount >= minCount)
  for i = 1, #inBubble do
    SetCluster(inBubble[i].btn, injuredCount, hot)
  end
end

local f = CreateFrame("Frame")
f:SetScript("OnUpdate", function(self, elapsed)
  if not NS.DB or not NS.DB.cluster or not NS.DB.cluster.enabled or (NS.DB.features or {}).showCluster == false then return end
  self.t = (self.t or 0) + elapsed
  if self.t < 0.4 then return end
  self.t = 0
  UpdateClusters()
end)

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("GROUP_ROSTER_UPDATE")
ev:RegisterEvent("UNIT_HEALTH_FREQUENT")
ev:RegisterEvent("UNIT_CONNECTION")
ev:SetScript("OnEvent", function()
  UpdateClusters()
end)
