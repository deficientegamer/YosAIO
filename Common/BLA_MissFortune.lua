require("BLA_Common") -- load common functions
require('GamsteronPrediction')
require('PussyDamageLib')
require('Alpha')

local LocalTableSort        = table.sort
local LocalStringFind       = string.find
LocalGeometry = _G.Alpha.Geometry

local inUlt = false
local initUltHealth = 0

class "MissFortune"

function MissFortune:__init()

  self.Q = {Type = _G.SPELLTYPE_CONE, range = 650, radius = 440, delay = 0.25,  speed = 1800, Collision = true, MaxCollision = 1, CollisionTypes = {_G.COLLISION_MINION, _G.COLLISION_ENEMYHERO, _G.COLLISION_YASUOWALL}}
  self.E = {Type = _G.SPELLTYPE_CIRCLE, range = 1000, delay = 0.5, speed = 2200, Radius = 400 }
  self.R = {Type = _G.SPELLTYPE_CONE, range = 1400}

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

function MissFortune:LoadMenu()

  self.Menu = MenuElement({type = MENU, id = "BLAMissFortune", name = "YosAIO (Soldier AIO) MissFortune RC 0.3"})

  self.Menu:MenuElement({type = MENU, id = "combo", name = "Combo"})
  self.Menu.combo:MenuElement({id = "Q", name = "Q", value = true})
  self.Menu.combo:MenuElement({id = "maxQ", name = "Q max distance in Combo", value = 650, min = 0, max = 650, step = 1})
  self.Menu.combo:MenuElement({id = "W", name = "W", value = true})
  self.Menu.combo:MenuElement({id = "E", name = "E", value = true})
  self.Menu.combo:MenuElement({id = "R", name = "R", value = true})
  self.Menu.combo:MenuElement({id = "minComboR", name = "R - whenever X(+) enemy's", value = 2, min = 1, max = 5, step = 1})
  self.Menu.combo:MenuElement({id = "RHighDamgeChange", name = "R - whenever high dmg", value = false})
  self.Menu.combo:MenuElement({id = "RImmobileHighDamgeChange", name = "R - whenever immobile high dmg", value = true})
  self.Menu.combo:MenuElement({id = "RHighKSChange", name = "R - whenever very high KS chance", value = true})
  self.Menu.combo:MenuElement({type = MENU, id = "comboUltConfig", name = "Custom Ult"})
  self.Menu.combo.comboUltConfig:MenuElement({id = "highDamageDivisor", name = "High Damage Divisor Consider", value = 15, min = 5, max = 30, step = 1})
  self.Menu.combo.comboUltConfig:MenuElement({id = "highDamageDivisor", name = "Very High Damage Divisor Consider", value = 20, min = 5, max = 30, step = 1})
  self.Menu.combo.comboUltConfig:MenuElement({id = "enemysDistance", name = "Enemy's Distance Consider", value = 480, min = 100, max = 1400, step = 1})
  self.Menu.combo.comboUltConfig:MenuElement({id = "maxDistance", name = "Max Distance", value = 900, min = 100, max = 1400, step = 1})



  self.Menu:MenuElement({type = MENU, id = "harass", name = "Harass"})
  self.Menu.harass:MenuElement({id = "Qminion", name = "Q in minion with enemy near", value = true})
  self.Menu.harass:MenuElement({id = "Qenemy", name = "Q in enemy with enemy near", value = true})
  self.Menu.harass:MenuElement({id = "E", name = "E in enemy", value = true})

  self.Menu:MenuElement({type = MENU, id = "clear", name = "Clear"})
  self.Menu.clear:MenuElement({id = "Q", name = "Q", value = true})
  self.Menu.clear:MenuElement({id = "E", name = "E", value = false})

  self.Menu:MenuElement({type = MENU, id = "auto", name = "Auto"})
  self.Menu.auto:MenuElement({id = "bounce", name = "Q Logic Bounce by Sikaka", value = true})

  self.Menu:MenuElement({type = MENU, id = "lastHit", name = "LastHit"})
  self.Menu.lastHit:MenuElement({id = "Q", name = "Q", value = true})
  self.Menu.lastHit:MenuElement({id = "E", name = "E", value = true})

  self.Menu:MenuElement({type = MENU, id = "escape", name = "Escape"})
  self.Menu.escape:MenuElement({id = "W", name = "W", value = true})

  self.Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawing"})
  self.Menu.Drawing:MenuElement({id = "Q", name = "Draw [Q] Range", value = true})
  self.Menu.Drawing:MenuElement({id = "E", name = "Draw [E] Range", value = true})
  self.Menu.Drawing:MenuElement({id = "R", name = "Draw [R] Range", value = true})

