-- Author: Fatalcaleb
-- Profiles.lua
local ADDON, NS = ...

local function DeepCopy(src)
  if type(src) ~= "table" then return src end
  local dst = {}
  for k, v in pairs(src) do
    dst[k] = DeepCopy(v)
  end
  return dst
end

local function GetCharKey()
  local name = UnitName("player") or "Unknown"
  local realm = GetRealmName() or "Realm"
  return name .. " - " .. realm
end

local function EnsureRootDB()
  MidnightHealerDB = MidnightHealerDB or {}
  local root = MidnightHealerDB

  -- Migration: old flat DB -> profiles format
  if root.profiles == nil or root.profileKeys == nil then
    local old = DeepCopy(root)
    root.profiles = root.profiles or {}
    root.profileKeys = root.profileKeys or {}

    -- Only migrate if it looks like the old format
    if old and type(old) == "table" and old.preset ~= nil then
      root.profiles["Default"] = old
      root.profileKeys[GetCharKey()] = "Default"
      -- wipe root keys except profiles/profileKeys
      for k in pairs(root) do
        if k ~= "profiles" and k ~= "profileKeys" then
          root[k] = nil
        end
      end
    else
      root.profiles["Default"] = root.profiles["Default"] or {}
      root.profileKeys[GetCharKey()] = root.profileKeys[GetCharKey()] or "Default"
    end
  end

  root.profiles = root.profiles or { ["Default"] = {} }
  root.profileKeys = root.profileKeys or {}
  return root
end

function NS.GetRootDB()
  return EnsureRootDB()
end

local function EnsureProfile(name)
  local root = EnsureRootDB()
  root.profiles[name] = root.profiles[name] or {}
  return root.profiles[name]
end

function NS.GetActiveProfileName()
  local root = EnsureRootDB()
  return root.profileKeys[GetCharKey()] or "Default"
end

function NS.GetActiveProfile()
  local root = EnsureRootDB()
  local name = NS.GetActiveProfileName()
  return EnsureProfile(name), name
end

function NS.SetProfile(name, silent)
  local root = EnsureRootDB()
  if not name or name == "" then return end
  EnsureProfile(name)
  root.profileKeys[GetCharKey()] = name
  NS.DB = root.profiles[name]
  if NS.ApplyDefaults then NS.ApplyDefaults(NS.DB) end
  if NS.Print and not silent then NS.Print("Profile set to: " .. name) end

  -- Rebuild/apply after profile switch
  if NS.RequestSecureApply and NS.RequestSecureApply() then
    if NS.RebuildFrames then NS.RebuildFrames() end
    if NS.ReapplyClickCast then NS.ReapplyClickCast() end
  end
  if NS.RefreshTestLayout then NS.RefreshTestLayout() end
  if NS.UpdateMoveHandle then NS.UpdateMoveHandle() end
end

function NS.ListProfiles()
  local root = EnsureRootDB()
  local t = {}
  for name in pairs(root.profiles) do t[#t+1] = name end
  table.sort(t)
  return t
end

function NS.CreateProfile(name, copyFrom, silent)
  local root = EnsureRootDB()
  if not name or name == "" then return false end
  if root.profiles[name] then return false end

  if copyFrom and root.profiles[copyFrom] then
    root.profiles[name] = DeepCopy(root.profiles[copyFrom])
  else
    root.profiles[name] = {}
  end
  if NS.Print and not silent then NS.Print("Created profile: " .. name) end
  return true
end

function NS.DeleteProfile(name, silent)
  local root = EnsureRootDB()
  if not name or name == "" or name == "Default" then return false end
  if not root.profiles[name] then return false end

  root.profiles[name] = nil
  -- Reassign any characters using it back to Default
  for k, v in pairs(root.profileKeys) do
    if v == name then root.profileKeys[k] = "Default" end
  end

  -- If we deleted active, switch
  if NS.GetActiveProfileName() == name then
    NS.SetProfile("Default", true)
  end

  if NS.Print and not silent then NS.Print("Deleted profile: " .. name) end
  return true
end

-- Bind to login to set NS.DB pointer early
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
  local root = EnsureRootDB()
  local profile, name = NS.GetActiveProfile()
  NS.DB = profile
  NS.RootDB = root
end)




-- Profile Import/Export (no external libs)
local function _MH_EncodeValue(v, out)
  local t = type(v)
  if t == "nil" then
    out[#out+1] = "n"
  elseif t == "boolean" then
    out[#out+1] = v and "t" or "f"
  elseif t == "number" then
    out[#out+1] = "d"
    out[#out+1] = tostring(v)
    out[#out+1] = ";"
  elseif t == "string" then
    out[#out+1] = "s"
    out[#out+1] = tostring(#v)
    out[#out+1] = ":"
    out[#out+1] = v
  elseif t == "table" then
    out[#out+1] = "m"
    local count = 0
    for k in pairs(v) do count = count + 1 end
    out[#out+1] = tostring(count)
    out[#out+1] = ":{"
    for k, vv in pairs(v) do
      _MH_EncodeValue(k, out)
      _MH_EncodeValue(vv, out)
    end
    out[#out+1] = "}"
  else
    -- unsupported types -> nil
    out[#out+1] = "n"
  end
end

local function _MH_DecodeValue(s, i)
  local tag = s:sub(i,i)
  if tag == "n" then
    return nil, i+1
  elseif tag == "t" then
    return true, i+1
  elseif tag == "f" then
    return false, i+1
  elseif tag == "d" then
    local j = s:find(";", i+1, true)
    if not j then return nil, #s+1 end
    local num = tonumber(s:sub(i+1, j-1))
    return num, j+1
  elseif tag == "s" then
    local j = s:find(":", i+1, true)
    if not j then return nil, #s+1 end
    local len = tonumber(s:sub(i+1, j-1)) or 0
    local start = j+1
    local stop = start + len - 1
    return s:sub(start, stop), stop+1
  elseif tag == "m" then
    local j = s:find(":{", i+1, true)
    if not j then return nil, #s+1 end
    local count = tonumber(s:sub(i+1, j-1)) or 0
    local tbl = {}
    local idx = j+2
    for _ = 1, count do
      local k; k, idx = _MH_DecodeValue(s, idx)
      local v; v, idx = _MH_DecodeValue(s, idx)
      tbl[k] = v
    end
    if s:sub(idx, idx) == "}" then idx = idx + 1 end
    return tbl, idx
  end
  return nil, i+1
end

function NS.ExportActiveProfile()
  local out = {}
  _MH_EncodeValue(NS.DB, out)
  return table.concat(out)
end

function NS.ImportProfile(encoded)
  if type(encoded) ~= "string" or encoded == "" then return false end
  local decoded = nil
  local ok = pcall(function()
    decoded = select(1, _MH_DecodeValue(encoded, 1))
  end)
  if not ok or type(decoded) ~= "table" then return false end

  -- Replace active profile contents in-place (keeps references stable)
  for k in pairs(NS.DB) do NS.DB[k] = nil end
  for k, v in pairs(decoded) do NS.DB[k] = v end

  if NS.ApplyDefaults then NS.ApplyDefaults(NS.DB) end
  if NS.ReapplyClickCast then NS.ReapplyClickCast() end
  if NS.RebuildFrames and not InCombatLockdown() then NS.RebuildFrames() end
  if NS.RefreshTestLayout then NS.RefreshTestLayout() end
  if NS.UpdateMoveHandle then NS.UpdateMoveHandle() end
  return true
end

