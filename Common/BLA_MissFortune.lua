require("BLA_Common") -- load common functions
require('GamsteronPrediction')
require('PussyDamageLib')

local LocalTableSort        = table.sort
local LocalStringFind       = string.find
local inUlt = false

class "MissFortune"

function MissFortune:__init()

  self.Q = {Type = _G.SPELLTYPE_LINE, range = 650,  delay = 0.25,  speed = 1800, Collision = true, MaxCollision = 1, CollisionTypes = {_G.COLLISION_MINION, _G.COLLISION_ENEMYHERO, _G.COLLISION_YASUOWALL}}
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
      if lastMove + 220 > GetTickCount() then
        args.Process = false
      else
        args.Process = true
        lastMove = GetTickCount()
      end
    end
  )
end

function MissFortune:LoadMenu()

  self.Menu = MenuElement({type = MENU, id = "BLAMissFortune", name = "BotLaneAIO MissFortune RC 0.1"})

  self.Menu:MenuElement({type = MENU, id = "combo", name = "Combo"})
  self.Menu.combo:MenuElement({id = "Q", name = "Q", value = true})
  self.Menu.combo:MenuElement({id = "W", name = "W", value = true})
  self.Menu.combo:MenuElement({id = "E", name = "E", value = true})
  self.Menu.combo:MenuElement({id = "R", name = "R", value = true})
  self.Menu.combo:MenuElement({id = "maxQ", name = "Q max distance in Combo", value = 650, min = 0, max = 650, step = 1})
  self.Menu.combo:MenuElement({id = "minComboR", name = "R min enemy's in Combo", value = 2, min = 1, max = 5, step = 1})

  self.Menu:MenuElement({type = MENU, id = "harass", name = "Harass"})
  self.Menu.harass:MenuElement({id = "Q", name = "Use Q if two targets", value = true})
  self.Menu.harass:MenuElement({id = "E", name = "Use E", value = true})

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
  local target = nil
  -- E Start
  target = self:GetTarget(690)
  if inUlt == false then
    if self.Menu.combo.E:Value()  and lastE +180 and Ready(_E) and IsValid(target) then
      local Pred = GetGamsteronPrediction(target, self.E, myHero)
      if Pred.Hitchance >= _G.HITCHANCE_HIGH then
        if target and self.Menu.combo.E:Value() then
          Control.CastSpell(HK_E,Pred.CastPosition)
        end
      end
    end
    -- E End

    -- W Start
    if self.Menu.combo.W:Value()  and lastW +120 and Ready(_W) then
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
  -- R Start
  for i = 1, #Enemys do
    local hero = Enemys[i]
    local numAround = self:GetTargetInRange(940, hero)
    local RDmg = getdmg("R", hero, myHero, 1)
    local count = self:GetTargetInRange(420, hero) -- inimigos proximo ao alvo
    if count >=self.Menu.combo.minComboR:Value() and IsValid(hero)
      and Ready(_R) then
    
      if self.Menu.combo.R:Value() 
        and (numAround >= self.Menu.combo.minComboR:Value() or RDmg/1.6 > hero.health)  then
        _G.SDK.Orbwalker:SetMovement(false) -- Stop moviment in R
        inUlt=true
        Control.CastSpell(HK_R, hero)
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
  -- R End

end

function MissFortune:Harass()
  local targetE = nil
  local  targetE = self:GetTarget(1000)
  if self.Menu.harass.E:Value() and targetE and Ready(_E) and IsValid(targetE) then
     Control.CastSpell(HK_E,target)
  end



  local target = self:GetTarget(self.Q.range, true)

  if IsValid(target) then
    if self.Menu.harass.Q:Value() then
      Control.CastSpell(HK_Q, target)
      lastQ = GetTickCount()
      return
    end
  end



end

function MissFortune:Clear()

  -- Atack enemys minions
  local eMinions = SDK.ObjectManager:GetEnemyMinions(self.Q.range)
  for i = 1, #eMinions do
    local minion = eMinions[i]
    if IsValid(minion) then
      if self.Menu.clear.Q:Value()
        and myHero.pos:DistanceTo(minion.pos) < 580 and Ready(_W) then
        local count = GetMinionCount(200, minion)
        if count >=3 then
          -- use E if user decide
          if self.Menu.clear.E:Value()
            and Ready(_E) then
            Control.CastSpell(HK_E, minion.pos)
          end

          Control.CastSpell(HK_Q, minion.pos)
          if self.Menu.clear.Q:Value() then
          end
        end
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
          if self.Menu.lastHit.Q:Value()
            and Ready(_Q)  then

            local WDmg = getdmg("Q", minion, myHero, 1)
            if (WDmg > minion.health) then
              Control.CastSpell(HK_Q, minion.pos)
              return
            end

            local WDmg = getdmg("E", minion, myHero, 1)
            if self.Menu.lastHit.E:Value() and (WDmg > minion.health) then
              Control.CastSpell(HK_Q, minion.pos)
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


MissFortune()
