-- Author: Fatalcaleb
-- Triage.lua
local ADDON, NS = ...

local DEBUFF_COLORS = {
  Magic   = {0.2, 0.6, 1.0},
  Curse   = {0.7, 0.2, 1.0},
  Disease = {0.6, 0.4, 0.0},
  Poison  = {0.2, 1.0, 0.2},
  Bleed   = {1.0, 0.2, 0.2},
  none    = {1.0, 1.0, 1.0},
}

local function FindHelpfulBySpellId(unit, spellId)
  for i = 1, 40 do
    local name, icon, count, _, duration, expTime, source, _, _, auraSpellId =
      UnitAura(unit, i, "HELPFUL|PLAYER")
    if not name then break end
    if auraSpellId == spellId then
      return true, icon, (count or 0), (duration or 0), (expTime or 0)
    end
  end
  return false
end

local function AnyMyTrackedHot(unit)
  for _, id in ipairs(NS.DB.hotSpellIds or {}) do
    if FindHelpfulBySpellId(unit, id) then return true end
  end
  return false
end

local function GetBestDebuff(unit)
  local function score(dtype)
    if dtype == "Magic" then return 5 end
    if dtype == "Curse" then return 4 end
    if dtype == "Disease" then return 3 end
    if dtype == "Poison" then return 2 end
    if dtype == "Bleed" then return 1 end
    return 0
  end

  local bestIcon, bestType
  local bestScore = -1

  for i = 1, 40 do
    local name, icon, _, dtype = UnitDebuff(unit, i)
    if not name then break end
    local s = score(dtype)
    if s > bestScore then
      bestScore = s
      bestIcon, bestType = icon, dtype
    end
  end

  if not bestIcon then
    local name, icon, _, dtype = UnitDebuff(unit, 1)
    if name then bestIcon, bestType = icon, dtype end
  end

  return bestIcon, bestType
end

local function SetDebuffBox(btn)
  if (NS.DB.features or {}).showDebuff == false then if btn.DebuffBox then btn.DebuffBox.Icon:SetAlpha(0); btn.DebuffBox.Border:SetAlpha(0) end; return end
  if not btn.DebuffBox then return end
  local unit = btn.unit
  if not unit or not UnitExists(unit) then
    btn.DebuffBox.Icon:SetAlpha(0)
    btn.DebuffBox.Border:SetAlpha(0)
    return
  end

  local icon, dtype = GetBestDebuff(unit)
  if icon then
    btn.DebuffBox.Icon:SetTexture(icon)
    btn.DebuffBox.Icon:SetAlpha(1)
    local c = DEBUFF_COLORS[dtype or "none"] or DEBUFF_COLORS.none
    btn.DebuffBox.Border:SetColorTexture(c[1], c[2], c[3], 1)
    btn.DebuffBox.Border:SetAlpha(1)
  else
    btn.DebuffBox.Icon:SetAlpha(0)
    btn.DebuffBox.Border:SetAlpha(0)
  end
end

local function SetStackTracker(btn)
  local st = NS.DB.stackTracker or { spellId = 0, squareIndex = 0 }
  if not st.spellId or st.spellId == 0 or not st.squareIndex or st.squareIndex == 0 then
    if btn.MH_LBText then btn.MH_LBText:SetText("") end
    return
  end

  local unit = btn.unit
  if not unit or not UnitExists(unit) then return end

  local squares = btn.MH_HotSquares
  if not squares or not squares[st.squareIndex] then return end

  local active, _, stacks, _, exp = FindHelpfulBySpellId(unit, st.spellId)
  if not active then
    if btn.MH_LBText then btn.MH_LBText:SetText("") end
    return
  end

  local now = GetTime()
  local remaining = (exp or 0) - now
  local alpha = 0.95
  if remaining <= 4 then alpha = 0.35
  elseif remaining <= 8 then alpha = 0.65 end

  squares[st.squareIndex]:SetColorTexture(0.2, 1.0, 0.2, alpha)

  if not btn.MH_LBText then
    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 4, 3)
    fs:SetText("")
    btn.MH_LBText = fs
  end
  btn.MH_LBText:SetText(stacks and stacks > 0 and tostring(stacks) or "")
