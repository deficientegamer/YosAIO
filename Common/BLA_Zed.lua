require("BLA_Common") -- load common functions
require('GamsteronPrediction')
require('PussyDamageLib')

local LocalTableSort        = table.sort
local LocalStringFind       = string.find
local inUlt = false

class "Zed"

function Zed:__init()

  self.Q = {Type = _G.SPELLTYPE_LINE,  range = 900, speed=900}
  self.W = {Type = _G.SPELLTYPE_LINE, range = 650, radius=1950, speed=1750}
  self.E = {Type = _G.SPELLTYPE_CIRCLE, radius = 290}
  self.R = {Type = _G.SPELLTYPE_LINE, range = 625}

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

function Zed:LoadMenu()

  self.Menu = MenuElement({type = MENU, id = "BLAZed", name = "SoldierAIO Zed RC 0.1"})

  self.Menu:MenuElement({type = MENU, id = "combo", name = "Combo"})
  self.Menu.combo:MenuElement({id = "maxComboEnemies", name = "Max Enemies near target in combo", value = 1, min = 0, max = 4, step = 1})
  self.Menu.combo:MenuElement({id = "maxComboEnemiesDistance", name = "Distance to Max Enemies", value = 400, min = 0, max = 2200, step = 1})
  self.Menu.combo:MenuElement({id = "comboPrediction", name = "HitChance (1=normal,2=high)", value = 2, min = 1, max = 2, step = 1})

  self.Menu.combo:MenuElement({id = "Q", name = "Q", value = true})

  self.Menu.combo:MenuElement({id = "W", name = "W", value = true})

  self.Menu.combo:MenuElement({id = "E", name = "E", value = true})
  --self.Menu.combo:MenuElement({id = "EProtect", name = "E to protect ally", value = true})
  --self.Menu.combo:MenuElement({id = "maxE", name = "E max distance in Combo", value = 735, min = 0, max = 775, step = 1})


  self.Menu.combo:MenuElement({id = "R", name = "R", value = true})
  -- self.Menu.combo:MenuElement({id = "RVeryNear", name = "RW - whenever very and < health", value = true})
  -- self.Menu.combo:MenuElement({id = "RmaxEnemies", name = "R - whenever many enemies", value = true})
  -- self.Menu.combo:MenuElement({id = "RAfterE", name = "R - whenever after E in wall", value = true})

  --self.Menu.combo:MenuElement({type = MENU, id = "comboUltConfig", name = "Custom Ult"})
  --self.Menu.combo.comboUltConfig:MenuElement({id = "veryNear", name = "Very Near Consider", value = 50, min = 0, max = 120, step = 1})
  --  self.Menu.combo.comboUltConfig:MenuElement({id = "maxEnemies", name = "Many Enemies For Clear", value = 3, min = 1, max = 5, step = 1})
  --self.Menu.combo.comboUltConfig:MenuElement({id = "distancieCountEnemies", name = "Distance Enemies For Count", value = 440, min = 50, max = 1000, step = 1})
  --self.Menu.combo.comboUltConfig:MenuElement({id = "maxDistance", name = "Max Distance", value = 220, min = 0, max = 1000, step = 1})


  self.Menu:MenuElement({type = MENU, id = "harass", name = "Harass"})
  self.Menu.harass:MenuElement({id = "Q", name = "Q", value = true})
  self.Menu.harass:MenuElement({id = "W", name = "W", value = true})
  self.Menu.harass:MenuElement({id = "E", name = "E", value = true})
  self.Menu.harass:MenuElement({id = "prediction", name = "HitChance (1=normal,2=high)", value = 2, min = 1, max = 2, step = 1})

  self.Menu:MenuElement({type = MENU, id = "clear", name = "Clear"})
  self.Menu.clear:MenuElement({id = "Q", name = "Q", value = true})
  self.Menu.clear:MenuElement({id = "W", name = "W", value = true})
  self.Menu.clear:MenuElement({id = "E", name = "E", value = true})
  self.Menu.clear:MenuElement({id = "prediction", name = "HitChance (1=normal,2=high)", value = 1, min = 1, max = 2, step = 1})

  self.Menu:MenuElement({type = MENU, id = "lastHit", name = "LastHit"})
  self.Menu.lastHit:MenuElement({id = "Q", name = "Q", value = true})
  
  self.Menu.lastHit:MenuElement({id = "prediction", name = "HitChance (1=normal,2=high)", value = 2, min = 1, max = 2, step = 1})

  self.Menu:MenuElement({type = MENU, id = "escape", name = "Escape (use Orb Key)"})
  self.Menu.escape:MenuElement({id = "W", name = "W if my health * 1.4 <", value = true})


  self.Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawing"})
  self.Menu.Drawing:MenuElement({id = "Q", name = "Draw [Q] Range", value = true})
  self.Menu.Drawing:MenuElement({id = "W", name = "Draw [W] Range", value = true})
  self.Menu.Drawing:MenuElement({id = "R", name = "Draw [R] Range", value = true})

