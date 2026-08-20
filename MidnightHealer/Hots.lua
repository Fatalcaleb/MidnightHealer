-- Author: Fatalcaleb
-- Hots.lua
-- WoW Midnight 12.1 aura compatibility shim.
--
-- The pre-12.1 implementation iterated UnitAura and performed duration
-- arithmetic. In restricted content, aura data can be secret and indexed aura
-- APIs can error for addons. 0.13.0 intentionally disables that implementation
-- until HoT presentation is rebuilt on Blizzard's AuraContainer/AuraButton API.
local ADDON, NS = ...

local function ClearLegacyHotIndicators()
  local header = _G["MidnightHealerHeader"]
  if not header then return end

  local children = { header:GetChildren() }
  for _, btn in ipairs(children) do
    if btn and btn.MH_HotSquares then
      for _, tex in ipairs(btn.MH_HotSquares) do
        if tex and tex.SetAlpha then tex:SetAlpha(0) end
      end
    end
    if btn and btn.SwiftmendPip then btn.SwiftmendPip:SetAlpha(0) end
    if btn and btn.MH_LBText then btn.MH_LBText:SetText("") end
  end
end

function NS.RefreshHots()
  ClearLegacyHotIndicators()
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:SetScript("OnEvent", function()
  ClearLegacyHotIndicators()
end)
