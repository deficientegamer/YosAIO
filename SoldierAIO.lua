-- Check have libs useds by heros
if not FileExist(COMMON_PATH .. "PussyDamageLib.lua") then
  print("PussyDamageLib installed Press 2x F6")
  DownloadFileAsync("https://raw.githubusercontent.com/Pussykate/GoS/master/PussyDamageLib.lua", COMMON_PATH .. "PussyDamageLib.lua", function() end)
  while not FileExist(COMMON_PATH .. "PussyDamageLib.lua") do end
end

if not FileExist(COMMON_PATH .. "GamsteronPrediction.lua") then
  print("GamsteronPrediction installed Press 2x F6")
  DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GOS-EXT/master/Common/GamsteronPrediction.lua", COMMON_PATH .. "GamsteronPrediction.lua", function() end)
  while not FileExist(COMMON_PATH .. "GamsteronPrediction.lua.lua") do end
end

-- globals
local version = 0.04
local hero = myHero.charName
if hero == "Brand" or hero == "MissFortune" or hero == "Poppy" then
  print("SoldierAIO 0.04 waiting GSOOrb for 3 second's...")
  Callback.Add("Load", function()
    DelayAction(function()
      if not AIO then
        AIO = true
        require("BLA_".. hero)
       print("Loading SoldierAIO 0.04 Press F6 x2")
      end
    end, 3)
  end)


else
  print("Champ not supported by BotLane AIO")
end
