-- This AIO was private. The republication of this AIO is a tribute to our friend Yoshino who has always helped me with the logic of scripts and wants to develop one day too. Force Yoshi!

-- Notice --
--This AIO was made for my private use. I'm sharing with the community for free, without asking for anything in return.
-- It is the result of the work of several developers, in addition to my own work, and may even contain code snippets or similarities with codes that I don't even know who the original author is.
--
--Also, as I do this for myself to play, AIO currently contains a Sett Pussy MOD (Duly identified and credited to him) and MAY, in the future, contain other things of the same type. Because sometimes I use script from another DEV to play and when this script has a flaw or something I fix myself.
--
--Example: Pussy's Sett currently doesn't do well. So I changed it for me to play.
--
--Main developers who contributed in some way: 
-- PussyKat (Helped a lot in all things!), Yoshino (Always helped me with logic when I needed it), extin (One of the first people who tested it), Feretorix (based on several excerpts from the scripts official), Deftsu (Original author AntiDash Logic), Gamsteron (Brand Attributes and combo logic), Sikaka (MF Q Logic), Maxxwell (MapPosition), Ark223 (I based on a few things about him, I can't remember exactly what), DamnedNoob (I got the idea of ​​Q Darius' movement from when I played with his script), BrainDotExe (I copied from him the concept of lastQ = GetTickCount ()),
--RugalVaper (I improved my ignite and exhaust from his old AIO), ty01314 (I met his work in the update from 10.3 to 10.4 the script crashed the loading of the GSO Orb and, on the run, I ended up solving this using the same idea that he uses in his AIO for delayed loading).
--
--If you find something in the middle of this AIO that is yours and you get nervous about it you can contact me indicating which section is yours, with a proof, and I will replace it with my own code on the same day.


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
local version = 0.08
local hero = myHero.charName
if hero == "Brand" or hero == "MissFortune" or hero == "Poppy" or hero == "Galio" or hero == "Zed" 
       or hero == "Sett" or hero == "Darius" then
  print("YosAIO (Soldier AIO) 0.08 loading...")
  Callback.Add("Load", function()
    DelayAction(function()
      if not AIO then
        AIO = true
        require("BLA_".. hero)
       print("YosAIO (Soldier AIO) 0.08 To ensure the functioning press f6 x 2")
      end
    end, 2)
  end)


else
  print("Champ not supported by YosAIO")
end
