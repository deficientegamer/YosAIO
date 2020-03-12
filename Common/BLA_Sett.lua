require("BLA_Common") -- load common functions
require('GamsteronPrediction')
require('PussyDamageLib')

GameMinionCount      = Game.MinionCount;

GameMinion         = Game.Minion;

class "Sett"

local function GetEnemyHeroes()
  return Enemies
end

function GetMinionCount(range, pos)
  local pos = pos.pos
  local count = 0
  for i = 1,Game.MinionCount() do
    local hero = Game.Minion(i)
    local Range = range * range
    if hero.team ~= TEAM_ALLY and hero.dead == false and GetDistanceSquared(pos, hero.pos) < Range then
      count = count + 1
    end
  end
  return count
end

function Sett:__init()

  self.W =   {Type = _G.SPELLTYPE_LINE, Delay = 0.52, Radius = 90, Range = 750, Speed = MathHuge, Collision = false }


  self:LoadMenu()

  OnAllyHeroLoad(function(hero)
    TableInsert(Allys, hero);
  end)

  OnEnemyHeroLoad(function(hero)
    TableInsert(Enemys, hero);
  end)

  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)

  Orb:OnPreMovement(
    function(args)
      if lastMove + 60 > GetTickCount() then
        args.Process = false
      else
        args.Process = true
        lastMove = GetTickCount()
      end
    end
  )
end

function Sett:LoadMenu()

  Menu = MenuElement({type = MENU, id = "BLASett", name = "PussyAIO Sett Mod RC 0.1"})

  --ComboMenu
  Menu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
  Menu.Combo:MenuElement({id = "UseQ", name = "[Q]", value = true})
  Menu.Combo:MenuElement({id = "UseW", name = "[W]", value = true})
  Menu.Combo:MenuElement({id = "Grit", name = "Min Grit to Use [W]", value = 50, min = 0, max = 100, identifier = "%"})
  Menu.Combo:MenuElement({id = "UseE", name = "[E]", value = true})
  Menu.Combo:MenuElement({id = "UseR", name = "[R]", value = true})
  Menu.Combo:MenuElement({id = "HP", name = "Use [R] if Enemy HP lower then", value = 50, min = 0, max = 100, identifier = "%"})
  Menu.Combo:MenuElement({id = "ignite", name = "Ignite in Combo", value = true})
  Menu.Combo:MenuElement({id = "exaust", name = "Exhaust in Combo", value = true})
  Menu.Combo:MenuElement({id = "ignitehp", name = "Ignite HP:", value = 35, min = 5, max = 95, identifier = "%"})


  -- Harasss
  Menu:MenuElement({type = MENU, id = "Harass", name = "Harass"})
  Menu.Harass:MenuElement({id = "Grit", name = "Min Grit to Use [W]", value = 30, min = 0, max = 100, identifier = "%"})


  --LaneClear Menu
  Menu:MenuElement({type = MENU, id = "Clear", name = "LaneClear"})
  Menu.Clear:MenuElement({id = "UseQ", name = "[Q]", value = true})
  Menu.Clear:MenuElement({id = "UseE", name = "[E]", value = true})
  Menu.Clear:MenuElement({id = "UseW", name = "[W]", value = true})
  Menu.Clear:MenuElement({id = "Wmin", name = "[W] If Hit X Minion ", value = 2, min = 1, max = 6, step = 1, identifier = "Minion/s"})
  Menu.Clear:MenuElement({id = "Emin", name = "[E] If Hit X Minion ", value = 3, min = 1, max = 6, step = 1, identifier = "Minion/s"})
  Menu.Clear:MenuElement({id = "Grit", name = "Min Grit to Use [W]", value = 2, min = 0, max = 100, identifier = "%"})

  --JungleClear
  Menu:MenuElement({type = MENU, id = "JClear", name = "JungleClear"})
  Menu.JClear:MenuElement({id = "UseQ", name = "[Q]", value = true})
  Menu.JClear:MenuElement({id = "UseW", name = "[W]", value = true})
  Menu.JClear:MenuElement({id = "Grit", name = "Min Grit to Use [W]", value = 3, min = 0, max = 100, identifier = "%"})

  --Prediction
  Menu:MenuElement({type = MENU, id = "Pred", name = "Prediction"})
  Menu.Pred:MenuElement({id = "PredW", name = "Hitchance [W]", value = 1, drop = {"Normal", "High", "Immobile"}})

  --Drawing
  Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawings"})
  Menu.Drawing:MenuElement({id = "DrawW", name = "Draw [W]", value = false})
  Menu.Drawing:MenuElement({id = "DrawE", name = "Draw [E]", value = false})
  Menu.Drawing:MenuElement({id = "DrawR", name = "Draw [R]", value = false})

