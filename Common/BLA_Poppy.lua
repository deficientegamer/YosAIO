require("BLA_Common") -- load common functions
require('GamsteronPrediction')
require('PussyDamageLib')
require("MapPositionGoS")

local LocalTableSort        = table.sort
local LocalStringFind       = string.find
local inUlt = false

class "Poppy"

function Poppy:__init()

  self.Q = {Type = _G.SPELLTYPE_LINE, width=40, range = 430}
  self.W = {Type = _G.SPELLTYPE_CIRCLE, range = 430, radius=400}
  self.E = {Type = _G.SPELLTYPE_LINE, range = 775, Collision = true, MaxCollision = 0, CollisionTypes = {_G.COLLISION_MINION, _G.COLLISION_ENEMYHERO, _G.COLLISION_YASUOWALL}}
  self.R = {Type = _G.SPELLTYPE_LINE, range = 1900, width=180}

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
      if lastMove + 120 > GetTickCount() then
        args.Process = false
      else
        args.Process = true
        lastMove = GetTickCount()
      end
    end
  )
end

function Poppy:LoadMenu()

  self.Menu = MenuElement({type = MENU, id = "BLAPoppy", name = "BotLaneAIO Poppy RC 0.1"})

  self.Menu:MenuElement({type = MENU, id = "combo", name = "Combo"})
  self.Menu.combo:MenuElement({id = "Q", name = "Q", value = true})
  self.Menu.combo:MenuElement({id = "maxQ", name = "E max distance in Combo", value = 270, min = 0, max = 430, step = 1})

  self.Menu.combo:MenuElement({id = "W", name = "W", value = false})

  self.Menu.combo:MenuElement({id = "E", name = "E", value = true})
  self.Menu.combo:MenuElement({id = "maxE", name = "E max distance in Combo", value = 700, min = 0, max = 775, step = 1})

  self.Menu.combo:MenuElement({id = "R", name = "R (Only Near)", value = true})
  self.Menu.combo:MenuElement({id = "RVeryNear", name = "RW - whenever very and < health", value = true})
  self.Menu.combo:MenuElement({id = "RHighKSChange", name = "R - whenever very and high KS chance", value = true})

  self.Menu.combo:MenuElement({type = MENU, id = "comboUltConfig", name = "Custom Ult"})
  self.Menu.combo.comboUltConfig:MenuElement({id = "veryNear", name = "Very Near Consider", value = 50, min = 0, max = 120, step = 1})
  self.Menu.combo.comboUltConfig:MenuElement({id = "highDamageDivisor", name = "Very High KS Divisor Consider", value = 10, min = 5, max = 30, step = 1})
  self.Menu.combo.comboUltConfig:MenuElement({id = "enemysDistance", name = "Enemy's Distance Consider", value = 90, min = 0, max = 200, step = 1})
  self.Menu.combo.comboUltConfig:MenuElement({id = "maxDistance", name = "Max Distance", value = 220, min = 0, max = 310, step = 1})


  self.Menu:MenuElement({type = MENU, id = "harass", name = "Harass"})
  self.Menu.harass:MenuElement({id = "Q", name = "Q", value = true})
  self.Menu.harass:MenuElement({id = "E", name = "E", value = true})

  self.Menu:MenuElement({type = MENU, id = "clear", name = "Clear"})
  self.Menu.clear:MenuElement({id = "Q", name = "Q", value = true})
  self.Menu.clear:MenuElement({id = "E", name = "E", value = true})

  self.Menu:MenuElement({type = MENU, id = "lastHit", name = "LastHit"})
  self.Menu.lastHit:MenuElement({id = "Q", name = "Q", value = true})
  self.Menu.lastHit:MenuElement({id = "E", name = "E", value = true})

  self.Menu:MenuElement({type = MENU, id = "auto", name = "Auto (insecure)"})
  self.Menu.auto:MenuElement({id = "W", name = "W", value = true})

  self.Menu:MenuElement({type = MENU, id = "escape", name = "Escape"})
  self.Menu.escape:MenuElement({id = "W", name = "W", value = true})

  self.Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawing"})
  self.Menu.Drawing:MenuElement({id = "Q", name = "Draw [Q] Range", value = true})
  self.Menu.Drawing:MenuElement({id = "W", name = "Draw [W] Range", value = true})
  self.Menu.Drawing:MenuElement({id = "E", name = "Draw [E] Range", value = true})
  self.Menu.Drawing:MenuElement({id = "R", name = "Draw [R] Range", value = true})

end


