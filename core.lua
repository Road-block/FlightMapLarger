local addonName, addon = ...

addon.IsMoPC = WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC
local minset, maxset, defset = 1.0, 2.0, 1.5
if addon.IsMoPC then
  minset,maxset,defset = 0.8, 1.5, 1.2
end
FlightMapLargerDB = FlightMapLargerDB or {size=defset}
local _p = {}
_p.defaults = {
  width = 384,
  height = 512,
  w_art = 256,
  h_art = 256,
  node_base = 16,
  global_taximap_w = 316,
  global_taximap_h = 352,
}
if addon.IsMoPC then
  _p.defaults.width = 590
  _p.defaults.height = 608
  _p.defaults.global_taximap_w = 580
  _p.defaults.global_taximap_h = 580
end
local function SetupTaxiFrame()
  if FlightMapLargerDB.size == 1.0 then return end
  if TaxiFrame then
    local padx, pady = _p.defaults.width*(FlightMapLargerDB.size or defset)-_p.defaults.width, _p.defaults.height*(FlightMapLargerDB.size or 1.5)-_p.defaults.height
    TaxiFrame:SetWidth(_p.defaults.width*(FlightMapLargerDB.size or defset))
    TaxiFrame:SetHeight(_p.defaults.height*(FlightMapLargerDB.size or defset))
    TAXI_MAP_WIDTH = _p.defaults.global_taximap_w+padx
    TAXI_MAP_HEIGHT = _p.defaults.global_taximap_h+pady
--    TaxiMap:SetWidth(TAXI_MAP_WIDTH)
--    TaxiMap:SetHeight(TAXI_MAP_HEIGHT)
    TaxiRouteMap:SetWidth(TAXI_MAP_WIDTH)
    TaxiRouteMap:SetHeight(TAXI_MAP_HEIGHT)
    for i, region in ipairs({TaxiFrame:GetRegions()}) do
      if region.GetObjectType and region:GetObjectType() == "Texture" then
        local fileID = region:GetTextureFileID()
        if fileID == 137041 then -- top left corner
          region:SetHorizTile(true)
          region:SetVertTile(true)
          region:SetWidth(_p.defaults.w_art+padx)
          region:SetHeight(_p.defaults.h_art+pady)
        elseif fileID == 137042 then -- top right corner
          region:SetPoint("TOPLEFT", _p.defaults.w_art+padx, 0)
          region:SetVertTile(true)
          region:SetHeight(_p.defaults.h_art+pady)
        elseif fileID == 137039 then -- bottom left corner
          region:SetPoint("TOPLEFT", 0, -(_p.defaults.h_art+pady))
          region:SetHorizTile(true)
          region:SetWidth(_p.defaults.w_art+padx)
        elseif fileID == 137040 then -- bottom right corner
          region:SetPoint("TOPLEFT", _p.defaults.w_art+padx, -(_p.defaults.h_art+pady))
        end
      end
    end
  end
end

local function NodeMultiplier(map_mult)
  local nodeBase = 0.5
  local map_extra = map_mult - 1.0
  local node_mult = nodeBase + (map_extra/2)
  return node_mult
end

local frame = CreateFrame("Frame")
frame.OnEvent = function(self,event,...)
  return frame[event] and frame[event](frame,...)
end
frame:SetScript("OnEvent",frame.OnEvent)
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("TAXIMAP_OPENED")
local loader = CreateFrame("Frame")
loader.AddonLoaded = function(self,event,...)
  if ... == addonName then
    FlightMapLargerDB = FlightMapLargerDB or {size=defset}
    loader:UnregisterEvent("ADDON_LOADED")
    C_Timer.After(5,function()
      print(format("FlightMap Larger: /fml N [%.1F to %.1F]",minset,maxset))
    end)
  end
end
loader:SetScript("OnEvent",loader.AddonLoaded)
loader:RegisterEvent("ADDON_LOADED")

function frame:ADDON_LOADED(...)
  if ... == "Blizzard_UIPanels_Game" then
    frame:UnregisterEvent("PLAYER_LOGIN")
    SetupTaxiFrame()
  end
end

function frame:PLAYER_ENTERING_WORLD(...)
  local isLogin, isReload = ...
  if isLogin or isReload then
    if C_AddOns.IsAddOnLoaded("Blizzard_UIPanels_Game") then
      frame:UnregisterEvent("ADDON_LOADED")
      SetupTaxiFrame()
    end
  end
end

function frame:TAXIMAP_OPENED()
  if FlightMapLargerDB.size == 1.0 then return end
  local nodeMult = NodeMultiplier(FlightMapLargerDB.size)
  local nodeSize = Round(_p.defaults.node_base * nodeMult)
  local nodeButton, nodeButtonTex
  for i = 1, NumTaxiNodes() do
    nodeButton = _G["TaxiButton"..i]

    if nodeButton then
      nodeButton:SetWidth(nodeSize)
      nodeButton:SetHeight(nodeSize)
      nodeButtonTex = nodeButton:GetHighlightTexture()
      if nodeButtonTex then
        nodeButtonTex:SetSize(nodeSize*2, nodeSize*2)
      end
    end
  end

end
local addonNameU, addonNameL = addonName:upper(), addonName:lower()
SlashCmdList[addonNameU] = function(input)
  local size = tonumber(input or "")
  if (not size) or (size < minset) or (size > maxset) then
    print(format("FlightMap Larger: /fml N [%.1F to %.1F])",minset,maxset))
    return
  else
    if FlightMapLargerDB.size ~= size then
      FlightMapLargerDB.size = size
      CloseTaxiMap()
      SetupTaxiFrame()
    end
  end
end
_G["SLASH_"..addonNameU.."1"] = "/"..addonNameL
_G["SLASH_"..addonNameU.."2"] = "/fml"