end


function MissFortune:Tick()
  if myHero.dead or Game.IsChatOpen() or (ExtLibEvade and ExtLibEvade.Evading == true) then
    return
  end

  if inUlt == true and initUltHealth >= myHero.health then
    return false
  end

  if self.Menu.auto.bounce:Value()  and lastQ +70 and Ready(_Q) then

    self:Bounce()
  end

  --self:Auto()

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
    if self.Menu.combo.W:Value()  and lastW +120 and Ready(_W) then
      Control.CastSpell(HK_W)
    end
    -- W End
  end

end


-- Bounce logic ALMOST ALL Credits for Sikaka
function MissFortune:Bounce()
  --All the traditional Q logic
  if Ready(_Q) then
    local target =  self:GetTarget(self.Q.range)
    if target and IsValid(target) then
      local bounceTarget = GetQBounceTarget(target)
      if IsValid(bounceTarget) and LocalStringFind(bounceTarget.type, "Hero") then
        --Check for killsteal
        local WDmg = getdmg("Q", bounceTarget, myHero, 1)
        if WDmg >= bounceTarget.health then
          local Pred = GetGamsteronPrediction(target, self.Q, myHero)
          if Pred.Hitchance >= _G.HITCHANCE_NORMAL then
            Control.CastSpell(HK_Q, target.pos)
            lastQ = GetTickCount()
            return
          end
        end
        -- bounce with enemy
        if lastQ +170 < GetTickCount() and Ready(_Q)  then
          for i = 1, #Enemys do
            local hero1 = Enemys[i]
            if IsValid(hero1) then

              -- Check have enemy hero near
              local hero2 = self:GetHeroInRange(160, hero1)
              if hero2 ~= hero1 then
                local Pred = GetGamsteronPrediction(hero2, self.Q, myHero)
                if IsValid(hero2) and Pred.Hitchance >= _G.HITCHANCE_NORMAL then
                  Control.CastSpell(HK_Q, hero1.pos)
                  lastQ = GetTickCount()
                  return
                end
              end
            end
          end
        end
      end
    end

    --Minion bounce: only calculate if there are enemies we could bounce to
    if NearestEnemy(myHero.pos, 1000) ~= nil then
      local eMinions = SDK.ObjectManager:GetEnemyMinions(650)
      for i = 1,#eMinions do
        local minion = eMinions[i]

        if IsValid(minion) and LocalGeometry:IsInRange(myHero.pos, minion.pos, self.Q.range) then
          local minionHp = _G.SDK.HealthPrediction:GetPrediction(minion, self.Q.delay)
          if minionHp > 0 then
            local bounceTarget = GetQBounceTarget(minion)

            if IsValid(bounceTarget) and LocalStringFind(bounceTarget.type, "Hero") then
              Control.CastSpell(HK_Q, minion.pos)
              lastQ = GetTickCount()
              return
            end
          end
        end
      end
    end
  end

end


