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

  self.Menu = MenuElement({type = MENU, id = "BLAPoppy", name = "SoldierAIO Poppy RC 0.2"})

  self.Menu:MenuElement({type = MENU, id = "combo", name = "Combo"})
  self.Menu.combo:MenuElement({id = "Q", name = "Q", value = true})
  self.Menu.combo:MenuElement({id = "maxQ", name = "q max distance in Combo", value = 140, min = 0, max = 340, step = 1})

  self.Menu.combo:MenuElement({id = "W", name = "W", value = false})

  self.Menu.combo:MenuElement({id = "E", name = "E", value = true})
  self.Menu.combo:MenuElement({id = "EProtect", name = "E to protect ally", value = true})
  self.Menu.combo:MenuElement({id = "maxE", name = "E max distance in Combo", value = 735, min = 0, max = 775, step = 1})


  self.Menu.combo:MenuElement({id = "R", name = "R", value = true})
  self.Menu.combo:MenuElement({id = "RVeryNear", name = "RW - whenever very and < health", value = true})
  self.Menu.combo:MenuElement({id = "RManyEnemies", name = "R - whenever many enemies", value = true})
  self.Menu.combo:MenuElement({id = "RAfterE", name = "R - whenever after E in wall", value = true})

  self.Menu.combo:MenuElement({type = MENU, id = "comboUltConfig", name = "Custom Ult"})
  self.Menu.combo.comboUltConfig:MenuElement({id = "veryNear", name = "Very Near Consider", value = 50, min = 0, max = 120, step = 1})
  self.Menu.combo.comboUltConfig:MenuElement({id = "manyEnemies", name = "Many Enemies For Clear", value = 3, min = 1, max = 5, step = 1})
  self.Menu.combo.comboUltConfig:MenuElement({id = "distancieCountEnemies", name = "Distance Enemies For Count", value = 440, min = 50, max = 1000, step = 1})
  self.Menu.combo.comboUltConfig:MenuElement({id = "maxDistance", name = "Max Distance", value = 220, min = 0, max = 1000, step = 1})


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

  self.Menu:MenuElement({type = MENU, id = "escape", name = "Escape (use Orb Key)"})
  self.Menu.escape:MenuElement({id = "W", name = "W if my health <", value = true})
  self.Menu.escape:MenuElement({id = "E", name = "E if my health > and ally low", value = true})

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
    target = self:GetTarget(800)
    if self.Menu.escape.W:Value()  and lastW +240 and Ready(_W)
      and IsValid(target) and target.health > myHero.health then
      Control.CastSpell(HK_W)
      lastW = GetTickCount()
    end
    -- W End

    -- E Start
    -- afastar inimigo de aliado morrendo
    target = self:GetTarget(740)
    numLwHealthAlly = HeroesAroundLowHealthCompMe(380,myHero.pos,TEAM_ENEMY)
    print(numLwHealthAlly)
    if self.Menu.escape.E:Value()  and lastE +140 and Ready(_E)
      and IsValid(target)
      and (target.health*1.30) < myHero.health
      and numLwHealthAlly>0 then
      Control.CastSpell(HK_E)
      lastE = GetTickCount()
    end

  end

end