end


function Sett:Tick()
  if myHero.dead or Game.IsChatOpen() or (ExtLibEvade and ExtLibEvade.Evading == true) then
    return
  end



  if Orb.Modes[ORBWALKER_MODE_COMBO] then
    self:Combo()
    self:castIginite()
    self:castExaust()
  elseif Orb.Modes[ORBWALKER_MODE_HARASS] then
    self:Harass()
  elseif Orb.Modes[ORBWALKER_MODE_LANECLEAR] then
    self:Clear()
    self:JungleClear()
  elseif Orb.Modes[ORBWALKER_MODE_FLEE] then
    self:castExaust()
  end

end

function Sett:Combo()
  print("0")
  local target = self:GetTarget(800)
    print(target)
  if target == nil then return end
  print("1")
  if IsValid(target) then
 print("2")
    if myHero.pos:DistanceTo(target.pos) < 400 and Menu.Combo.UseR:Value() and Ready(_R)  then
      if target.health/target.maxHealth <= Menu.Combo.HP:Value() / 100 then
        Control.CastSpell(HK_R, target)
      end
    end

    if myHero.pos:DistanceTo(target.pos) < 490 and Menu.Combo.UseE:Value() and Ready(_E) then
      Control.CastSpell(HK_E, target.pos)
    end

    if myHero.pos:DistanceTo(target.pos) < 800 and Menu.Combo.UseQ:Value() and Ready(_Q) then
      Control.CastSpell(HK_Q)
    end

    if myHero.pos:DistanceTo(target.pos) < 750 and Menu.Combo.UseW:Value() and Ready(_W) and myHero.mana/myHero.maxMana >= Menu.Combo.Grit:Value() / 100 then

      local pred = GetGamsteronPrediction(target, self.E, myHero)
      if pred.Hitchance >= Menu.Pred.PredW:Value()+1 then
        Control.CastSpell(HK_W, pred.CastPosition)
      end

    end
  end

end

function Sett:Harass()

  local target = self:GetTarget(750)
  if target == nil then return end
  if IsValid(target) then

    if myHero.pos:DistanceTo(target.pos) < 750 and Menu.Combo.UseW:Value() and Ready(_W)
      and myHero.mana/myHero.maxMana >= Menu.Harras.Grit:Value() / 100 then

      local pred = GetGamsteronPrediction(target, self.E, myHero)
      if pred.Hitchance >= Menu.Pred.PredW:Value()+1 then
        Control.CastSpell(HK_W, pred.CastPosition)
      end

    end

  end
end

function Sett:Clear()
  for i = 1, GameMinionCount() do
    local minion = GameMinion(i)
    if myHero.pos:DistanceTo(minion.pos) <= 800 and minion.team == TEAM_ENEMY and IsValid(minion) then


      if myHero.pos:DistanceTo(minion.pos) <= 490 and Menu.Clear.UseW:Value() and Ready(_E) then
        local count = GetMinionCount(160, minion)
        if count >= Menu.Clear.Emin:Value() then
          Control.CastSpell(HK_E, minion.pos)
        end
      end

      if myHero.pos:DistanceTo(minion.pos) <= 400 and Menu.Clear.UseQ:Value() and Ready(_Q) then
        Control.CastSpell(HK_Q)
      end


      if myHero.pos:DistanceTo(minion.pos) <= 750 and Menu.Clear.UseW:Value() and Ready(_W) then
        local count = GetMinionCount(490, minion)
        if count >= Menu.Clear.Wmin:Value() and myHero.mana/myHero.maxMana >= Menu.Clear.Grit:Value() / 100 then
          Control.CastSpell(HK_W, minion.pos)
        end
      end

    end
  end
