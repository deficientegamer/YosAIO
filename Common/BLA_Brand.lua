require("BLA_Common") -- load common functions
require('GamsteronPrediction')
require('PussyDamageLib')

class "Brand"

function Brand:__init()

  self.Q = {Type = _G.SPELLTYPE_LINE, Delay = 0.25, Speed = 1600 , range = 1050, width = 60, Collision = true, MaxCollision = 0, CollisionTypes = {_G.COLLISION_MINION, _G.COLLISION_ENEMYHERO, _G.COLLISION_YASUOWALL}}
  self.W = {Type = _G.SPELLTYPE_CIRCLE, Delay = 0.9, Speed = math.huge , range = 900, radius = 200}
  self.E = {range = 625}
  self.R = {range = 750}

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

function Brand:LoadMenu()

  self.Menu = MenuElement({type = MENU, id = "BLABrand", name = "SoldierAIO Brand RC 0.3"})

  self.Menu:MenuElement({type = MENU, id = "combo", name = "Combo"})
  self.Menu.combo:MenuElement({id = "Q", name = "Q", value = true})
  self.Menu.combo:MenuElement({id = "W", name = "W", value = true})
  self.Menu.combo:MenuElement({id = "E", name = "E", value = true})
  self.Menu.combo:MenuElement({id = "R", name = "R", value = true})
  self.Menu.combo:MenuElement({id = "minQ", name = "Q min distance in Combo", value = 320, min = 0, max = 625, step = 1})
  self.Menu.combo:MenuElement({id = "minComboR", name = "R min enemy's in Combo", value = 1, min = 1, max = 5, step = 1})
  self.Menu.combo:MenuElement({id = "dmgMultiplierR", name = "R damge multiplier", value = 25, min = 10, max = 50, step = 1})
  self.Menu.combo:MenuElement({id = "ignite", name = "Ignite in Combo", value = true})
  self.Menu.combo:MenuElement({id = "ignitehp", name = "Ignite HP:", value = 35, min = 5, max = 95, identifier = "%"})
  self.Menu.combo:MenuElement({id = "exaust", name = "Exhaust in Combo", value = true})
  self.Menu.combo:MenuElement({id = "prediction", name = "Q HitChance (1=normal;2=high)", value = 2, min = 1, max =2, step = 1})


  self.Menu:MenuElement({type = MENU, id = "harass", name = "Harass"})
  self.Menu.harass:MenuElement({id = "W", name = "use W", value = true})
  self.Menu.harass:MenuElement({id = "E", name = "use E", value = true})
  self.Menu.harass:MenuElement({id = "Q", name = "use Q", value = true})
  self.Menu.harass:MenuElement({id = "prediction", name = "HitChance (1=normal;2=high)", value = 2, min = 1, max =2, step = 1})

  self.Menu:MenuElement({type = MENU, id = "auto", name = "Auto (Insecure)"})
  self.Menu.auto:MenuElement({id = "use", name = "Use", value = false})
  self.Menu.auto:MenuElement({id = "R", name = "R", value = false})
  self.Menu.auto:MenuElement({id = "minAutoR", name = "Min R target", value = 4, min = 1, max = 5, step = 1})
  self.Menu.auto:MenuElement({id = "Q", name = "auto Q to stun", value = false})
  self.Menu.auto:MenuElement({id = "maxRange", name = "Max Q Range", value = 875, min = 0, max = 875, step = 1})
  self.Menu.auto:MenuElement({id = "W", name = "auto W if Immobile", value = false})
  self.Menu.auto:MenuElement({id = "E", name = "auto E if Buff count 2", value = false})
  self.Menu.auto:MenuElement({type = MENU, id = "AntiDash", name = "E Anti Dash Target"})
  OnEnemyHeroLoad(function(hero) self.Menu.auto.AntiDash:MenuElement({id = hero.charName, name = hero.charName, value = false}) end)
  self.Menu.auto:MenuElement({id = "prediction", name = "HitChance (1=normal;2=high)", value = 2, min = 1, max =2, step = 1})

  self.Menu:MenuElement({type = MENU, id = "clear", name = "Clear"})
  self.Menu.clear:MenuElement({id = "W", name = "W on 3 minions +", value = true})
  self.Menu.clear:MenuElement({id = "ECombo", name = "(W) + E Combo on 3 minions +", value = true})
  self.Menu.clear:MenuElement({id = "E", name = "E on solo minion", value = false})

  self.Menu:MenuElement({type = MENU, id = "lastHit", name = "LastHit"})
  self.Menu.lastHit:MenuElement({id = "Q", name = "Q", value = true})
  self.Menu.lastHit:MenuElement({id = "E", name = "E", value = true})
  self.Menu.lastHit:MenuElement({id = "prediction", name = "HitChance (1=normal;2=high)", value = 2, min = 1, max =2, step = 1})


  self.Menu:MenuElement({type = MENU, id = "escape", name = "Escape"})
  self.Menu.escape:MenuElement({id = "exaust", name = "Exhaust", value = true})

  self.Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawing"})
  self.Menu.Drawing:MenuElement({id = "Q", name = "Draw [Q] Range", value = true})
  self.Menu.Drawing:MenuElement({id = "W", name = "Draw [W] Range", value = true})
  self.Menu.Drawing:MenuElement({id = "E", name = "Draw [E] Range", value = true})
  self.Menu.Drawing:MenuElement({id = "R", name = "Draw [R] Range", value = true})

