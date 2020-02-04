require("BLA_Common") -- load common functions
require('GamsteronPrediction')
require('PussyDamageLib')

local LocalTableSort        = table.sort
local LocalStringFind       = string.find
local inUlt = false

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

  self.Menu = MenuElement({type = MENU, id = "BLAMissFortune", name = "BotLaneAIO MissFortune RC 0.2"})

  self.Menu:MenuElement({type = MENU, id = "combo", name = "Combo"})
  self.Menu.combo:MenuElement({id = "Q", name = "Q", value = true})
  self.Menu.combo:MenuElement({id = "maxQ", name = "Q max distance in Combo", value = 650, min = 0, max = 650, step = 1})
  self.Menu.combo:MenuElement({id = "W", name = "W", value = true})
  self.Menu.combo:MenuElement({id = "E", name = "E", value = true})
  self.Menu.combo:MenuElement({id = "R", name = "R", value = true})
  self.Menu.combo:MenuElement({id = "minComboR", name = "R - whenever X(+) enemy's", value = 3, min = 1, max = 5, step = 1})
  self.Menu.combo:MenuElement({id = "RHighDamgeChange", name = "R - whenever high dmg", value = true})
  self.Menu.combo:MenuElement({id = "RImmobileHighDamgeChange", name = "R - whenever immobile high dmg", value = true})
  self.Menu.combo:MenuElement({id = "RHighKSChange", name = "R - whenever very high KS chance", value = true})

  self.Menu:MenuElement({type = MENU, id = "harass", name = "Harass"})
  self.Menu.harass:MenuElement({id = "Qminion", name = "Q in minion with enemy near", value = true})
  self.Menu.harass:MenuElement({id = "Qenemy", name = "Q in enemy with enemy near", value = true})
  self.Menu.harass:MenuElement({id = "E", name = "E in enemy", value = true})

  self.Menu:MenuElement({type = MENU, id = "clear", name = "Clear"})
  self.Menu.clear:MenuElement({id = "Q", name = "Q", value = true})
  self.Menu.clear:MenuElement({id = "E", name = "E", value = false})

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

