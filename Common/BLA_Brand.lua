require("BLA_Common") -- load common functions
require('GamsteronPrediction')
require('PussyDamageLib')

class "Brand"

function Brand:__init()

  self.Q = {Type = _G.SPELLTYPE_LINE, Delay = 0.25, Speed = 1600 , range = 1050, width = 60, Collision = true, MaxCollision = 0, CollisionTypes = {_G.COLLISION_MINION, _G.COLLISION_ENEMYHERO, _G.COLLISION_YASUOWALL}}
  self.W = {Type = _G.SPELLTYPE_CIRCLE, Delay = 0.9, Speed = math.huge , range = 900, radius = 200}
  self.E = {range = 625}
  self.R = {range = 750, Collision = true, MaxCollision = 0, CollisionTypes = {_G.COLLISION_MINION, _G.COLLISION_ENEMYHERO, _G.COLLISION_YASUOWALL}}

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

function Brand:LoadMenu()

  self.Menu = MenuElement({type = MENU, id = "BLABrand", name = "SoldierAIO Brand RC 0.4"})

  self.Menu:MenuElement({type = MENU, id = "combo", name = "Combo"})
  self.Menu.combo:MenuElement({id = "Q", name = "Q", value = true})
  self.Menu.combo:MenuElement({id = "W", name = "W", value = true})
  self.Menu.combo:MenuElement({id = "E", name = "E", value = true})
  self.Menu.combo:MenuElement({id = "R", name = "R", value = true})
  self.Menu.combo:MenuElement({id = "minQ", name = "Q min distance in Combo", value = 320, min = 0, max = 625, step = 1})
  self.Menu.combo:MenuElement({id = "minComboR", name = "R min enemy's in Combo", value = 1, min = 1, max = 5, step = 1})
  self.Menu.combo:MenuElement({id = "dmgMultiplierR", name = "R damge multiplier", value = 10, min = 10, max = 30, step = 1, , identifier = "%"})
  self.Menu.combo:MenuElement({id = "ignite", name = "Ignite in Combo", value = true})
  self.Menu.combo:MenuElement({id = "ignitehp", name = "Ignite HP:", value = 35, min = 5, max = 95, identifier = "%"})
  self.Menu.combo:MenuElement({id = "exaust", name = "Exhaust in Combo", value = true})
  self.Menu.combo:MenuElement({id = "prediction", name = "HitChance (2=normal;3=high;4=immobile)", value = 3, min = 2, max =4, step = 1})


  self.Menu:MenuElement({type = MENU, id = "harass", name = "Harass"})
  self.Menu.harass:MenuElement({id = "W", name = "use W", value = true})
  self.Menu.harass:MenuElement({id = "E", name = "use E", value = true})
  self.Menu.harass:MenuElement({id = "Q", name = "use Q", value = true})
  self.Menu.harass:MenuElement({id = "prediction", name = "HitChance (2=normal;3=high;4=immobile)", value = 3, min = 2, max =4, step = 1})

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
  self.Menu.auto:MenuElement({id = "prediction", name = "HitChance (2=normal;3=high;4=immobile)", value = 3, min = 2, max =4, step = 1})

  self.Menu:MenuElement({type = MENU, id = "clear", name = "Clear"})
  self.Menu.clear:MenuElement({id = "W", name = "W on 3 minions +", value = true})
  self.Menu.clear:MenuElement({id = "ECombo", name = "(W) + E Combo on 3 minions +", value = true})
  self.Menu.clear:MenuElement({id = "E", name = "E on solo minion", value = false})

  self.Menu:MenuElement({type = MENU, id = "lastHit", name = "LastHit"})
  self.Menu.lastHit:MenuElement({id = "Q", name = "Q", value = true})
  self.Menu.lastHit:MenuElement({id = "E", name = "E", value = true})
  self.Menu.lastHit:MenuElement({id = "prediction", name = "HitChance (2=normal;3=high;4=immobile)", value = 3, min = 2, max =4, step = 1})


  self.Menu:MenuElement({type = MENU, id = "escape", name = "Escape"})
  self.Menu.escape:MenuElement({id = "exaust", name = "Exhaust", value = true})

  self.Menu:MenuElement({type = MENU, id = "settings", name = "Settings"})
  self.Menu.settings:MenuElement({id = "predW", name = "Use Pred in W", value = true})
  self.Menu.settings:MenuElement({id = "forceFocus", name = "Force combo in first target ", value = false})
  self.Menu.settings:MenuElement({id = "predictionW", name = "W HitChance (2=normal;3=high;4=immobile)", value = 3, min = 2, max =4, step = 1})


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
  -- verifica se é pra focar ou não
  if self.Menu.settings.forceFocus:Value() then
    -- força o foco da sequencia em um alvo só

    target = self:GetTarget(860)

    -- nesse caso eu tenho sempre que ver a distancia
    if IsValid(target) then
      local distanceSqr = GetDistanceSquared(myHero.pos, target.pos)

      -- Q se tiver em chamas

      if IsValid(target) and distanceSqr < 1000*1000 then
        if self.Menu.combo.Q:Value()
          and Ready(_Q) and lastQ + 60 < GetTickCount()  and IsValid(target) then
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
      -- END Q

      -- W para começar o combo
      if self.Menu.combo.W:Value() and lastW + 80 < GetTickCount() and Ready(_W) and IsValid(target)
        and distanceSqr < 860*860 then
        self:CastW(target)
        -- tento dar o E depois do W no mesmo alvo
        DelayAction(
          function()
            if distanceSqr < 650*650 then
              Control.CastSpell(HK_E, target)
              lastE = GetTickCount()
            end
          end, 1
        )
      end
      -- W END

      -- Se o E do delay não pegar eu tento dar E em quem tiver buffado

      if self.Menu.combo.E:Value() and Ready(_E) and lastE +60 < GetTickCount()
        and distanceSqr < 625*625 and IsValid(target) then
        local hasBuff, duration, count = self:HasPassiveBuff(target)
        if hasBuff and count > 0 then
          Control.CastSpell(HK_E, target)
          lastE = GetTickCount()
        end
      end


      -- E, se ninguém está bufado dou E dou no primeiro que achar pra tentar dar stun com o Q

      if IsValid(target) then

        if Ready(_E) and lastE +60 < GetTickCount() and distanceSqr < 625*625  and IsValid(target) then
          if target and self.Menu.combo.E:Value() then
            Control.CastSpell(HK_E,target)
            lastE = GetTickCount()
          end
        end
      end

      -- Q, tento stunar (only buffed)

      if IsValid(target) and distanceSqr < 1000*1000 then
        if self.Menu.combo.Q:Value()
          and Ready(_Q) and lastQ + 60 < GetTickCount() and IsValid(target) then
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

      -- R, se tiver gente perto ou for possivel matar
      for i = 1, #Enemys do
        local hero = Enemys[i]
        local numAround = self:GetTargetInRange(650, hero)
        local RDmg = getdmg("R", hero, myHero, 1)
        if IsValid(target) then

          if self.Menu.combo.R:Value() and lastQ + 750 and Ready(_R)
            and distanceSqr < 625*625 and IsValid(target)
            and (numAround >= self.Menu.combo.minComboR:Value() or RDmg*(self.Menu.combo.dmgMultiplierR:Value()/10) > hero.health)  then
            Control.CastSpell(HK_R, hero)
            lastR = GetTickCount()
          end
        end
      end

      if IsValid(target) then

        if target and self.Menu.combo.Q:Value() and Ready(_Q) and Ready(_E) and lastQ + 60 < GetTickCount()
          and distanceSqr < 650*650  then
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
            return
          end
        end
      end
      -- E

      if IsValid(target) then
        if target and self.Menu.combo.E:Value() and Ready(_E)
          and lastE + 60 < GetTickCount()
          and distanceSqr < 650*650 then
          local Pred = GetGamsteronPrediction(target, self.E, myHero)
          if Pred.Hitchance >= self.Menu.combo.prediction:Value() then
            Control.CastSpell(HK_E, target)
            lastE = GetTickCount()
            return
          end
        end
      end
    end

  else
    -- Deixa o orb escolher os alvos durante o combo

    -- Q se tiver em chamas
    target = self:GetTarget(1000)
    if IsValid(target) then
      if self.Menu.combo.Q:Value()
        and lastQ + 550 < GetTickCount()
        and Ready(_Q) then
        local distanceSqr = GetDistanceSquared(myHero.pos, target.pos)
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
    -- END Q


    -- Q With E
    target = self:GetTarget(650)
    if IsValid(target) then

      if self.Menu.combo.Q:Value() and self.Menu.combo.E:Value()
        and Ready(_W) == false
        and Ready(_Q) and Ready(_E)
        and lastQ + 60 < GetTickCount()
        and lastE + 60 < GetTickCount()
        and IsValid(target)  then
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
          return
        end
      end
    end

    -- W para começar o combo
    target = self:GetTarget(900)
    if self.Menu.combo.W:Value() and lastW + 80 < GetTickCount() and Ready(_W) and IsValid(target) then
      self:CastW(target)
      -- tento dar o E depois do W no mesmo alvo
      DelayAction(
        function()
          local distanceSqr = GetDistanceSquared(myHero.pos, target.pos)
          if  distanceSqr < 650*650 then
            Control.CastSpell(HK_E, target)
            lastE = GetTickCount()
          end
        end, 1
      )
    end
    -- W END


    -- Q se tiver em chamas DEPOIS DO WE
    target = self:GetTarget(1000)
    if IsValid(target) then
      if self.Menu.combo.Q:Value()
        and lastQ + 550 < GetTickCount()
        and Ready(_Q) then
        local distanceSqr = GetDistanceSquared(myHero.pos, target.pos)
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
    -- END Q

    -- Se o E do delay não pegar eu tento dar E em quem tiver buffado
    target = self:GetTarget(625)
    if self.Menu.combo.E:Value() and Ready(_E) and lastE +60 < GetTickCount() and IsValid(target) then
      local hasBuff, duration, count = self:HasPassiveBuff(target)
      if hasBuff and count > 0 then
        Control.CastSpell(HK_E, target)
        lastE = GetTickCount()
      end
    end


    -- E, se ninguém está bufado dou E dou no primeiro que achar pra tentar dar stun com o Q
    target = self:GetTarget(625)
    if IsValid(target) and lastE +60 < GetTickCount() then
      local distanceSqr = GetDistanceSquared(myHero.pos, target.pos)

      if Ready(_E)  and distanceSqr < 625*625 then
        if target and self.Menu.combo.E:Value() then
          Control.CastSpell(HK_E,target)
          lastE = GetTickCount()
          -- tento dar o Q depois do E no mesmo alvo
          DelayAction(
            function()
              local distanceSqr = GetDistanceSquared(myHero.pos, target.pos)
              if  distanceSqr < 1000*1000 then
                Control.CastSpell(HK_Q, target)
                lastQ = GetTickCount()
              end
            end, 1
          )

        end
      end
    end

    -- Q, tento stunar (only buffed)
    target = self:GetTarget(1000)
    if IsValid(target) then
      local distanceSqr = GetDistanceSquared(myHero.pos, target.pos)
      if self.Menu.combo.Q:Value()
        and Ready(_Q) and lastQ + 60 < GetTickCount() then
        local hasBuff, duration = self:HasPassiveBuff(target)
        local time = 0.25 + distanceSqr/(1050*1050)
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

    -- R, se tiver gente perto ou for possivel matar
    for i = 1, #Enemys do
      local hero = Enemys[i]
      local numAround = self:GetTargetInRange(650, hero)
      local RDmg = getdmg("R", hero, myHero, 1)
      if IsValid(target) then

        if self.Menu.combo.R:Value() and lastR + 750 and Ready(_R)
          and IsValid(target)
          and (numAround >= self.Menu.combo.minComboR:Value() or RDmg*(self.Menu.combo.dmgMultiplierR:Value()/10) > hero.health)  then
          Control.CastSpell(HK_R, hero)
          lastR = GetTickCount()
        end
      end
    end
    -- E

  end

