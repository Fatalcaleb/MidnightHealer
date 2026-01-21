-- Author: Fatalcaleb
-- SpecProfiles.lua
local ADDON, NS = ...

local function ShallowCopy(tbl)
  local out = {}
  for k, v in pairs(tbl or {}) do out[k] = v end
  return out
end

local function ArrayCopy(arr)
  local out = {}
  for i = 1, #(arr or {}) do out[i] = arr[i] end
  return out
end

local function GetSpecID()
  local specIndex = GetSpecialization()
  if not specIndex then return nil end
  local specID = GetSpecializationInfo(specIndex)
  return specID
end

local function GetClass()
  local _, class = UnitClass("player")
  return class
end

local function SaveCurrentToSpec(specID)
  if not specID then return end
  local sp = NS.DB.specProfiles
  if not sp or not sp.data then return end
  sp.data[specID] = {
    preset = NS.DB.preset,
    bindings = ShallowCopy(NS.DB.bindings),
    hotSpellIds = ArrayCopy(NS.DB.hotSpellIds),
    stackTracker = ShallowCopy(NS.DB.stackTracker or { spellId=0, squareIndex=0 }),
  }
end

local function LoadFromSpec(specID)
  if not specID then return false end
  local sp = NS.DB.specProfiles
  local d = sp and sp.data and sp.data[specID]
  if not d then return false end

  NS.DB.preset = d.preset or NS.DB.preset
  NS.DB.bindings = ShallowCopy(d.bindings or {})
  NS.DB.hotSpellIds = ArrayCopy(d.hotSpellIds or {})
  NS.DB.stackTracker = ShallowCopy(d.stackTracker or { spellId=0, squareIndex=0 })

  if NS.RequestSecureApply and not NS.RequestSecureApply() then return true end
  if NS.ReapplyClickCast then NS.ReapplyClickCast() end
  return true
end

local function ApplyDefaultForSpec(specID)
  local class = GetClass()
  local map = NS.DEFAULT_PRESET_BY_SPEC and NS.DEFAULT_PRESET_BY_SPEC[class]
  local presetKey = map and map[specID]
  if presetKey and NS.ApplyPreset then
    NS.ApplyPreset(presetKey, true)
    return true
  end
  return false
end

function NS.SaveSpecProfileNow()
  SaveCurrentToSpec(GetSpecID())
  if NS.Print then NS.Print("Saved profile for current spec.") end
end

function NS.ClearSpecProfileNow()
  local specID = GetSpecID()
  if not specID then return end
  local sp = NS.DB.specProfiles
  if sp and sp.data then
    sp.data[specID] = nil
    if NS.Print then NS.Print("Cleared profile for current spec.") end
  end
end

local lastSpecID = nil
local function HandleSpecChange()
  if not NS.DB or not NS.DB.specProfiles then return end
  local sp = NS.DB.specProfiles
  if not sp.enabled then return end

  local specID = GetSpecID()
  if not specID then return end

  if sp.remember and lastSpecID and lastSpecID ~= specID then
    SaveCurrentToSpec(lastSpecID)
  end

  local loaded = LoadFromSpec(specID)
  if not loaded then
    ApplyDefaultForSpec(specID)
    if sp.remember then SaveCurrentToSpec(specID) end
  end

  lastSpecID = specID
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(_, event, unit)
  if event == "PLAYER_SPECIALIZATION_CHANGED" and unit and unit ~= "player" then return end
  if not NS.DB then return end
  HandleSpecChange()
end)