function MissFortune:Combo()

  if inUlt == true then return false end
  local target = nil

  -- R Start
  if lastR + 400 < GetTickCount() and Ready(_R) then
    for i = 1, #Enemys do

      local hero = Enemys[i]
      local distanceSqr = GetDistanceSquared(myHero.pos, hero.pos)

      if  distanceSqr < self.R.range ^2 then
        local maxDistance = self:GetTargetInRange(900, myHero)
        local numAround = self:GetTargetInRange(650, hero)
        local RDmg = getdmg("R", hero, myHero, 1)

        if self.Menu.combo.R:Value() and maxDistance > 0 then
          _G.SDK.Orbwalker:SetMovement(false) -- Stop moviment in R

          local Pred = GetGamsteronPrediction(hero, self.R, myHero)
          -- solta r quando tem muito inimigo, ou inimigo esta imovel e chance de matar ou muita quando tem chance de matar
          if (numAround >= self.Menu.combo.minComboR:Value())
            or (self.Menu.combo.RHighDamgeChange:Value()
            and Pred.Hitchance >= _G.HITCHANCE_HIGH or RDmg/1.4 > hero.health)
            or (self.Menu.combo.RImmobileHighDamgeChange:Value()
            and Pred.Hitchance >= _G.HITCHANCE_IMMOBILE or RDmg > hero.health)
            or (self.Menu.combo.RHighKSChange:Value()
            and Pred.Hitchance >= _G.HITCHANCE_HIGH or RDmg/1.6 > hero.health) then

            inUlt=true
            Control.CastSpell(HK_R, Pred.CastPosition)
            lastR = GetTickCount()

            -- MOV AFTER 3 + 0.20
            DelayAction(
              function()
                _G.SDK.Orbwalker:SetMovement(true)
                inUlt=false
              end, 3 + 0.20
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
      end
    end
  end
  -- E End

  -- W Start
  if self.Menu.combo.W:Value()  and lastW +120  < GetTickCount() and Ready(_W) then
    Control.CastSpell(HK_W)
  end
  -- W End

  -- Q Start
  target = self:GetTarget(690)


  if IsValid(target) then
    local distanceSqr = GetDistanceSquared(myHero.pos, target.pos)
    if self.Menu.combo.Q:Value()
      and distanceSqr < self.Menu.combo.maxQ:Value() ^2
      and Ready(_Q) and lastQ + 170 < GetTickCount() then
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

  -- bounce with minion
  if self.Menu.harass.Qminion:Value() and  lastQ +180 < GetTickCount() and Ready(_Q) then
    local eMinions = SDK.ObjectManager:GetEnemyMinions(650)
    for i = 1, #eMinions do
      local minion = eMinions[i]
      if IsValid(minion) then
        -- Check have enemy hero near
        local hero = self:GetHeroInRange(390, minion)
        local Pred = GetGamsteronPrediction(hero, self.Q, myHero)

        if IsValid(hero) and Pred.Hitchance >= _G.HITCHANCE_NORMAL then
          Control.CastSpell(HK_Q, minion.pos)
        end

      end
    end
  end

  -- bounce with enemy
  if self.Menu.harass.Qenemy:Value() and  lastQ +180 < GetTickCount() and Ready(_Q) then
    for i = 1, #Enemys do
      local hero1 = Enemys[i]
      if IsValid(hero1) then

        -- Check have enemy hero near
        local hero2 = self:GetHeroInRange(390, hero1)
        if hero2 ~= hero1 then
          local Pred = GetGamsteronPrediction(hero2, self.Q, myHero)
          if IsValid(hero2) and Pred.Hitchance >= _G.HITCHANCE_NORMAL then
            Control.CastSpell(HK_Q, hero1.pos)
          end
        end
      end
    end
  end

  if self.Menu.harass.E:Value()  and lastE +180  < GetTickCount() and Ready(_E) and IsValid(target) then
    local Pred = GetGamsteronPrediction(target, self.E, myHero)
    if Pred.Hitchance >= _G.HITCHANCE_HIGH then
      if target and self.Menu.harass.E:Value() then
        Control.CastSpell(HK_E,Pred.CastPosition)
      end
    end
  end


end

function MissFortune:Clear()
  if inUlt == true then return false end
  -- Atack enemys minions
  local eMinions = SDK.ObjectManager:GetEnemyMinions(self.Q.range)
  for i = 1, #eMinions do
    local minion = eMinions[i]
    if IsValid(minion) then
      if self.Menu.clear.Q:Value()
        and  lastQ +180 < GetTickCount()
        and myHero.pos:DistanceTo(minion.pos) < 650 and Ready(_Q) then
        local count = GetMinionCount(280, minion)
        if count >=2 then
          -- use E if user decide
          local Pred = GetGamsteronPrediction(target, self.E, minion)
          if Pred.Hitchance >= _G.HITCHANCE_HIGH then
            if self.Menu.clear.E:Value()
              and Ready(_E) then
              Control.CastSpell(HK_E, Pred.CastPosition)
            end
          end

          local Pred = GetGamsteronPrediction(target, self.Q, minion)
          if Pred.Hitchance >= _G.HITCHANCE_HIGH then
            if self.Menu.clear.Q:Value()
              and Ready(_Q) then
              Control.CastSpell(HK_Q, Pred.CastPosition)
            end
          end
        end
      end

    end
  end
end


function MissFortune:LastHit()

  if self.Menu.lastHit.Q:Value()  and Ready(_Q)then
    -- Cast Q
    local eMinions = SDK.ObjectManager:GetEnemyMinions(self.Q.range)
    for i = 1, #eMinions do

      local minion = eMinions[i]
      if IsValid(minion) then
        if myHero.pos:DistanceTo(minion.pos) < 650 and Ready(_Q) then
          if self.Menu.lastHit.Q:Value() then

            local WDmg = getdmg("Q", minion, myHero, 1)
            if (WDmg > minion.health) then
              Control.CastSpell(HK_Q, minion.pos)
              return
            end

            local WDmg = getdmg("E", minion, myHero, 1)
            if self.Menu.lastHit.E:Value()  and Ready(_E) and (WDmg > minion.health) then
              Control.CastSpell(HK_E, minion.pos)
              return
            end

          end
        end
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


MissFortune()