end


function Brand:Tick()
  if myHero.dead or Game.IsChatOpen() or (ExtLibEvade and ExtLibEvade.Evading == true) then
    return
  end

  if self.Menu.auto.use:Value() then
    self:Auto()
  end

  if Orb.Modes[ORBWALKER_MODE_COMBO] then
    self:Combo()
    self:castIginite()
    self:castExaust()
  elseif Orb.Modes[ORBWALKER_MODE_HARASS] then
    self:Harass()
  elseif Orb.Modes[ORBWALKER_MODE_LANECLEAR] then
    self:Clear()
  elseif Orb.Modes[ORBWALKER_MODE_LASTHIT] then
    self:LastHit()
  elseif Orb.Modes[ORBWALKER_MODE_FLEE] then
    self:castExaust()
  end

end

function Brand:Combo()
  local target = nil



  target = self:GetTarget(1000)
  if IsValid(target) then
    if self.Menu.combo.Q:Value()
      and Ready(_Q) and lastQ + 550 < GetTickCount() then


      local distanceSqr = GetDistanceSquared(myHero.pos, target.pos)
      local hasBuff, duration = self:HasPassiveBuff(target)
      local time = 0.25 + distanceSqr/(1600*1600)
      if hasBuff and duration >= time then
        local Pred = GetGamsteronPrediction(target, self.Q, myHero)
        if Pred.Hitchance >= self.Menu.auto.prediction:Value() then
          Control.CastSpell(HK_Q, Pred.CastPosition)
          lastQ = GetTickCount()
          return
        end
      end
    end
  end

  target = self:GetTarget(900)
  if self.Menu.combo.W:Value() and lastW + 80 < GetTickCount() and Ready(_W) and IsValid(target) then
    if target and self.Menu.combo.W:Value() then
      self:CastW(target)
    end

    -- E
    target = self:GetTarget(600)
    if IsValid(target) then
      local distanceSqr = GetDistanceSquared(myHero.pos, target.pos)

      if Ready(_E) and lastE +60 < GetTickCount() and distanceSqr < 625*625 then
        if target and self.Menu.combo.E:Value() then
          Control.CastSpell(HK_E,target)
          lastE = GetTickCount()
        end
      end
    end

    target = self:GetTarget(1000)
    if IsValid(target) then

      local distanceSqr = GetDistanceSquared(myHero.pos, target.pos)

      if self.Menu.combo.Q:Value()
        and Ready(_Q) and lastQ + 60 < GetTickCount() then
        local hasBuff, duration = self:HasPassiveBuff(target)
        local time = 0.25 + distanceSqr/(1600*1600)
        if hasBuff and duration >= time then
          local Pred = GetGamsteronPrediction(target, self.Q, myHero)
          if Pred.Hitchance >= self.Menu.combo.prediction:Value() then
            Control.CastSpell(HK_Q, Pred.CastPosition)
            lastQ = GetTickCount()
            return
          end
        end
      end
    end


  end

  for i = 1, #Enemys do
    local hero = Enemys[i]
    local numAround = self:GetTargetInRange(650, hero)
    local RDmg = getdmg("R", hero, myHero, 1)
    if IsValid(target) then

      if self.Menu.combo.R:Value() and Ready(_R)
        and (numAround >= self.Menu.combo.minComboR:Value() or RDmg*(self.Menu.combo.dmgMultiplierR:Value()/10) > hero.health)  then
        Control.CastSpell(HK_R, hero)
        lastR = GetTickCount()
        return
      end
    end
  end
  -- Q With E
  target = self:GetTarget(900)
  if IsValid(target) then

    if target and self.Menu.combo.Q:Value() and Ready(_Q) and Ready(_E) and lastQ + 60 < GetTickCount()  then
      local Pred = GetGamsteronPrediction(target, self.Q, myHero)
      if Pred.Hitchance >= self.Menu.combo.prediction:Value()
        and GetDistanceSquared(myHero.pos, Pred.CastPosition) >= self.Menu.combo.minQ:Value()^2
        and GetDistanceSquared(myHero.pos, Pred.CastPosition) < self.E.range^2
      then
        Control.CastSpell(HK_Q, Pred.CastPosition)
        lastQ = GetTickCount()
        DelayAction(
          function()
            Control.CastSpell(HK_E, target)
            lastE = GetTickCount()
          end, 1
        )
      end
    end
  end

  target = self:GetTarget(625)
  if IsValid(target) then

    if target and self.Menu.combo.E:Value() and Ready(_E)
      and lastE + 60 < GetTickCount() then
      local Pred = GetGamsteronPrediction(target, self.E, myHero)
      if Pred.Hitchance >= self.Menu.combo.prediction:Value() then
        Control.CastSpell(HK_E, target)
        lastE = GetTickCount()
      end
    end
  end