function MissFortune:Combo()


  local target = nil

  -- R Start
  if lastR + 1200 < GetTickCount() and Ready(_R) then
    for i = 1, #Enemys do

      local hero = Enemys[i]
      local distanceSqr = GetDistanceSquared(myHero.pos, hero.pos)

      if  distanceSqr < self.R.range ^2 then
        local maxDistance = self:GetTargetInRange(self.Menu.combo.comboUltConfig.maxDistance:Value(), myHero)
        local numAround = self:GetTargetInRange(self.Menu.combo.comboUltConfig.enemysDistance:Value(), hero)
        local RDmg = getdmg("R", hero, myHero, 1)

        if self.Menu.combo.R:Value() and maxDistance > 0 then

          local Pred = GetGamsteronPrediction(hero, self.R, myHero)
          -- solta r quando tem muito inimigo, ou inimigo esta imovel e chance de matar ou muita quando tem chance de matar
          if (numAround >= self.Menu.combo.minComboR:Value())
            or (self.Menu.combo.RHighDamgeChange:Value()
            and Pred.Hitchance >= _G.HITCHANCE_HIGH or RDmg/(self.Menu.combo.comboUltConfig.highDamageDivisor:Value()/10) > hero.health)
            or (self.Menu.combo.RImmobileHighDamgeChange:Value()
            and Pred.Hitchance >= _G.HITCHANCE_IMMOBILE or RDmg > hero.health)
            or (self.Menu.combo.RHighKSChange:Value()
            and Pred.Hitchance >= _G.HITCHANCE_HIGH or RDmg/(self.Menu.combo.comboUltConfig.highDamageDivisor:Value()/10) > hero.health) then


            Control.CastSpell(HK_R, Pred.CastPosition)
            lastR = GetTickCount()
            inUlt=true
            _G.SDK.Orbwalker:SetAttack(false)
            _G.SDK.Orbwalker:SetMovement(false) -- Stop moviment in R
            initUltHealth=myHero.health

            -- MOV AFTER 3 + 0.20
            DelayAction(
              function()
                _G.SDK.Orbwalker:SetMovement(true)
                _G.SDK.Orbwalker:SetAttack(true)
                inUlt=false
                
              end, 3.0
            )
            return

          end
        end
      end

    end
  end

  -- R End

  -- E Start

  target = self:GetTarget(690)


  if self.Menu.combo.E:Value()  and lastE +180  < GetTickCount() and Ready(_E) and IsValid(target) then
    local Pred = GetGamsteronPrediction(target, self.E, myHero)
    if Pred.Hitchance >= _G.HITCHANCE_HIGH then
      if target and self.Menu.combo.E:Value() then
        Control.CastSpell(HK_E,Pred.CastPosition)
        lastE = GetTickCount()
      end
    end
  end
  -- E End

  -- W Start
  target = self:GetTarget(1200)
  if self.Menu.combo.W:Value()  and lastW +120  < GetTickCount() and Ready(_W) and IsValid(target) then
    Control.CastSpell(HK_W)
    lastW = GetTickCount()
  end
  -- W End

  -- Q Start
  target = self:GetTarget(690)


  if IsValid(target) and Ready(_Q) and lastQ + 170 < GetTickCount() then
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
end



function MissFortune:Harass()
  if inUlt == true then return false end

  self:Bounce()

  if self.Menu.harass.E:Value()  and lastE +180  < GetTickCount() and Ready(_E)  then
    for i = 1, #Enemys do
      local hero = Enemys[i]
      local Pred = GetGamsteronPrediction(hero, self.E, myHero)
      if Pred.Hitchance >= _G.HITCHANCE_HIGH then
        if target and self.Menu.harass.E:Value() and IsValid(hero) then
          Control.CastSpell(HK_E,Pred.CastPosition)
          lastE = GetTickCount()
        end
      end
    end
  end


end

function MissFortune:Clear()
  if inUlt == true then return false end
  -- Atack enemys minions

  local eMinions = SDK.ObjectManager:GetEnemyMinions(650)
  for i = 1, #eMinions do
    local minion = eMinions[i]

    if IsValid(minion)
      and myHero.pos:DistanceTo(minion.pos) < 650 then

      if self.Menu.clear.Q:Value()
        and  lastQ +70 < GetTickCount()
        and Ready(_Q) then
        Control.CastSpell(HK_Q, minion)
        lastQ = GetTickCount()
      end

      local count = GetMinionCount(310, minion)
      if self.Menu.clear.E:Value()
        and lastE +180  < GetTickCount()
        and Ready(_E) and count>1 then
        Control.CastSpell(HK_E, minion)
        lastE = GetTickCount()
      end

    end
  end
end


function MissFortune:LastHit()

  if self.Menu.lastHit.Q:Value() then
    -- Cast Q
    local eMinions = SDK.ObjectManager:GetEnemyMinions(self.Q.range)
    for i = 1, #eMinions do

      local minion = eMinions[i]
      if IsValid(minion) then
        if myHero.pos:DistanceTo(minion.pos) < 650 and Ready(_Q) then
          if self.Menu.lastHit.Q:Value() and lastQ +70  < GetTickCount() then

            local WDmg = getdmg("Q", minion, myHero, 1)
            if (WDmg > minion.health) then
              Control.CastSpell(HK_Q, minion.pos)
              lastQ = GetTickCount()
              return
            end



          end

        end
      end

      local WDmg = getdmg("E", minion, myHero, 1)
      if self.Menu.lastHit.E:Value() and  lastE +180  < GetTickCount()
        and Ready(_E) and (WDmg > minion.health) then
        Control.CastSpell(HK_E, minion.pos)
        lastE = GetTickCount()
        return
      end

    end
  end