function Poppy:Tick()
  if myHero.dead or Game.IsChatOpen() or (ExtLibEvade and ExtLibEvade.Evading == true) then
    return
  end

  self:Auto()

  if Orb.Modes[ORBWALKER_MODE_COMBO] then
    self:Combo()
  elseif Orb.Modes[ORBWALKER_MODE_HARASS] then
    self:Harass()
  elseif Orb.Modes[ORBWALKER_MODE_LANECLEAR] then
    self:Clear()
  elseif Orb.Modes[ORBWALKER_MODE_LASTHIT] then
    self:LastHit()
  elseif Orb.Modes[ORBWALKER_MODE_FLEE] then
    -- W Start
    if self.Menu.combo.W:Value()  and lastW +240 and Ready(_W) then
      Control.CastSpell(HK_W)
      lastW = GetTickCount()
    end
    -- W End
  end

end

function Poppy:Combo()

  local target = nil


  -- E Start
  target = self:GetTarget(775)
  if self.Menu.combo.E:Value()  and lastE +140  < GetTickCount() and Ready(_E) and IsValid(target) then

    local distanceSqr = GetDistanceSquared(myHero.pos, target.pos)
    local Pred = GetGamsteronPrediction(target, self.E, myHero)
    if Pred.Hitchance >= _G.HITCHANCE_HIGH and distanceSqr < self.Menu.combo.maxE:Value() ^2 then


      local finalPos = target.pos:Extended(myHero.pos, -425)

      -- Logica para mandar para parede
      if MapPosition:inWall(finalPos) then
        Control.CastSpell(HK_E,Pred.CastPosition)
        lastE = GetTickCount()
      end

      -- logica pra mandar pra torre
      if IsSendUnderTurretAlly(myHero,finalPos) then
        Control.CastSpell(HK_E,Pred.CastPosition)
        lastE = GetTickCount()
      end


    end
  end
  -- E End


  -- Q Start
  target = self:GetTarget(430)
  if IsValid(target) and Ready(_Q) and lastQ + 120 < GetTickCount() then
    local distanceSqr = GetDistanceSquared(myHero.pos, target.pos)
    if self.Menu.combo.Q:Value()
      and distanceSqr < self.Menu.combo.maxQ:Value() ^2    then
      local Pred = GetGamsteronPrediction(target, self.Q, myHero)
      if Pred.Hitchance >= _G.HITCHANCE_HIGH then
        Control.CastSpell(HK_Q, Pred.CastPosition)
        lastQ = GetTickCount()
        return
      end
    end
  end
  -- Q End

  -- R Start
  if lastR + self.Menu.combo.comboUltConfig.maxDistance:Value() < GetTickCount() and Ready(_R) then
    for i = 1, #Enemys do

      local hero = Enemys[i]
      local distanceSqr = GetDistanceSquared(myHero.pos, hero.pos)

      -- very near
      if  distanceSqr < self.Menu.combo.comboUltConfig.veryNear:Value() ^2
        and IsValid(hero) and myHero.health+200 < hero.health then
        local Pred = GetGamsteronPrediction(hero, self.R, myHero)
        if  Pred.Hitchance >= _G.HITCHANCE_HIGH and Ready(_W)  then
          Control.CastSpell(HK_R, Pred.CastPosition)
          lastR = GetTickCount()
          Control.CastSpell(HK_W)
          lastW = GetTickCount()
        end
      end

      -- ks near
      local maxDistance = self:GetTargetInRange(self.Menu.combo.comboUltConfig.maxDistance:Value(), myHero)
      print("0")
      if  distanceSqr < (maxDistance ^2) then
        print("1")
        local RDmg = getdmg("R", hero, myHero, 1)
        if self.Menu.combo.R:Value() and IsValid(hero) then
          print("2")
          local Pred = GetGamsteronPrediction(hero, self.R, myHero)
          -- solta r quando tem muito inimigo, ou inimigo esta imovel e chance de matar ou muita quando tem chance de matar
          if self.Menu.combo.RHighKSChange:Value()
            and Pred.Hitchance >= _G.HITCHANCE_HIGH or RDmg/(self.Menu.combo.comboUltConfig.highDamageDivisor:Value()/10) > hero.health then
            print("3")
            Control.KeyDown(HK_R)
            DelayAction(
              function()
                Control.KeyUp(HK_R)
                Control.CastSpell(HK_R, Pred.CastPosition)
                lastR = GetTickCount()
              end, 4
            )

            return
          end
        end
      end

    end
  end

  -- R End

  -- W Start
  if self.Menu.combo.W:Value()  and lastW +240  < GetTickCount() and Ready(_W) then
    Control.CastSpell(HK_W)
    lastW = GetTickCount()
  end
  -- W End

end

function Poppy:Auto()
  -- W Start
  if self.Menu.auto.W:Value()  and lastW +240  < GetTickCount() and Ready(_W)
    and self:HeroesAround(1600,myHero.pos,TEAM_ENEMY)>2  then
    Control.CastSpell(HK_W)
    lastW = GetTickCount()
  end
  -- W End

end