function Poppy:Combo()

  local target = nil


  -- E Start
  target = self:GetTarget(self.Menu.combo.maxE:Value())
  
  if self.Menu.combo.E:Value()  and lastE +140  < GetTickCount() and Ready(_E) and IsValid(target) then

    local distanceSqr = GetDistanceSquared(myHero.pos, target.pos)
    local Pred = GetGamsteronPrediction(target, self.E, myHero)
    if Pred.Hitchance >= _G.HITCHANCE_NORMAL  then


      local finalPos = target.pos:Extended(myHero.pos, -425)

      -- Logica para mandar para torre aliada
      if IsSendUnderTurretAlly(myHero,finalPos) then
        -- logica pra mandar pra torre
        Control.CastSpell(HK_E,Pred.CastPosition)
        lastE = GetTickCount()
        -- Logica para mandar ele pra parede
      else if MapPosition:inWall(finalPos) then

          Control.CastSpell(HK_E,Pred.CastPosition)
          lastE = GetTickCount()
          
          -- se t· na parede e perto dou tb o R
          local targetNear = self:GetTarget(self.Menu.combo.comboUltConfig.veryNear:Value())
          if tagertNear == target and IsValid(targetNear)  then
            local Pred = GetGamsteronPrediction(targetNear, self.R, myHero)
            if  Pred.Hitchance >= _G.HITCHANCE_HIGH and Ready(_R)  then
              Control.CastSpell(HK_R, Pred.CastPosition)
              lastR = GetTickCount()
            end
          end
          
      else
        local numAround = self:GetTargetInRange(500, target)
        -- SE MEU LIFE … MAIOR QUE o dele e n„o tem ninguÈm perto, dou E
        if myHero.health > target.health and numAround == 0 then
          Control.CastSpell(HK_E,Pred.CastPosition)
          lastE = GetTickCount()
        end

        -- Se eu n√£o conseguir nada, tento mandar pra tras
        for i = 1, Game.TurretCount() do
          local turret = Game.Turret(i)
          if turret.isAlly and not turret.dead then
            if turret.pos:DistanceTo(target.pos) < turret.pos:DistanceTo(myHero.pos) then
              local Pred = GetGamsteronPrediction(target, self.E, myHero)
              if  Pred.Hitchance >= _G.HITCHANCE_NORMAL and Ready(_E)  then
                Control.CastSpell(HK_E,Pred.CastPosition)
                lastE = GetTickCount()
              end
              
            end
          end
        end
      end

      end

      -- afastar inimigo de aliado morrendo
      if self.Menu.combo.EProtect:Value() then
        target = self:GetTarget(740)
        numLwHealthAlly = HeroesAroundLowHealthCompMe(380,myHero.pos,TEAM_ALLY)
        if self.Menu.escape.E:Value()  and lastE +140 and Ready(_E)
          and IsValid(target) and target.health < myHero.health
          and numLwHealthAlly>0 then
          Control.CastSpell(HK_E)
          lastE = GetTickCount()
        end
      end


    end
  end
  -- E End


  -- Q Start
  target = self:GetTarget(self.Menu.combo.maxQ:Value())
  if IsValid(target) and Ready(_Q) and lastQ + 120 < GetTickCount() then
    if self.Menu.combo.Q:Value()  then
      local Pred = GetGamsteronPrediction(target, self.Q, myHero)
      if Pred.Hitchance >= _G.HITCHANCE_NORMAL then
        Control.CastSpell(HK_Q, Pred.CastPosition)
        lastQ = GetTickCount()
        return
      end
    end
  end
  -- Q End

  -- R Start
  target = self:GetTarget(self.Menu.combo.comboUltConfig.maxDistance:Value())

  if IsValid(target) and Ready(_R)  and self.Menu.combo.R:Value()  then

    for i = 1, #Enemys do
      -- very near
      local targetNear = self:GetTarget(self.Menu.combo.comboUltConfig.veryNear:Value())
      if  IsValid(targetNear)  then
        local Pred = GetGamsteronPrediction(targetNear, self.R, myHero)
        if  Pred.Hitchance >= _G.HITCHANCE_HIGH and Ready(_R)  then

          Control.CastSpell(HK_R, Pred.CastPosition)
          lastR = GetTickCount()
          Control.CastSpell(HK_W)
          lastW = GetTickCount()
        end
      end

      -- jogar para longe muitos inimigos

      local numAround = self:GetTargetInRange(self.Menu.combo.comboUltConfig.distancieCountEnemies:Value(), target)
      local RDmg = getdmg("R", target, myHero, 1)

      local Pred = GetGamsteronPrediction(target, self.R, myHero)
      -- solta r quando tem muito inimigo, ou inimigo esta imovel e chance de matar ou muita quando tem chance de matar
      if self.Menu.combo.RManyEnemies:Value()
        and Pred.Hitchance >= _G.HITCHANCE_HIGH
        and numAround >= self.Menu.combo.comboUltConfig.manyEnemies:Value()
        and lastR + 90 < GetTickCount()  then
        Control.KeyDown(HK_R)
        DelayAction(
          function()
            Control.KeyUp(HK_R)
            local Pred = GetGamsteronPrediction(target, self.R, myHero)
            if Pred.Hitchance >= _G.HITCHANCE_HIGH then
              Control.CastSpell(HK_R, Pred.CastPosition)
            end
            lastR = GetTickCount()
          end, 3
        )

        return
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
