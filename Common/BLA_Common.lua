 GameHeroCount     = Game.HeroCount
 GameHero          = Game.Hero
 TableInsert       = _G.table.insert

 Orb               = _G.SDK.Orbwalker
 TargetSelector    = _G.SDK.TargetSelector


 ORBWALKER_MODE_NONE = -1
 ORBWALKER_MODE_COMBO = 0
 ORBWALKER_MODE_HARASS = 1
 ORBWALKER_MODE_LANECLEAR = 2
 ORBWALKER_MODE_JUNGLECLEAR = 3
 ORBWALKER_MODE_LASTHIT = 4
 ORBWALKER_MODE_FLEE = 5

 HITCHANCE_NORMAL = 2
 HITCHANCE_HIGH = 3
 HITCHANCE_IMMOBILE = 4

 TEAM_JUNGLE = 300
 TEAM_ALLY = myHero.team
 TEAM_ENEMY = 300 - myHero.team


 lastQ = 0
 lastW = 0
 lastE = 0
 lastEQ = 0
 lastMove = 0
 lastR = 0
 lastIG = 0
 lastEX = 0

 Enemys =   {}
 Allys  =   {}


function EnableOrb(bool)
  if _G.EOWLoaded then
    EOW:SetMovements(bool)
    EOW:SetAttacks(bool)
  elseif _G.SDK and _G.SDK.Orbwalker then
    _G.SDK.Orbwalker:SetMovement(bool)
    _G.SDK.Orbwalker:SetAttack(bool)
  else
    GOS.BlockMovement = not bool
    GOS.BlockAttack = not bool
  end
end

function GetDistanceSquared(vec1, vec2)
   dx = vec1.x - vec2.x
   dy = (vec1.z or vec1.y) - (vec2.z or vec2.y)
  return dx * dx + dy * dy
end

function IsValid(unit)
  return  unit
    and unit.valid
    and unit.isTargetable
    and unit.alive
    and unit.visible
    and unit.networkID
    and unit.health > 0
    and not unit.dead
end

function Ready(spell)
  return myHero:GetSpellData(spell).currentCd == 0
    and myHero:GetSpellData(spell).level > 0
    and myHero:GetSpellData(spell).mana <= myHero.mana
    and Game.CanUseSpell(spell) == 0
end

function OnAllyHeroLoad(cb)
  for i = 1, GameHeroCount() do
     obj = GameHero(i)
    if obj.isAlly then
      cb(obj)
    end
  end
end

function OnEnemyHeroLoad(cb)
  for i = 1, GameHeroCount() do
     obj = GameHero(i)
    if obj.isEnemy then
      cb(obj)
    end
  end
end