function Poppy:Harass()


  local target = nil


  -- E Start
  target = self:GetTarget(775)
  if self.Menu.harass.E:Value()  and lastE +140  < GetTickCount() and Ready(_E) and IsValid(target) then

    local distanceSqr = GetDistanceSquared(myHero.pos, target.pos)
    local Pred = GetGamsteronPrediction(target, self.E, myHero)
    if Pred.Hitchance >= _G.HITCHANCE_HIGH and distanceSqr < self.Menu.combo.maxE:Value() ^2 then


      local finalPos = target.pos:Extended(myHero.pos, -425)

      -- Logica para mandar para parede
      if MapPosition:inWall(finalPos) then
        Control.CastSpell(HK_E,Pred.CastPosition)
        lastE = GetTickCount()
      end

      -- logica pra mandar pra torre
      if IsSendUnderTurretAlly(myHero,finalPos) then
        Control.CastSpell(HK_E,Pred.CastPosition)
        lastE = GetTickCount()
      end


    end
  end
  -- E End


  -- Q Start
  target = self:GetTarget(430)
  if IsValid(target) and Ready(_Q) and lastQ + 120 < GetTickCount() then
    local distanceSqr = GetDistanceSquared(myHero.pos, target.pos)
    if self.Menu.harass.Q:Value()
      and distanceSqr < self.Menu.combo.maxQ:Value() ^2    then
      local Pred = GetGamsteronPrediction(target, self.Q, myHero)
      if Pred.Hitchance >= _G.HITCHANCE_HIGH then
        Control.CastSpell(HK_Q, Pred.CastPosition)
        lastQ = GetTickCount()
        return
      end
    end
  end
  -- Q End
end

function Poppy:Clear()


  local eMinions = SDK.ObjectManager:GetEnemyMinions(650)
  for i = 1, #eMinions do
    local target = eMinions[i]

    -- E Start
    if self.Menu.clear.E:Value()  and lastE +140  < GetTickCount() and Ready(_E) and IsValid(target) then
      Control.CastSpell(HK_E,target)
      lastE = GetTickCount()
    end
    -- E End

    -- Q Start
    if IsValid(target) and Ready(_Q) and lastQ + 120 < GetTickCount()
      and  myHero.pos:DistanceTo(target.pos) < 200 then
      Control.CastSpell(HK_Q, target)
      lastQ = GetTickCount()
      return
    end

    -- Q End
  end


end


function Poppy:LastHit()


  local eMinions = SDK.ObjectManager:GetEnemyMinions(650)
  for i = 1, #eMinions do
    local target = eMinions[i]

    -- E Start
    local WDmg = getdmg("E", target, myHero, 1)
    if self.Menu.clear.E:Value()  and lastE +140  < GetTickCount() and Ready(_E) and IsValid(target)
      and (WDmg > target.health)
    then
      Control.CastSpell(HK_E,target)
      lastE = GetTickCount()
    end
    -- E End

    -- Q Start
    local WDmg = getdmg("Q", target, myHero, 1)
    if IsValid(target) and Ready(_Q) and lastQ + 120 < GetTickCount()
      and  myHero.pos:DistanceTo(target.pos) < 200
      and (WDmg > target.health) then
      Control.CastSpell(HK_Q, target)
      lastQ = GetTickCount()
      return
    end

    -- Q End
  end

end


function Poppy:Draw()
  if myHero.dead then return  end
  if self.Menu.Drawing.R:Value() and Ready(_R) then
    Draw.Circle(myHero, 1900, 1, Draw.Color(255, 225, 255, 10))
  end
  if self.Menu.Drawing.Q:Value() and Ready(_Q) then
    Draw.Circle(myHero, 430, 1, Draw.Color(225, 225, 0, 10))
  end
  if self.Menu.Drawing.W:Value() and Ready(_W) then
    Draw.Circle(myHero, 400, 1, Draw.Color(225, 225, 0, 10))
  end
  if self.Menu.Drawing.E:Value() and Ready(_E) then
    Draw.Circle(myHero, 775, 1, Draw.Color(225, 225, 125, 10))
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

function Poppy:GetTarget(range, list)
  local targetList = {}
  local inputList = list or Enemys

  for i = 1, #Enemys do
    local hero = Enemys[i]
    if GetDistanceSquared(hero.pos, myHero.pos) < range * range and IsValid(hero) then
      targetList[#targetList + 1] = hero
    end
  end

  return TargetSelector:GetTarget(targetList)
end

function Poppy:GetTargetInRange(range, target)
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


function Poppy:GetHeroInRange(range, target)

  for i = 1, #Enemys do
    local hero = Enemys[i]
    if IsValid(hero) then
      if GetDistanceSquared(target.pos, hero.pos) < range * range then
        return hero
      end
    end
  end
end


function Poppy:HeroesAround(range, pos, team)
  pos = pos or myHero.pos
  team = team or foe
  Count = 0
  for i = 1, Game.HeroCount() do
    hero = Game.Hero(i)
    if hero and hero.team == team and not hero.dead and GetDistanceSquared(pos, hero.pos) < range then
      Count = Count + 1
    end
  end
  return Count
end



Poppy()