end


function Zed:Tick()
  if myHero.dead or Game.IsChatOpen() or (ExtLibEvade and ExtLibEvade.Evading == true) then
    return
  end


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
    target = self:GetTarget(600)
    if self.Menu.escape.W:Value()  and lastW +240 and Ready(_W)
      and IsValid(target) and target.health > myHero.health then
      Control.CastSpell(HK_W, myHero.pos-640)
      lastW = GetTickCount()
    end
    -- W End
  end

end

function Zed:Combo()

  local target = nil

  target = self:GetTarget(self.Menu.combo.maxComboEnemiesDistance:Value())
  if lastR + 8000 < GetTickCount() then
    inUlt=false
  end

  for i = 1, #Enemys do
    if IsValid(target)  then

      local numAround = self:GetTargetInRange(self.Menu.combo.maxComboEnemiesDistance:Value(), target)

      if numAround <= self.Menu.combo.maxComboEnemies:Value() then

        target = self:GetTarget(650)
        -- W Start

        if IsValid(target) and self.Menu.combo.W:Value()  and lastW +140  < GetTickCount() and Ready(_W)
         then

          Control.CastSpell(HK_W,target.pos)
          lastW = GetTickCount()
        end
        -- W End

        -- R Start
        target = self:GetTarget(625)
        if inUlt==false and IsValid(target) and lastW +600  < GetTickCount() and Ready(_R)  and self.Menu.combo.R:Value()
        then


          local Pred = GetGamsteronPrediction(target, self.R, myHero)
          -- soltar R quando tem no maximo x enemies
          if Pred.Hitchance >=   self.Menu.combo.comboPrediction:Value() then
       
            Control.CastSpell(HK_R, Pred.CastPosition)
            lastR = GetTickCount()
            inUlt=true
			print("ult")
          end

        end
      end

      -- R End



      -- E Start
      target = self:GetTarget(80)

      if self.Menu.combo.E:Value()  and lastE +30  < GetTickCount() and Ready(_E) and IsValid(target) then

        local distanceSqr = GetDistanceSquared(myHero.pos, target.pos)
        local Pred = GetGamsteronPrediction(target, self.E, myHero)
        if Pred.Hitchance >=  self.Menu.combo.comboPrediction:Value()  then
          Control.CastSpell(HK_E,Pred.CastPosition)
          lastE = GetTickCount()
        end
      end
      -- E End


      -- Q Start
      target = self:GetTarget(900)
	
      if IsValid(target) and Ready(_Q) and lastQ + 60 < GetTickCount() then
        if self.Menu.combo.Q:Value()  then
		    print("teste")
          local Pred = GetGamsteronPrediction(target, self.Q, myHero)
          if Pred.Hitchance >=   self.Menu.combo.comboPrediction:Value() then
		      print("teste2")
            Control.CastSpell(HK_Q, Pred.CastPosition)
            lastQ = GetTickCount()
            return
          end
        end
      end
      -- Q End
    end
  end

end


