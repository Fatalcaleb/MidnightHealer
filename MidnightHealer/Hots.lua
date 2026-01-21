-- Author: Fatalcaleb
-- Hots.lua
local ADDON, NS = ...

local function EnsureHotSquares(btn, count)
  if btn.MH_HotSquares then return btn.MH_HotSquares end
  btn.MH_HotSquares = {}

  local parent = btn.HotRow
  if not parent then return btn.MH_HotSquares end

  for i = 1, count do
    local s = parent:CreateTexture(nil, "OVERLAY")
    s:SetSize(8, 8)
    s:SetPoint("LEFT", (i - 1) * 10, 0)
    s:SetColorTexture(0.8, 0.8, 0.8, 0.0)
    btn.MH_HotSquares[i] = s
  end

  return btn.MH_HotSquares
end

local function FindAuraBySpellId(unit, spellId)
  for i = 1, 40 do
    local name, icon, count, _, duration, expirationTime, source, _, _, auraSpellId =
      UnitAura(unit, i, "HELPFUL|PLAYER")
    if not name then break end
    if auraSpellId == spellId then
      return true, icon, (count or 0), (duration or 0), (expirationTime or 0)
    end
  end
  return false
end

local function UpdateUnitButton(btn)
  if (NS.DB.features or {}).showHots == false then
    if btn.MH_HotSquares then
      for _, t in ipairs(btn.MH_HotSquares) do t:SetColorTexture(0.8,0.8,0.8,0.0) end
    end
    return
  end
  local unit = btn.unit
  if not unit or not UnitExists(unit) then return end

  local hotIds = NS.DB.hotSpellIds or {}
  local squares = EnsureHotSquares(btn, math.max(#hotIds, 5))

  for i = 1, #hotIds do
    local spellId = hotIds[i]
    local active, _, _, _, exp = FindAuraBySpellId(unit, spellId)
    local tex = squares[i]
    if tex then
      if active then
        local now = GetTime()
        local remaining = (exp or 0) - now
        local a = 0.95
        if remaining <= 4 then
          a = 0.35
        elseif remaining <= 8 then
          a = 0.65
        end
        tex:SetColorTexture(0.2, 1.0, 0.2, a)
      else
        tex:SetColorTexture(0.8, 0.8, 0.8, 0.0)
      end
    end
  end
end

local function HookButton(btn)
  if btn.MH_HotsHooked then return end
  btn.MH_HotsHooked = true

  btn:RegisterUnitEvent("UNIT_AURA", btn.unit)
  btn:HookScript("OnEvent", function(self, event, arg1)
    if event == "UNIT_AURA" and arg1 == self.unit then
      UpdateUnitButton(self)
    end
  end)

  UpdateUnitButton(btn)
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