end

function Brand:Harass()
  local  target = self:GetTarget(900)
  if self.Menu.harass.W:Value() and lastW + 80 < GetTickCount() and target  and Ready(_W) and IsValid(target) then
    self:CastW(target)

    lastW = GetTickCount()
  end

  local  target = self:GetTarget(625)
  if self.Menu.harass.E:Value() and lastE + 60 < GetTickCount() and target  and Ready(_E) and IsValid(target)  then
    Control.CastSpell(HK_E, target)
    lastE = GetTickCount()
  end
end

function Brand:Clear()
  -- Atack enemys minions
  local eMinions = SDK.ObjectManager:GetEnemyMinions(self.W.range)
  for i = 1, #eMinions do
    local minion = eMinions[i]
    if IsValid(minion) then
      -- Use WE if possible, min 3 minions
      if self.Menu.clear.W:Value()
        and lastW + 80
        and myHero.pos:DistanceTo(minion.pos) < 625 and Ready(_W) then
        local count = GetMinionCount(160, minion)
        if count >=3 then
          Control.CastSpell(HK_W, minion.pos)
          if self.Menu.clear.ECombo:Value() then
            DelayAction(
              function()
                Control.CastSpell(HK_E, minion.pos)
                lastE = GetTickCount()
              end, 1
            )
          end
        end
      end
      -- use E if user decide
      if self.Menu.clear.E:Value()
        and lastE + 60 < GetTickCount()
        and myHero.pos:DistanceTo(minion.pos) < 625 and Ready(_E) then
        Control.CastSpell(HK_E, minion.pos)
        lastE = GetTickCount()
      end

    end
  end
end


function Brand:LastHit()

  if self.Menu.lastHit.Q:Value() then
    -- Cast Q
    local eMinions = SDK.ObjectManager:GetEnemyMinions(self.Q.range)
    for i = 1, #eMinions do

      local minion = eMinions[i]

      -- Q
      if IsValid(minion) then
        if myHero.pos:DistanceTo(minion.pos) < 950 and Ready(_Q) then
          if self.Menu.auto.Q:Value()
            and Ready(_Q)  then

            local WDmg = getdmg("Q", minion, myHero, 1)
            if (WDmg > minion.health) then
              local Pred = GetGamsteronPrediction(target, self.E, myHero)
              if Pred.Hitchance >= self.Menu.lastHit.prediction:Value() then
                Control.CastSpell(HK_Q, minion.pos)
                lastQ = GetTickCount()

              end
            end

          end
        end


        -- E
        if IsValid(minion) then
          if myHero.pos:DistanceTo(minion.pos) < 625 and Ready(_E) then
            if self.Menu.auto.Q:Value()
              and Ready(_E)  then

              local WDmg = getdmg("E", minion, myHero, 1)
              if (WDmg > minion.health) then
                Control.CastSpell(HK_E, minion.pos)
                lastE = GetTickCount()
                return
              end

            end
          end



        end
      end
    end
  end
end


function Brand:Draw()
  if myHero.dead then return  end
  if self.Menu.Drawing.R:Value() and Ready(_R) then
    Draw.Circle(myHero, 750, 1, Draw.Color(255, 225, 255, 10))
  end
  if self.Menu.Drawing.Q:Value() and Ready(_Q) then
    Draw.Circle(myHero, 1050, 1, Draw.Color(225, 225, 0, 10))
  end
  if self.Menu.Drawing.E:Value() and Ready(_E) then
    Draw.Circle(myHero, 625, 1, Draw.Color(225, 225, 125, 10))
  end
  if self.Menu.Drawing.W:Value() and Ready(_W) then
    Draw.Circle(myHero, 900, 1, Draw.Color(225, 225, 125, 10))
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