end

local function SetReadyPip(btn)
  if not btn.SwiftmendPip then return end
  local unit = btn.unit
  if unit and UnitExists(unit) and AnyMyTrackedHot(unit) then
    btn.SwiftmendPip:SetAlpha(0.9)
  else
    btn.SwiftmendPip:SetAlpha(0)
  end
end

local function SetRangeAndState(btn)
  local unit = btn.unit
  if not unit or not UnitExists(unit) then return end

  local dead = UnitIsDeadOrGhost(unit)
  local conn = UnitIsConnected(unit)

  if not conn then
    if (NS.DB.features or {}).showStateText == false then btn.StateText:SetText("") else btn.StateText:SetText("OFFLINE")
  elseif dead then
    if (NS.DB.features or {}).showStateText == false then btn.StateText:SetText("") else btn.StateText:SetText("DEAD")
  else
    if (NS.DB.features or {}).showStateText == false then btn.StateText:SetText("") else btn.StateText:SetText("")
  end

  local inRange = UnitInRange(unit)
  if inRange == false then
    btn:SetAlpha(0.45)
  else
    btn:SetAlpha(1.0)
  end

  if (not conn) or dead then
    btn:SetAlpha(0.35)
  end
end

local function SetRoleIcon(btn)
  if (NS.DB.features or {}).showRoleIcon == false then if btn.RoleIcon then btn.RoleIcon:SetAlpha(0) end; return end
  if not btn.RoleIcon then return end
  local unit = btn.unit
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
  if (NS.DB.features or {}).showAggro == false then if btn.AggroBorder then btn.AggroBorder:SetAlpha(0) end; return end
  if not btn.AggroBorder then return end
  local unit = btn.unit
  if not unit or not UnitExists(unit) then
    btn.AggroBorder:SetAlpha(0)
    return
  end

  local threat = UnitThreatSituation(unit)
  if threat and threat >= 2 then
    btn.AggroBorder:SetAlpha(1)
  else
    btn.AggroBorder:SetAlpha(0)
  end
end

local function SetRaidGroupLabel(btn)
  if not btn.GroupText then return end
  local unit = btn.unit
  if not unit or not UnitExists(unit) then
    btn.GroupText:SetText("")
    return
  end
  if not IsInRaid() then
    btn.GroupText:SetText("")
    return
  end

  local name = UnitName(unit)
  if not name then
    btn.GroupText:SetText("")
    return
  end

  for i = 1, GetNumGroupMembers() do
    local n, _, subgroup = GetRaidRosterInfo(i)
    if n == name and subgroup then
      btn.GroupText:SetText("G" .. tostring(subgroup))
      return
    end
  end
  btn.GroupText:SetText("")
end

local function UpdateTriage(btn)
  SetRangeAndState(btn)
  SetDebuffBox(btn)
  SetReadyPip(btn)
  SetStackTracker(btn)
  SetRoleIcon(btn)
  SetAggroHighlight(btn)
  SetRaidGroupLabel(btn)
end

local function HookButton(btn)
  if btn.MH_TriageHooked then return end
  btn.MH_TriageHooked = true

  btn:RegisterUnitEvent("UNIT_AURA", btn.unit)
  btn:RegisterUnitEvent("UNIT_CONNECTION", btn.unit)
  btn:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", btn.unit)
  btn:RegisterUnitEvent("UNIT_THREAT_SITUATION_UPDATE", btn.unit)
  btn:RegisterUnitEvent("UNIT_OTHER_PARTY_CHANGED", btn.unit)

  btn:HookScript("OnEvent", function(self, event, arg1)
    if arg1 and arg1 ~= self.unit then return end
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
  if not header then return end
  local i = 1
  while true do
    local child = select(i, header:GetChildren())
    if not child then break end
    if child.unit then HookButton(child) end
    i = i + 1
  end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:SetScript("OnEvent", function()
  HookAllButtons()
end)
