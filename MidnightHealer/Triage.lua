-- Author: Fatalcaleb
-- Triage.lua
-- Midnight 12.1-safe frame state helpers. Aura/debuff prioritization has been
-- removed from this module because indexed aura inspection is restricted.
local ADDON, NS = ...

local function GetUnit(btn)
  if not btn then return nil end
  local unit = btn:GetAttribute("unit") or btn.unit
  if unit then btn.unit = unit end
  return unit
end

local function ClearAuraDerivedIndicators(btn)
  if btn.DebuffBox then
    if btn.DebuffBox.Icon then btn.DebuffBox.Icon:SetAlpha(0) end
    if btn.DebuffBox.Border then btn.DebuffBox.Border:SetAlpha(0) end
  end
  if btn.SwiftmendPip then btn.SwiftmendPip:SetAlpha(0) end
  if btn.MH_LBText then btn.MH_LBText:SetText("") end
end

local function SetRangeAndState(btn)
  local unit = GetUnit(btn)
  if not unit or not UnitExists(unit) then return end

  local dead = UnitIsDeadOrGhost(unit)
  local connected = UnitIsConnected(unit)

  if btn.StateText then
    if (NS.DB.features or {}).showStateText == false then
      btn.StateText:SetText("")
    elseif not connected then
      btn.StateText:SetText("OFFLINE")
    elseif dead then
      btn.StateText:SetText("DEAD")
    else
      btn.StateText:SetText("")
    end
  end

  local alpha = 1
  local inRange = UnitInRange(unit)
  if inRange == false then alpha = 0.45 end
  if (not connected) or dead then alpha = 0.35 end
  btn:SetAlpha(alpha)
end

local function SetRoleIcon(btn)
  if not btn.RoleIcon then return end
  if (NS.DB.features or {}).showRoleIcon == false then
    btn.RoleIcon:SetAlpha(0)
    return
  end

  local unit = GetUnit(btn)
  if not unit or not UnitExists(unit) then
    btn.RoleIcon:SetAlpha(0)
    return
  end

  local role = UnitGroupRolesAssigned(unit)
  if role == "TANK" then
    btn.RoleIcon:SetAtlas("roleicon-tiny-tank")
    btn.RoleIcon:SetAlpha(1)
  elseif role == "HEALER" then
    btn.RoleIcon:SetAtlas("roleicon-tiny-healer")
    btn.RoleIcon:SetAlpha(1)
  elseif role == "DAMAGER" then
    btn.RoleIcon:SetAtlas("roleicon-tiny-dps")
    btn.RoleIcon:SetAlpha(1)
  else
    btn.RoleIcon:SetAlpha(0)
  end
end

local function SetAggroHighlight(btn)
  if not btn.AggroBorder then return end
  if (NS.DB.features or {}).showAggro == false then
    btn.AggroBorder:SetAlpha(0)
    return
  end

  local unit = GetUnit(btn)
  if not unit or not UnitExists(unit) then
    btn.AggroBorder:SetAlpha(0)
    return
  end

  -- Threat state can itself become secret. Query the secret predicate before
  -- attempting a numeric comparison; if restricted, simply hide the hint.
  if C_Secrets and C_Secrets.ShouldUnitThreatStateBeSecret and C_Secrets.ShouldUnitThreatStateBeSecret(unit) then
    btn.AggroBorder:SetAlpha(0)
    return
  end

  local threat = UnitThreatSituation(unit)
  btn.AggroBorder:SetAlpha((threat and threat >= 2) and 1 or 0)
end

local function SetRaidGroupLabel(btn)
  if not btn.GroupText then return end
  local unit = GetUnit(btn)
  if not unit or not UnitExists(unit) or not IsInRaid() then
    btn.GroupText:SetText("")
    return
  end

  local name = UnitName(unit)
  if not name then
    btn.GroupText:SetText("")
    return
  end

  for i = 1, GetNumGroupMembers() do
    local raidName, _, subgroup = GetRaidRosterInfo(i)
    if raidName == name and subgroup then
      btn.GroupText:SetText("G" .. tostring(subgroup))
      return
    end
  end
  btn.GroupText:SetText("")
end

local function UpdateTriage(btn)
  if not NS.DB then return end
  ClearAuraDerivedIndicators(btn)
  SetRangeAndState(btn)
  SetRoleIcon(btn)
  SetAggroHighlight(btn)
  SetRaidGroupLabel(btn)
end

local function HookButton(btn)
  local unit = GetUnit(btn)
  if not unit or btn.MH_TriageHooked then return end
  btn.MH_TriageHooked = true

  btn:RegisterUnitEvent("UNIT_CONNECTION", unit)
  btn:RegisterUnitEvent("UNIT_FLAGS", unit)
  btn:RegisterUnitEvent("UNIT_THREAT_SITUATION_UPDATE", unit)

  btn:HookScript("OnEvent", function(self, _, arg1)
    if arg1 and arg1 ~= GetUnit(self) then return end
    UpdateTriage(self)
  end)

  btn:HookScript("OnUpdate", function(self, elapsed)
    self.MH_RangeT = (self.MH_RangeT or 0) + elapsed
    if self.MH_RangeT < 0.25 then return end
    self.MH_RangeT = 0
    SetRangeAndState(self)
  end)

  UpdateTriage(btn)
end

local function HookAllButtons()
  local header = _G["MidnightHealerHeader"]
  if not header or not NS.DB then return end
  local children = { header:GetChildren() }
  for _, child in ipairs(children) do
    if child and child.GetAttribute and child:GetAttribute("unit") then
      HookButton(child)
    end
  end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:SetScript("OnEvent", HookAllButtons)

NS.RefreshTriage = HookAllButtons