function Brand:Auto()
  for i = 1, #Enemys do
    local hero = Enemys[i]
    if IsValid(hero) then
      local distanceSqr = GetDistanceSquared(myHero.pos, hero.pos)
      if Ready(_R) and lastR + 750 < GetTickCount() and distanceSqr < self.R.range^2 then
        local numAround = self:GetTargetInRange(480, hero)
        if self.Menu.auto.R:Value() and numAround >= self.Menu.auto.minAutoR:Value() then
          Control.CastSpell(HK_R, hero)
          lastR = GetTickCount()
        end
      end


      if self.Menu.auto.Q:Value() and distanceSqr < self.Menu.auto.maxRange:Value() ^2
        and Ready(_Q) and lastQ + 550 < GetTickCount() then
        local hasBuff, duration = self:HasPassiveBuff(hero)
        local time = 0.25 + distanceSqr/(1600*1600)
        if hasBuff and duration >= time then
          local Pred = GetGamsteronPrediction(hero, self.Q, myHero)
          if Pred.Hitchance >= self.Menu.auto.prediction:Value() then
            Control.CastSpell(HK_Q, Pred.CastPosition)
            lastQ = GetTickCount()
            return
          end
        end
      end

      if self.Menu.auto.W:Value() and Ready(_W) and lastW + 700 < GetTickCount() and distanceSqr < 900*900 then
        local Pred = GetGamsteronPrediction(hero, self.W, myHero)
        if Pred.Hitchance >= _G.HITCHANCE_IMMOBILE then
          Control.CastSpell(HK_W, Pred.CastPosition)
          lastW = GetTickCount()
          return
        end
      end

      -- AntiDash thanks D3ftsu
      if self.Menu.auto.AntiDash[hero.charName]
        and self.Menu.auto.AntiDash[hero.charName]:Value()
        and hero.pathing.isDashing
        and hero.pathing.dashSpeed>0
        and Ready(_Q)
        and Ready(_E)
        and lastE+60 < GetTickCount()
        and distanceSqr < 625*625 then
        Control.CastSpell(HK_E, hero)
        lastE = GetTickCount()
        return
      end

      if self.Menu.auto.E:Value() and Ready(_E) and lastE +60 < GetTickCount() and distanceSqr < 625*625 then
        local hasBuff, duration, count = self:HasPassiveBuff(hero)
        if hasBuff and count == 2 then
          Control.CastSpell(HK_E, hero)
          lastE = GetTickCount()
          return
        end

      end
    end
  end
end

function Brand:castIginite()
  if self.Menu.combo.ignite:Value() == false then return end
  if myHero.dead then return end
  for i = 1, #Enemys do
    local target = Enemys[i]
    if IsValid(target) then
      local TargetHp = target.health/target.maxHealth

      if TargetHp <= self.Menu.combo.ignitehp:Value()/100 and myHero.pos:DistanceTo(target.pos) <= 600 then
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
function Brand:castExaust()
  if self.Menu.combo.exaust:Value() == false then return end
  if myHero.dead then return end
  for i = 1, #Enemys do
    local target = Enemys[i]
    if IsValid(target) then
      if myHero.pos:DistanceTo(target.pos) <= 650  then
        if myHero:GetSpellData(SUMMONER_1).name == "SummonerExhaust" and Ready(SUMMONER_1) then
          Control.CastSpell(HK_SUMMONER_1, target)
        elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerExhaust" and Ready(SUMMONER_2) then
          Control.CastSpell(HK_SUMMONER_2, target)
        end
      end

    end
  end
end

function Brand:CastW(target)
  if Ready(_W) and lastW + 600 < GetTickCount() then

    local Pred = GetGamsteronPrediction(target, self.W, myHero)

    if Pred.Hitchance >= _G.HITCHANCE_HIGH then
      Control.CastSpell(HK_W, Pred.CastPosition)
      lastW = GetTickCount()
    end
  end
end

function Brand:GetTarget(range, list)
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

function Brand:GetTargetInRange(range, target)
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

function Brand:HasPassiveBuff(unit)
  local name = "BrandAblaze"
  for i = 0, unit.buffCount do
    local buff = unit:GetBuff(i)
    if buff and buff.count > 0 and buff.name == name then
      return true, buff.duration, buff.count
    end
  end
  return false
end

--
--function Brand:GetEnemyMinions(range)
--  local EnemyMinions = {}
--  for i = 1, Game.MinionCount() do
--    local Minion = Game.Minion(i)
--    if Minion then
--      table.insert(EnemyMinions, Minion)
--    end
--  end
--  return EnemyMinions
--end



Brand()