function Zed:Harass()


  local target = nil
    target = self:GetTarget(625)
  -- W Start
    if self.Menu.harass.W:Value()  and lastW +140  < GetTickCount() and Ready(_W) then
      Control.CastSpell(HK_W,target)
      lastW = GetTickCount()
    end
    -- W End
	
	target = self:GetTarget(90)
	if self.Menu.harass.E:Value()  and lastE +30  < GetTickCount() and Ready(_E) and IsValid(target) then

      local distanceSqr = GetDistanceSquared(myHero.pos, target.pos)
      local Pred = GetGamsteronPrediction(target, self.E, myHero)
      if Pred.Hitchance >=   self.Menu.harass.prediction:Value()  then
        Control.CastSpell(HK_E,Pred.CastPosition)
        lastE = GetTickCount()
      end
    end

  -- Q Start
  target = self:GetTarget(900)

  if self.Menu.harass.Q:Value()  and IsValid(target) and Ready(_Q) and lastQ + 60 < GetTickCount() then

    local Pred = GetGamsteronPrediction(target, self.Q, myHero)
    if Pred.Hitchance >=   self.Menu.harass.prediction:Value() then
      Control.CastSpell(HK_Q, Pred.CastPosition)
      lastQ = GetTickCount()
      return

    end
  end
  -- Q End

end

function Zed:Clear()


  local eMinions = SDK.ObjectManager:GetEnemyMinions(650)
  for i = 1, #eMinions do
    local target = eMinions[i]


    -- W Start
    if self.Menu.clear.W:Value()  and lastW +140  < GetTickCount() and Ready(_W) then
      Control.CastSpell(HK_W,target)
      lastW = GetTickCount()
    end
    -- W End

    if self.Menu.clear.E:Value()  and lastE +30  < GetTickCount() and Ready(_E) and IsValid(target) then

      local distanceSqr = GetDistanceSquared(myHero.pos, target.pos)
      local Pred = GetGamsteronPrediction(target, self.E, myHero)
      if Pred.Hitchance >=   self.Menu.clear.prediction:Value()  then
        Control.CastSpell(HK_E,Pred.CastPosition)
        lastE = GetTickCount()
      end
    end


    
  end

 local eMinions = SDK.ObjectManager:GetEnemyMinions(900)
  for i = 1, #eMinions do
    local target = eMinions[i]

-- Q
    if self.Menu.clear.Q:Value()  and IsValid(target) and Ready(_Q) and lastQ + 60 < GetTickCount() then
      if self.Menu.combo.Q:Value()  then
        local Pred = GetGamsteronPrediction(target, self.Q, myHero)
        if Pred.Hitchance >= self.Menu.clear.prediction:Value() then
          Control.CastSpell(HK_Q, Pred.CastPosition)
          lastQ = GetTickCount()
          return
        end
      end
    end
    -- Q End
	
	end

end


function Zed:LastHit()


  local eMinions = SDK.ObjectManager:GetEnemyMinions(650)
  for i = 1, #eMinions do
    local target = eMinions[i]

    -- Q
    if self.Menu.lastHit.Q:Value()  and IsValid(target) and Ready(_Q) and lastQ + 60 < GetTickCount() then
      if self.Menu.combo.Q:Value()  then
        local Pred = GetGamsteronPrediction(target, self.Q, myHero)
        if Pred.Hitchance >= self.Menu.lastHit.prediction:Value() then
          Control.CastSpell(HK_Q, Pred.CastPosition)
          lastQ = GetTickCount()
          return
        end
      end
    end
    -- Q End
  end

end


function Zed:Draw()
  if myHero.dead then return  end
  if self.Menu.Drawing.R:Value() and Ready(_R) then
    Draw.Circle(myHero, 625, 1, Draw.Color(255, 225, 255, 10))
  end
  if self.Menu.Drawing.Q:Value() and Ready(_Q) then
    Draw.Circle(myHero, 900, 1, Draw.Color(225, 225, 0, 10))
  end
  if self.Menu.Drawing.W:Value() and Ready(_W) then
    Draw.Circle(myHero, 650, 1, Draw.Color(225, 225, 0, 10))
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

function Zed:GetTarget(range, list)
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

function Zed:GetTargetInRange(range, target)
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


function Zed:GetHeroInRange(range, target)

  for i = 1, #Enemys do
    local hero = Enemys[i]
    if IsValid(hero) then
      if GetDistanceSquared(target.pos, hero.pos) < range * range then
        return hero
      end
    end
  end
end


function Zed:HeroesAround(range, pos, team)
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



Zed()