end


function MissFortune:Draw()
  if myHero.dead then return  end
  if self.Menu.Drawing.R:Value() and Ready(_R) then
    Draw.Circle(myHero, 1400, 1, Draw.Color(255, 225, 255, 10))
  end
  if self.Menu.Drawing.Q:Value() and Ready(_Q) then
    Draw.Circle(myHero, 650, 1, Draw.Color(225, 225, 0, 10))
  end
  if self.Menu.Drawing.E:Value() and Ready(_E) then
    Draw.Circle(myHero, 1000, 1, Draw.Color(225, 225, 125, 10))
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

function MissFortune:GetTarget(range, list)
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

function MissFortune:GetTargetInRange(range, target)
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


function MissFortune:GetHeroInRange(range, target)

  for i = 1, #Enemys do
    local hero = Enemys[i]
    if IsValid(hero) then
      if GetDistanceSquared(target.pos, hero.pos) < range * range then
        return hero
      end
    end
  end
end



function NearestEnemy(origin, range)
  local enemy = nil
  local distance = range
  for i = 1,#Enemys do
    local hero = Enemys[i]
    if hero and IsValid(hero) then
      local d =  LocalGeometry:GetDistance(origin, hero.pos)
      if d < range  and d < distance  then
        distance = d
        enemy = hero
      end
    end
  end
  if distance < range then
    return enemy, distance
  end
end


function GetQBounceTarget(target)
  if not target then return end

  local bounceTargetDelay = LocalGeometry:InterceptTime(myHero, target,0.25 , 1800)
  local targetOrigin = LocalGeometry:PredictUnitPosition(target, bounceTargetDelay)

  if not LocalGeometry:IsInRange(myHero.pos, targetOrigin, 650) then return end

  local topVector = targetOrigin +(targetOrigin - myHero.pos):Perpendicular():Normalized()* 500
  local bottomVector = targetOrigin +(targetOrigin - myHero.pos):Perpendicular2():Normalized()* 500


  local targets = {}
  local eMinions = SDK.ObjectManager:GetEnemyMinions(650)

  for i = 1, #eMinions do
    local hero = eMinions[i]

    if IsValid(hero) and hero.networkID ~= target.networkID then
      local heroOrigin = LocalGeometry:PredictUnitPosition(hero, bounceTargetDelay)

      if LocalGeometry:IsInRange(targetOrigin, heroOrigin, 400 + hero.boundingRadius) and
        not LocalGeometry:IsInRange(topVector, heroOrigin, 350 - hero.boundingRadius) and
        not LocalGeometry:IsInRange(bottomVector, heroOrigin, 350 - hero.boundingRadius) and
        LocalGeometry:GetDistanceSqr(myHero.pos, heroOrigin) > LocalGeometry:GetDistanceSqr(myHero.pos, targetOrigin) then
        targets[#targets + 1] = {t = hero, d = LocalGeometry:GetDistance(targetOrigin, heroOrigin)}
      end
    end
  end

  for i = 1, #Enemys do

    local hero = Enemys[i]

    if IsValid(hero) and hero.networkID ~= target.networkID then
      local heroOrigin = LocalGeometry:PredictUnitPosition(hero, bounceTargetDelay )
      if LocalGeometry:IsInRange(targetOrigin, heroOrigin, 400 + hero.boundingRadius) and
        not LocalGeometry:IsInRange(topVector, heroOrigin, 350 - hero.boundingRadius) and
        not LocalGeometry:IsInRange(bottomVector, heroOrigin, 350 - hero.boundingRadius) and
        LocalGeometry:GetDistanceSqr(myHero.pos, heroOrigin) > LocalGeometry:GetDistanceSqr(myHero.pos, targetOrigin) then
        targets[#targets + 1] = {t = hero, d = LocalGeometry:GetDistance(targetOrigin, heroOrigin)}
      end
    end
  end

  if #targets > 0 then
    LocalTableSort(targets, function (a,b) return a.d < b.d end)
    return targets[1].t
  end

end



MissFortune()