end


function Sett:JungleClear()
  for i = 1, GameMinionCount() do
    local minion = GameMinion(i)
    if myHero.pos:DistanceTo(minion.pos) <= 800 and minion.team == TEAM_JUNGLE and IsValid(minion) then

      if myHero.pos:DistanceTo(minion.pos) <= 400 and Menu.JClear.UseQ:Value() and Ready(_Q) then
        Control.CastSpell(HK_Q)
      end

      if myHero.pos:DistanceTo(minion.pos) <= 750 and Menu.JClear.UseW:Value() and Ready(_W) and myHero.mana/myHero.maxMana >= Menu.JClear.Grit:Value() / 100 then
        Control.CastSpell(HK_W, minion.pos)
      end
    end
  end
end


function GetMinionCount(range, pos)
  local pos = pos.pos
  local count = 0
  for i = 1,Game.MinionCount() do
    local hero = Game.Minion(i)
    local Range = range * range
    if hero.team ~= TEAM_ALLY and hero.dead == false and GetDistanceSquared(pos, hero.pos) < Range then
      count = count + 1
    end
  end
  return count
end



function Sett:castIginite()
  if Menu.Combo.ignite:Value() == false then return end
  for i = 1, #Enemys do
    local target = Enemys[i]
    if IsValid(target)  and myHero.pos:DistanceTo(target.pos) <= 580 then
      local TargetHp = target.health/target.maxHealth

      if TargetHp <= Menu.Combo.ignitehp:Value()/100 then
        if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1) then
          Control.CastSpell(HK_SUMMONER_1, target)
        elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2) then
          Control.CastSpell(HK_SUMMONER_2, target)

        end

      end
    end
  end

end

-- ok
function Sett:castExaust()
  if Menu.Combo.exaust:Value() == false then return end
  for i = 1, #Enemys do
    local target = Enemys[i]
    if IsValid(target)  and myHero.pos:DistanceTo(target.pos) <= 600 then
      if myHero:GetSpellData(SUMMONER_1).name == "SummonerExhaust" and Ready(SUMMONER_1) then
        Control.CastSpell(HK_SUMMONER_1, target)
      elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerExhaust" and Ready(SUMMONER_2) then
        Control.CastSpell(HK_SUMMONER_2, target)
      end
    end
  end
end


function Sett:GetTarget(range, list)
  local targetList = {}
  local inputList = list or Enemys
  for i = 1, #inputList do
    local hero = inputList[i]
    if GetDistanceSquared(hero.pos, myHero.pos) < range * range and IsValid(hero) then
      targetList[#targetList + 1] = hero
    end
  end

  return TargetSelector:GetTarget(targetList)
end

function Sett:GetTargetInRange(range, target)
  local counter = 0
  for i = 1, #Enemys do
    local hero = Enemys[i]
    if IsValid(hero) then
      if GetDistanceSquared(target.pos, hero.pos) < range * range then
        counter = counter + 1
      end
    end
  end
  return counter
end




function Sett:Draw()
  if myHero.dead then return  end
  if Menu.Drawing.DrawW:Value() and Ready(_W) then
    DrawCircle(myHero, 750, 1, DrawColor(225, 225, 0, 10))
  end
  if Menu.Drawing.DrawE:Value() and Ready(_E) then
    DrawCircle(myHero, 490, 1, DrawColor(225, 225, 0, 10))
  end
  if Menu.Drawing.DrawR:Value() and Ready(_R) then
    DrawCircle(myHero, 400, 1, DrawColor(225, 225, 0, 10))
  end
end




Sett()