end

function Brand:Harass()
  local  target = self:GetTarget(900)
  if self.Menu.harass.W:Value() and lastW + 80 < GetTickCount()  and Ready(_W) and IsValid(target) then
    self:CastW(target)
    lastW = GetTickCount()
  end

  local  target = self:GetTarget(625)
  if self.Menu.harass.E:Value() and lastE + 60 < GetTickCount() and Ready(_E) and IsValid(target)  then
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
      -- use E SOLO if user decide
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
      end
    end
  end


  -- E
  local eMinions = SDK.ObjectManager:GetEnemyMinions(self.E.range)
  for i = 1, #eMinions do
    local minion = eMinions[i]

    if IsValid(minion) then
      if myHero.pos:DistanceTo(minion.pos) < 625 and Ready(_E) then
        local WDmg = getdmg("E", minion, myHero, 1)
        if (WDmg > minion.health) then
          Control.CastSpell(HK_E, minion.pos)
          lastE = GetTickCount()
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

      -- R
      if  lastR + 750 < GetTickCount() and Ready(_R)
        and distanceSqr < self.R.range^2 then
        local numAround = self:GetTargetInRange(480, hero)
        if self.Menu.auto.R:Value() and numAround >= self.Menu.auto.minAutoR:Value() then
          Control.CastSpell(HK_R, hero)
          lastR = GetTickCount()
        end
      end
      -- R END

      -- W
      local target = hero
      if self.Menu.combo.W:Value() and lastW + 80 < GetTickCount() and Ready(_W)
        and distanceSqr < self.W.range^2
      then
        self:CastW(target)
        -- tento dar o E depois do W no mesmo alvo
        DelayAction(
          function()
            Control.CastSpell(HK_E, target)
            lastE = GetTickCount()
          end, 1
        )
      end
      -- W END

      -- Q
      if self.Menu.auto.Q:Value() and distanceSqr < self.Menu.auto.maxRange:Value() ^2
        and Ready(_Q) and lastQ + 60 < GetTickCount()
        and distanceSqr < self.Q.range^2 then
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
      -- Q end


      -- AntiDash thanks D3ftsu
      if self.Menu.auto.AntiDash[hero.charName]
        and self.Menu.auto.AntiDash[hero.charName]:Value()
        and distanceSqr < self.Q.range^2
        and distanceSqr < self.E.range^2
        and hero.pathing.isDashing
        and hero.pathing.dashSpeed>0
        and lastE+60 < GetTickCount()
        and lastQ+60 < GetTickCount()
        and Ready(_Q)
        and Ready(_E)
      then
        Control.CastSpell(HK_E, hero)
        lastE = GetTickCount()
        -- tento dar o Q depois do E no mesmo alvo
        DelayAction(
          function()
            Control.CastSpell(HK_Q, hero)
            lastQ = GetTickCount()
          end, 0.75
        )
        return
      end
      -- e se tiver buff
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
  for i = 1, #Enemys do
    local target = Enemys[i]
    if IsValid(target)  and myHero.pos:DistanceTo(target.pos) <= 580 then
      local TargetHp = target.health/target.maxHealth

      if TargetHp <= self.Menu.combo.ignitehp:Value()/100 then
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

function Brand:CastW(target)
  if lastW + 60 < GetTickCount() and Ready(_W)  and IsValid(target) then
    if self.Menu.settings.predW:Value() then
      -- W com pred
      local Pred = GetGamsteronPrediction(target, self.W, myHero)
      if Pred.Hitchance >= self.Menu.settings.predictionW:Value() then
        Control.CastSpell(HK_W, Pred.CastPosition)
        lastW = GetTickCount()
      end
    else
      -- W sem pred
      Control.CastSpell(HK_W, target)
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
