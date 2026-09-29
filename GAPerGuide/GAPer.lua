
local ADDON_NAME = ...
GAPerGuideDB = type(GAPerGuideDB)=="table" and GAPerGuideDB or {}

local DATA_VERSION = "v0.4.1 - 2026-09-28 - centered GG minimap button"
local UI

local L = {
  ru = {
    title="GAPer FOREVER", character="Персонаж", macros="Макросы", talents="Таланты",
    play="Как играть", updates="Обновления", language="Язык",
    russian="Русский", english="English", detected="Определено автоматически",
    class="Класс", level="Уровень", build="Стиль игры", current="Сейчас",
    next="Следующий уровень", create="Создать / обновить макросы",
    combat="Нельзя менять макросы во время боя.", created="Макросы GAPer обновлены.",
    only="Сейчас поддерживаются Паладин и Охотник.", choose="Выберите стиль игры:",
    paladin="Паладин", hunter="Охотник",
    ret="Воздаяние", prot="Защита", holy="Свет",
    bm="Повелитель зверей", mm="Стрельба", surv="Выживание",
    solo="Обычный моб", strong="Сильный моб", dungeon="Подземелье / пачка", boss="Босс",
    tip="Подсказка", source="База", client="Язык клиента WoW",
    macroLang="Названия заклинаний в макросах берутся под язык клиента WoW.",
    notYet="Эта способность ещё не должна быть доступна на вашем уровне.",
    beta="Бета меняется. GAPer показывает проверенную базу для текущего уровня 20; новые капы будут добавляться обновлениями.",
    legacy="План ниже без дополнительных очков Legacy/Talented.",
    autoLevel="GAPer сам читает ваш уровень и меняет подсказки.",
    update1="28.09.2026 — первая версия GAPer: Paladin + Hunter, RU/EN, автоуровень, макросы, таланты и ротации.",
    update2="24.09.2026 — учтён beta build 1.60.1.70009: Improved Holy Strike удалён; Holy Strike усилен/обновлён.",
    update3="Hunter 10-20: актуализирован ранний маршрут Deadly Aspects -> Focused Fire -> Lethal Attacks.",
  },
  en = {
    title="GAPer FOREVER", character="Character", macros="Macros", talents="Talents",
    play="How to Play", updates="Updates", language="Language",
    russian="Русский", english="English", detected="Auto-detected",
    class="Class", level="Level", build="Playstyle", current="Now",
    next="Next level", create="Create / update macros",
    combat="Macros cannot be changed in combat.", created="GAPer macros updated.",
    only="Paladin and Hunter are currently supported.", choose="Choose your playstyle:",
    paladin="Paladin", hunter="Hunter",
    ret="Retribution", prot="Protection", holy="Holy",
    bm="Beast Mastery", mm="Marksmanship", surv="Survival",
    solo="Normal mob", strong="Strong mob", dungeon="Dungeon / pack", boss="Boss",
    tip="Tip", source="Database", client="WoW client language",
    macroLang="Spell names inside macros follow the WoW client language.",
    notYet="This ability should not be available at your current level yet.",
    beta="Beta changes often. GAPer currently uses verified level-20 data; later caps will be added in updates.",
    legacy="The talent path below assumes no extra Legacy/Talented points.",
    autoLevel="GAPer reads your level automatically and changes the advice.",
    update1="2026-09-28 — first GAPer build: Paladin + Hunter, RU/EN, auto level, macros, talents and rotations.",
    update2="2026-09-24 — beta build 1.60.1.70009 reflected: Improved Holy Strike removed; Holy Strike updated.",
    update3="Hunter 10-20: early path updated to Deadly Aspects -> Focused Fire -> Lethal Attacks.",
  }
}

local specs = {
  PALADIN = {
    {id="ret", ru="Воздаяние", en="Retribution"},
    {id="prot", ru="Защита", en="Protection"},
    {id="holy", ru="Свет", en="Holy"},
  },
  HUNTER = {
    {id="bm", ru="Повелитель зверей", en="Beast Mastery"},
    {id="mm", ru="Стрельба", en="Marksmanship"},
    {id="surv", ru="Выживание", en="Survival"},
  }
}

-- Macro spell names are intentionally separated from UI localization:
-- /cast must use the WoW CLIENT locale, not the language chosen for GAPer.
local spellNames = {
  PALADIN = {
    holyStrike={en="Holy Strike", ru="Удар Света"},
    judgement={en="Judgement", ru="Правосудие"},
    hammer={en="Hammer of Justice", ru="Молот правосудия"},
    consecration={en="Consecration", ru="Освящение"},
    sealR={en="Seal of Righteousness", ru="Печать праведности"},
    sealC={en="Seal of Command", ru="Печать повиновения"},
    sealF={en="Seal of Fury", ru="Печать ярости"},
    holyLight={en="Holy Light", ru="Свет небес"},
    flash={en="Flash of Light", ru="Вспышка Света"},
    divineProtection={en="Divine Protection", ru="Божественная защита"},
    divineShield={en="Divine Shield", ru="Божественный щит"},
    lay={en="Lay on Hands", ru="Возложение рук"},
    exorcism={en="Exorcism", ru="Экзорцизм"},
  },
  HUNTER = {
    mark={en="Hunter's Mark", ru="Метка охотника"},
    serpent={en="Serpent Sting", ru="Укус змеи"},
    arcane={en="Arcane Shot", ru="Чародейский выстрел"},
    aimed={en="Aimed Shot", ru="Прицельный выстрел"},
    multi={en="Multi-Shot", ru="Залп"},
    raptor={en="Raptor Strike", ru="Удар ящера"},
  }
}

local macroDefs = {
  PALADIN = {
    {name="GAP_Holy", key="holyStrike", min=6, extra="/startattack"},
    {name="GAP_Judge", key="judgement", min=4},
    {name="GAP_Stun", key="hammer", min=8},
    {name="GAP_AOE", key="consecration", min=20},
    {name="GAP_SealR", key="sealR", min=1},
    {name="GAP_SealC", key="sealC", min=20},
    {name="GAP_SealF", key="sealF", min=10},
    {name="GAP_Heal", key="holyLight", min=1},
    {name="GAP_Flash", key="flash", min=20},
    {name="GAP_DP", key="divineProtection", min=6},
    {name="GAP_Bubble", key="divineShield", min=34},
    {name="GAP_LoH", key="lay", min=10},
    {name="GAP_Exorc", key="exorcism", min=20},
  },
  HUNTER = {
    {name="GAP_Pet", raw="#showtooltip\n/petattack"},
    {name="GAP_Mark", key="mark", min=6},
    {name="GAP_Sting", key="serpent", min=4},
    {name="GAP_Arcane", key="arcane", min=6},
    {name="GAP_Aimed", key="aimed", min=10},
    {name="GAP_Multi", key="multi", min=18},
    {name="GAP_Raptor", key="raptor", min=1, extra="/startattack"},
  }
}

local hunterTalents = {
 [10]="Deadly Aspects 1/5",[11]="Deadly Aspects 2/5",[12]="Deadly Aspects 3/5",
 [13]="Deadly Aspects 4/5",[14]="Deadly Aspects 5/5",[15]="Focused Fire 1/2",
 [16]="Focused Fire 2/2",[17]="Lethal Attacks 1/5",[18]="Lethal Attacks 2/5",
 [19]="Lethal Attacks 3/5",[20]="Lethal Attacks 4/5",
}
local palRetTalents = {
 [10]="Deflection 1/5",[11]="Deflection 2/5",[12]="Deflection 3/5",[13]="Deflection 4/5",[14]="Deflection 5/5",
 [15]="Improved Judgement 1/2",[16]="Improved Judgement 2/2",
 [17]="Conviction 1/5",[18]="Conviction 2/5",[19]="Conviction 3/5",[20]="Conviction 4/5",
}
local palProtTalents = {
 [10]="Benediction 1/5",[11]="Benediction 2/5",[12]="Benediction 3/5",[13]="Benediction 4/5",[14]="Benediction 5/5",
 [15]="Improved Judgement 1/2",[16]="Improved Judgement 2/2",
 [17]="Holy Conduit 1/2",[18]="Holy Conduit 2/2",[19]="Pursuit of Justice 1/2",[20]="Deflection 1/5",
}
local palHolyTalents = {
 [10]="Divine Intellect 1/5",[11]="Divine Intellect 2/5",[12]="Divine Intellect 3/5",[13]="Divine Intellect 4/5",[14]="Divine Intellect 5/5",
 [15]="Improved Seals 1/3",[16]="Improved Seals 2/3",[17]="Improved Seals 3/3",
 [18]="Healing Light 1/3",[19]="Healing Light 2/3",[20]="Reverence 1/3",
}

local function uiLang()
  GAPerGuideDB.lang = GAPerGuideDB.lang or ((GetLocale and GetLocale()=="ruRU") and "ru" or "en")
  return GAPerGuideDB.lang
end
local function T(k) return (L[uiLang()] and L[uiLang()][k]) or k end
local function clientLang()
  return (GetLocale and GetLocale()=="ruRU") and "ru" or "en"
end
-- UI language changes display text. Macro cast text must use the actual WoW client locale.
-- A separate preview displays the UI-language translation without breaking /cast.
local function spellbookName(english, russian)
  -- When a spell has been learned, take its name from the player's own spellbook.
  -- Avoid assuming translations of custom Forever spells are always correct.
  if not GetSpellBookItemName then return nil end
  local book = BOOKTYPE_SPELL or "spell"
  for slot=1,300 do
    local name = GetSpellBookItemName(slot,book)
    if name and (name==english or name==russian) then return name end
  end
  return nil
end


local function normalizeSpellName(v)
  if not v then return nil end
  v=tostring(v):lower()
  v=v:gsub("%s*%b()%s*$","")   -- strip trailing (Rank ...)
  v=v:gsub("^%s+",""):gsub("%s+$","")
  return v
end

local function spellNameMatches(liveName, english, russian)
  local n=normalizeSpellName(liveName)
  if not n then return false end
  local e=normalizeSpellName(english)
  local r=normalizeSpellName(russian)
  return n==e or n==r
end

local function spellbookInfo(english, russian)
  -- Forever beta has moved between old and new spellbook APIs.
  -- Try every supported path and return the exact localized spellbook name/icon.
  local book = BOOKTYPE_SPELL or "spell"

  -- Legacy API path.
  if GetSpellBookItemName then
    for slot=1,500 do
      local name,subName = GetSpellBookItemName(slot,book)
      if name and spellNameMatches(name,english,russian) then
        local texture=nil
        if GetSpellBookItemTexture then texture=GetSpellBookItemTexture(slot,book) end
        if not texture and GetSpellTexture then texture=GetSpellTexture(name) end
        return name,texture,slot
      end
    end
  end

  -- Newer C_SpellBook path.
  if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetSpellBookSkillLineInfo then
    local ok,num = pcall(C_SpellBook.GetNumSpellBookSkillLines)
    if ok and num then
      for skillLineIndex=1,num do
        local ok2,info = pcall(C_SpellBook.GetSpellBookSkillLineInfo, skillLineIndex)
        if ok2 and info and info.itemIndexOffset and info.numSpellBookItems then
          local first=info.itemIndexOffset+1
          local last=info.itemIndexOffset+info.numSpellBookItems
          for slot=first,last do
            local itemInfo=nil
            if C_SpellBook.GetSpellBookItemInfo then
              local ok3,res=pcall(C_SpellBook.GetSpellBookItemInfo,slot,Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0)
              if ok3 then itemInfo=res end
            end
            local name=nil
            local spellID=itemInfo and (itemInfo.spellID or itemInfo.actionID)
            if spellID and C_Spell and C_Spell.GetSpellName then
              local ok4,res=pcall(C_Spell.GetSpellName,spellID)
              if ok4 then name=res end
            end
            if not name and C_SpellBook.GetSpellBookItemName then
              local ok5,res=pcall(C_SpellBook.GetSpellBookItemName,slot,Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0)
              if ok5 then name=res end
            end
            if name and spellNameMatches(name,english,russian) then
              local texture=nil
              if spellID and C_Spell and C_Spell.GetSpellTexture then
                local ok6,res=pcall(C_Spell.GetSpellTexture,spellID)
                if ok6 then texture=res end
              end
              return name,texture,slot,spellID
            end
          end
        end
      end
    end
  end

  return nil,nil,nil,nil
end

local function dumpSpellbook()
  local seen={}
  local out={}
  local book=BOOKTYPE_SPELL or "spell"
  if GetSpellBookItemName then
    for slot=1,500 do
      local name=GetSpellBookItemName(slot,book)
      if name and not seen[name] then
        seen[name]=true
        out[#out+1]=name
      end
    end
  end
  if #out==0 and C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetSpellBookSkillLineInfo then
    local ok,num=pcall(C_SpellBook.GetNumSpellBookSkillLines)
    if ok and num then
      for skillLineIndex=1,num do
        local ok2,info=pcall(C_SpellBook.GetSpellBookSkillLineInfo,skillLineIndex)
        if ok2 and info and info.itemIndexOffset and info.numSpellBookItems then
          for slot=info.itemIndexOffset+1,info.itemIndexOffset+info.numSpellBookItems do
            local itemInfo=nil
            if C_SpellBook.GetSpellBookItemInfo then
              local ok3,res=pcall(C_SpellBook.GetSpellBookItemInfo,slot,Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0)
              if ok3 then itemInfo=res end
            end
            local spellID=itemInfo and (itemInfo.spellID or itemInfo.actionID)
            local name=nil
            if spellID and C_Spell and C_Spell.GetSpellName then
              local ok4,res=pcall(C_Spell.GetSpellName,spellID)
              if ok4 then name=res end
            end
            if name and not seen[name] then
              seen[name]=true
              out[#out+1]=name
            end
          end
        end
      end
    end
  end
  table.sort(out)
  print("|cffffd100GAPer spellbook scan ("..#out.."):|r")
  for _,name in ipairs(out) do print(name) end
end

local function defSpellInfo(class,def)
  if def.raw then return true,nil,nil end
  local names=spellNames[class] and spellNames[class][def.key]
  if not names then return false,nil,nil end
  local name,texture,slot=spellbookInfo(names.en,names.ru)
  return name~=nil,name,texture
end

local function classInfo()
  local localized, class = UnitClass("player")
  return localized or "?", class or "UNKNOWN"
end
local function levelInfo()
  return UnitLevel("player") or 1
end
local function selectedSpec(class)
  GAPerGuideDB.spec = GAPerGuideDB.spec or {}
  if not GAPerGuideDB.spec[class] then
    GAPerGuideDB.spec[class] = (class=="PALADIN" and "ret") or (class=="HUNTER" and "bm") or ""
  end
  return GAPerGuideDB.spec[class]
end

local function spellLabel(class, key, lang)
  local t = spellNames[class] and spellNames[class][key]
  if not t then return key end
  return t[lang] or t.en
end

local function makeMacroBody(class, def)
  if def.raw then return def.raw,nil end
  local learned,actualName,texture=defSpellInfo(class,def)
  if not learned then return nil,nil end
  local body="#showtooltip "..actualName
  if def.extra then body=body.."\n"..def.extra end
  body=body.."\n/cast "..actualName
  return body,texture
end

local function upsertMacro(name, body, texture)
  local idx = GetMacroIndexByName and GetMacroIndexByName(name) or 0
  local icon = texture or 134400
  if idx and idx > 0 then
    EditMacro(idx, name, icon, body, 1)
  else
    CreateMacro(name, icon, body, 1)
  end
end

local function createMacros()
  if InCombatLockdown and InCombatLockdown() then
    print("|cffff5555GAPer:|r "..T("combat")); return
  end
  local _,class=classInfo()
  if class~="PALADIN" and class~="HUNTER" then
    print("|cffffcc00GAPer:|r "..T("only")); return
  end
  local lvl=levelInfo()
  local created,trainer=0,0
  for _,def in ipairs(macroDefs[class]) do
    if def.raw then
      local ok,err=pcall(upsertMacro,def.name,def.raw,134400)
      if ok then created=created+1 else print("GAPer "..def.name..": "..tostring(err)) end
    elseif (not def.min) or lvl>=def.min then
      local learned,actualName,texture=defSpellInfo(class,def)
      if learned then
        local body=makeMacroBody(class,def)
        local ok,err=pcall(upsertMacro,def.name,body,texture)
        if ok then created=created+1 else print("GAPer "..def.name..": "..tostring(err)) end
      else
        trainer=trainer+1
        local display=spellLabel(class,def.key,clientLang())
        if uiLang()=="ru" then
          print("|cffffcc00GAPer:|r "..display.." - не найдено в книге заклинаний. Если уровень уже подходит, проверь тренера.")
        else
          print("|cffffcc00GAPer:|r "..display.." - not found in your spellbook. If your level is high enough, check your trainer.")
        end
      end
    end
  end
  if uiLang()=="ru" then
    print("|cff55ff55GAPer:|r создано/обновлено: "..created.."; нужно проверить у тренера: "..trainer)
    if created==0 then print("|cffff5555GAPer:|r Ничего не найдено. Введи /gpg scan - я покажу точные названия из твоей книги заклинаний.") end
  else
    print("|cff55ff55GAPer:|r created/updated: "..created.."; trainer checks: "..trainer)
    if created==0 then print("|cffff5555GAPer:|r Nothing matched. Type /gpg scan to print exact spellbook names.") end
  end
end

local function talentTable(class, spec)
  if class=="HUNTER" then return hunterTalents end
  if class=="PALADIN" and spec=="ret" then return palRetTalents end
  if class=="PALADIN" and spec=="prot" then return palProtTalents end
  if class=="PALADIN" and spec=="holy" then return palHolyTalents end
end

local function localizedTalentName(s)
  if uiLang()=="en" then return s end
  local repl = {
    ["Deadly Aspects"]="Смертоносные аспекты", ["Focused Fire"]="Сосредоточенный огонь",
    ["Lethal Attacks"]="Смертельные атаки", ["Deflection"]="Отражение",
    ["Improved Judgement"]="Улучшенное правосудие", ["Conviction"]="Приговор",
    ["Benediction"]="Благословение", ["Holy Conduit"]="Священный проводник",
    ["Pursuit of Justice"]="Погоня за справедливостью", ["Divine Intellect"]="Божественный интеллект",
    ["Improved Seals"]="Улучшенные печати", ["Healing Light"]="Исцеляющий Свет",
    ["Reverence"]="Благоговение",
  }
  for en,ru in pairs(repl) do s=s:gsub(en,ru) end
  return s
end

local function getTalentText(class, spec, lvl)
  local tt=talentTable(class,spec)
  if not tt then return "" end
  local out={}
  if lvl < 10 then
    table.insert(out, uiLang()=="ru" and "Таланты откроются с 10 уровня." or "Talents unlock at level 10.")
  else
    local cur=tt[math.min(lvl,20)]
    if cur then
      table.insert(out, "|cffffd100"..T("current")..":|r "..localizedTalentName(cur))
    else
      table.insert(out, uiLang()=="ru" and "Для уровней выше текущего beta-cap база будет добавлена после открытия следующего этапа." or "Levels above the current beta cap will be added when the next bracket opens.")
    end
    local nxt=tt[lvl+1]
    if nxt then table.insert(out, "\n|cff88ccff"..T("next")..":|r "..localizedTalentName(nxt)) end
    table.insert(out, "\n\n"..T("legacy"))
    table.insert(out, "\n\n|cffffd10010-20:|r")
    for n=10,20 do
      local mark = n<=lvl and "|cff55ff55+|r" or "-"
      table.insert(out, string.format("\n%s %d — %s", mark,n,localizedTalentName(tt[n])))
    end
  end
  return table.concat(out)
end

local function playText(class,spec,lvl)
  local ru=uiLang()=="ru"

  if class=="PALADIN" then
    if spec=="ret" then
      if ru then
        return [[|cffffd100ПЕРЕД БОЕМ|r
- Держи активную ауру и Благословение могущества.
- Держи Печать праведности. Печать не нужно обновлять после каждого Правосудия в Forever.

|cffffd100ОБЫЧНЫЙ МОБ|r
1. Если печати нет - нажми 5.
2. Подойди к цели.
3. Нажми 2 (Правосудие).
4. Нажми 1 (Удар Света).
5. Дальше автоатака; 1 и 2 нажимай по откату.
6. Не трать Освящение на одного слабого моба.

|cffffd100СИЛЬНЫЙ МОБ / ЭЛИТА|r
- Для длинного боя сначала Правосудие от Печати воина Света, потом верни Печать праведности.
- 1 и 2 по откату.
- 3 (Молот правосудия) береги под опасное заклинание, лечение или момент, когда надо отойти.
- Если здоровье около 45-50%, лучше оглушить цель и спокойно вылечиться, а не ждать почти смерти.

|cffffd100ПОДЗЕМЕЛЬЕ - ОДНА ЦЕЛЬ|r
- Дай танку начать бой.
- 2 -> 1 по откату.
- На длинной цели используй дебафф от Печати воина Света.
- 3 не трать просто ради урона: это твой контроль опасного моба.

|cffffd100ПОДЗЕМЕЛЬЕ - ПАЧКА|r
- Дождись, пока танк соберёт мобов.
- С 20 уровня: 4 (Освящение), если несколько целей и хватает маны.
- Потом 2 и 1 по приоритетной цели.
- Если маны мало, пропускай Освящение.

|cffffd100КРИТИЧЕСКАЯ СИТУАЦИЯ|r
- 45-50% HP: 3 -> отойти/полечиться, если возможно.
- 25-35% HP: используй защитную способность и лечение.
- 10-20% HP: Возложение рук - аварийная кнопка.
- Не стой и не кастуй длинный хил под ударами нескольких мобов, если можно сначала оглушить/отойти.

|cffffd100МАНА|r
- Не цепляй следующего моба почти без маны.
- На одиночной цели экономь Освящение.
- После тяжёлой пачки лучше выпить воду, чем входить в следующий бой без ресурса.]]
      else
        return [[|cffffd100BEFORE COMBAT|r
- Keep an Aura and Blessing of Might active.
- Maintain Seal of Righteousness. Judgement no longer consumes your Seal in Forever.

|cffffd100NORMAL MOB|r
1. Press 5 if your Seal is missing.
2. Move into melee.
3. Press 2 (Judgement).
4. Press 1 (Holy Strike).
5. Auto-attack; use 1 and 2 on cooldown.
6. Do not spend Consecration on one weak mob.

|cffffd100STRONG MOB / ELITE|r
- On a long fight, open with Judgement of the Crusader, then return to Seal of Righteousness.
- Use 1 and 2 on cooldown.
- Save 3 (Hammer of Justice) for a dangerous cast, healing window, or escape.
- Around 45-50% HP, stun and heal rather than waiting until you are almost dead.

|cffffd100DUNGEON - SINGLE TARGET|r
- Let the tank engage first.
- Use 2 -> 1 on cooldown.
- On a long-lived target, use the Crusader debuff.
- Save 3 for dangerous enemies instead of using it only for damage.

|cffffd100DUNGEON - PACK|r
- Wait for the tank to gather enemies.
- At level 20: use 4 (Consecration) when several targets are stacked and mana allows.
- Then 2 and 1 on the priority target.
- Skip Consecration when mana is low.

|cffffd100EMERGENCY|r
- 45-50% HP: stun, create space, heal if possible.
- 25-35% HP: defensive + healing.
- 10-20% HP: Lay on Hands is the emergency button.
- Avoid hard-casting a long heal while several enemies are hitting you if you can stun or move first.

|cffffd100MANA|r
- Do not chain-pull at very low mana.
- Save Consecration on single targets.
- Drink after a hard pull instead of starting the next one empty.]]
      end

    elseif spec=="prot" then
      if ru then
        return [[|cffffd100ПЕРЕД БОЕМ|r
- До 16 уровня Protection ещё не имеет полного набора для удержания угрозы.
- С 16: включи Праведное неистовство и подходящую ауру.
- Для танкования держи Печать ярости.

|cffffd100ОБЫЧНЫЙ МОБ|r
- До 20 в открытом мире проще качаться с хорошим двуручным оружием.
- Печать -> 2 (Правосудие) -> 1 (Удар Света) -> автоатаки.

|cffffd100ПОДЗЕМЕЛЬЕ - ОДНА ЦЕЛЬ|r
- Печать ярости до пулла.
- 2 -> 1.
- Экзорцизм только против нежити/демонов.
- С 20: 4 (Освящение), если мана позволяет.

|cffffd100ПОДЗЕМЕЛЬЕ - ПАЧКА|r
1. Праведное неистовство должно быть включено.
2. Собери мобов на себе.
3. С 20: 4 (Освящение).
4. 2 по опасной цели.
5. 1 по откату.
- Кастеров стягивай через угол/LoS, если нужно.

|cffffd100ЕСЛИ ТЕРЯЕШЬ АГРО|r
- Переключись на моба, который ушёл с тебя.
- Правосудие + Удар Света.
- Не бегай за каждым мобом хаотично: старайся держать пачку в Освящении.

|cffffd100КРИТИЧЕСКАЯ СИТУАЦИЯ|r
- Молот правосудия на самого опасного моба.
- Защитная способность, когда входящий урон резко вырос.
- Возложение рук оставь на реальную аварию.
- Если хилер без маны, замедли темп и не делай следующий пулл.]]
      else
        return [[|cffffd100BEFORE COMBAT|r
- Protection does not have its full threat kit before level 16.
- At 16+: keep Righteous Fury and an appropriate Aura active.
- Maintain Seal of Fury while tanking.

|cffffd100NORMAL MOB|r
- Before 20, a strong 2H weapon is generally easier for world leveling.
- Seal -> 2 (Judgement) -> 1 (Holy Strike) -> auto attacks.

|cffffd100DUNGEON - SINGLE TARGET|r
- Seal of Fury before the pull.
- 2 -> 1.
- Exorcism only against Undead/Demons.
- At 20+: 4 (Consecration) if mana allows.

|cffffd100DUNGEON - PACK|r
1. Righteous Fury must be active.
2. Gather enemies on you.
3. At 20+: 4 (Consecration).
4. 2 on the dangerous target.
5. 1 on cooldown.
- Use line-of-sight to stack casters when needed.

|cffffd100IF YOU LOSE THREAT|r
- Target the enemy that left you.
- Judgement + Holy Strike.
- Keep the pack together instead of chasing every mob randomly.

|cffffd100EMERGENCY|r
- Hammer of Justice the most dangerous enemy.
- Use a defensive when incoming damage spikes.
- Keep Lay on Hands for a real emergency.
- If the healer is out of mana, slow down and do not chain-pull.]]
      end

    else -- holy
      if ru then
        return [[|cffffd100СОЛО|r
- Печать праведности -> 2 (Правосудие) -> 1 (Удар Света) -> автоатаки.
- До 20 уровня Свет небес дорогой по мане: лечись между боями или когда действительно нужно.
- Не собирай большие пачки: Holy на низких уровнях всё ещё медленно убивает.

|cffffd100ПОДЗЕМЕЛЬЕ ДО 20|r
- Твой основной хил - Свет небес.
- Не лечи каждого после каждой царапины: длинный хил дорогой.
- Начинай каст заранее, если танк быстро теряет здоровье.
- Следи за своей маной и говори группе, если нужен перерыв.

|cffffd100С 20 УРОВНЯ|r
- Вспышка Света становится основным частым лечением.
- Свет небес оставь для более крупного лечения, когда есть время на каст.
- Освящение используй для урона только если группе безопасно и маны достаточно.

|cffffd100КОГДА ЛЕЧИТЬ|r
- Танк выше ~75%: обычно можно подождать, если входящий урон небольшой.
- Танк ~50-70%: начинай обычное лечение.
- Танк ниже ~40% и продолжает получать урон: лечи немедленно.
- Очень низкое HP / внезапный провал: аварийные способности, включая Возложение рук, если иначе цель погибнет.

|cffffd100КРИТИЧЕСКАЯ СИТУАЦИЯ|r
- Сначала спаси танка/себя, потом возвращайся к урону.
- Молот правосудия может остановить опасного моба и дать время на хил.
- Не трать всю ману на урон перед тяжёлой пачкой.
- Если маны мало, попроси паузу и выпей воду.]]
      else
        return [[|cffffd100SOLO|r
- Seal of Righteousness -> 2 (Judgement) -> 1 (Holy Strike) -> auto attacks.
- Before 20, Holy Light is mana-expensive: heal between pulls or when truly needed.
- Avoid large packs; low-level Holy still kills slowly.

|cffffd100DUNGEON BEFORE 20|r
- Holy Light is your main heal.
- Do not heal every tiny scratch; the long heal is expensive.
- Start casting early if the tank is dropping quickly.
- Watch your mana and tell the group when you need a break.

|cffffd100AT LEVEL 20|r
- Flash of Light becomes your frequent heal.
- Save Holy Light for larger heals when you have cast time.
- Use Consecration for damage only when the group is safe and mana is healthy.

|cffffd100WHEN TO HEAL|r
- Tank above ~75%: usually wait if incoming damage is low.
- Tank around 50-70%: start normal healing.
- Tank below ~40% and still taking damage: heal immediately.
- Very low HP / sudden drop: use emergency tools, including Lay on Hands if the target would otherwise die.

|cffffd100EMERGENCY|r
- Save the tank/yourself first, then return to damage.
- Hammer of Justice can stop a dangerous enemy and buy a healing window.
- Do not spend all mana on damage before a hard pull.
- If mana is low, ask for a pause and drink.]]
      end
    end

  elseif class=="HUNTER" then
    if ru then
      local common=[[|cffffd100ПЕРЕД БОЕМ|r
- Питомца держи сытым и с Growl для соло.
- В подземелье Growl питомца выключай, если танкуешь не ты.
- Метка охотника на приоритетную цель.

|cffffd100ОБЫЧНЫЙ МОБ|r
1. 1 - отправить питомца.
2. 2 - Метка охотника.
3. 3 - Укус змеи, если моб проживёт достаточно долго.
4. 4 - Чародейский выстрел по откату.
5. Держи дистанцию и продолжай автострельбу.

|cffffd100ПОДЗЕМЕЛЬЕ|r
- Не отправляй питомца раньше танка.
- Growl выключен.
- На одной цели: Метка -> Укус змеи -> основные выстрелы.
- На пачке с 18 уровня используй Залп/мульти-выстрел по ситуации, но не срывай агро.

|cffffd100КРИТИЧЕСКАЯ СИТУАЦИЯ|r
- Если моб добрался до тебя, используй контроль/дистанцию; Удар ящера только как запасной ближний бой.
- Не стой рядом с танком и фронтальными атаками босса.
- Если питомец почти умер, не продолжай бездумно тянуть новые цели.]]
      if spec=="surv" then
        return common.."\n\n|cffffd100SURVIVAL|r\nНа текущих ранних уровнях полного melee-набора ещё нет; играй гибридно и не форсируй постоянный ближний бой."
      elseif spec=="mm" then
        return common.."\n\n|cffffd100MARKSMANSHIP|r\nПрицельный выстрел используй по одной цели, Multi-Shot по нескольким. Следи за агро после сильного открытия."
      else
        return common.."\n\n|cffffd100BEAST MASTERY|r\nПитомец начинает бой первым. Твоя задача - поддерживать урон с дистанции и не перетягивать угрозу с питомца/танка."
      end
    else
      return [[|cffffd100BEFORE COMBAT|r
- Keep your pet happy; Growl on for solo.
- Turn pet Growl off in dungeons when another player is tanking.
- Hunter's Mark the priority target.

|cffffd100NORMAL MOB|r
1. 1 - send pet.
2. 2 - Hunter's Mark.
3. 3 - Serpent Sting if the mob will live long enough.
4. 4 - Arcane Shot on cooldown.
5. Keep range and continue Auto Shot.

|cffffd100DUNGEON|r
- Never send the pet before the tank.
- Growl off.
- Single target: Mark -> Sting -> core shots.
- On packs from level 18, use Multi-Shot when safe without pulling threat.

|cffffd100EMERGENCY|r
- If a mob reaches you, use control and regain range; Raptor Strike is a fallback melee button.
- Avoid standing in front of bosses with the tank.
- If your pet is nearly dead, do not blindly chain-pull.]]
    end
  end
  return T("only")
end

local function macroText(class,lvl)
  if class~="PALADIN" and class~="HUNTER" then return T("only") end
  local ru=uiLang()=="ru"
  local out={
    ru and "GAPer проверяет КНИГУ ЗАКЛИНАНИЙ, а не только уровень." or
           "GAPer checks your actual SPELLBOOK, not only your level.",
    (ru and "Клиент WoW: " or "WoW client: ")..(clientLang()=="ru" and "ruRU" or "enUS"),
    ru and "Текст /cast всегда создаётся на языке клиента WoW." or
           "/cast text is always generated in the WoW client language.",
    ""
  }
  for _,def in ipairs(macroDefs[class]) do
    if def.raw then
      out[#out+1]="[OK] "..def.name.." - "..(ru and "доступен" or "available")
    else
      local display=spellLabel(class,def.key,clientLang())
      local learned,actualName=defSpellInfo(class,def)
      if learned then
        out[#out+1]="|cff55ff55[OK]|r "..def.name.." - "..actualName
      elseif lvl >= (def.min or 1) then
        out[#out+1]="|cffffcc00["..(ru and "ТРЕНЕР" or "TRAINER").."]|r "..def.name.." - "..display..
          (ru and " (уровень подходит, но навык не найден)" or " (level is high enough, but spell is not learned)")
      else
        out[#out+1]="|cff888888["..(ru and "УР." or "LVL").." "..tostring(def.min or 1).."]|r "..def.name.." - "..display
      end
    end
  end
  out[#out+1]=""
  out[#out+1]=ru and
    "Кнопка создания делает макросы ТОЛЬКО для уже изученных навыков. После визита к тренеру открой эту вкладку снова и нажми создать/обновить." or
    "The create button only makes macros for spells you have actually learned. After visiting a trainer, reopen this tab and create/update again."
  return table.concat(out,"\n")
end

local function updateText()
  return table.concat({
    "|cffffd100"..T("source")..":|r "..DATA_VERSION,
    "",
    T("beta"),
    "",
    "- "..T("update1"),
    "- "..T("update2"),
    "- "..T("update3"),
  },"\n")
end

local function characterText(class, localizedClass, lvl, spec)
  local specName=spec
  for _,s in ipairs(specs[class] or {}) do if s.id==spec then specName=s[uiLang()] end end
  return string.format("|cffffd100%s:|r %s\n|cffffd100%s:|r %d\n|cffffd100%s:|r %s\n\n%s\n\n|cffaaaaaa%s: %s|r",
    T("class"), localizedClass, T("level"), lvl, T("build"), specName or "-", T("autoLevel"), T("source"), DATA_VERSION)
end

local function assignmentText(class,spec,lvl)
  local ru=uiLang()=="ru"
  local rows={}
  if class=="PALADIN" then
    rows={
      {"1","GAP_Holy","holyStrike",6},
      {"2","GAP_Judge","judgement",4},
      {"3","GAP_Stun","hammer",8},
      {"4","GAP_AOE","consecration",20},
      {"5",spec=="prot" and "GAP_SealF" or "GAP_SealR",spec=="prot" and "sealF" or "sealR",1},
      {"6",lvl>=20 and "GAP_Flash" or "GAP_Heal",lvl>=20 and "flash" or "holyLight",1},
      {"SHIFT-1","GAP_DP","divineProtection",6},
      {"SHIFT-2","GAP_LoH","lay",10},
      {"SHIFT-3","GAP_Exorc","exorcism",20},
    }
  elseif class=="HUNTER" then
    rows={
      {"1","GAP_Pet",nil,1},{"2","GAP_Mark","mark",6},{"3","GAP_Sting","serpent",4},
      {"4","GAP_Arcane","arcane",6},{"5","GAP_Aimed","aimed",10},{"6","GAP_Multi","multi",18},
      {"SHIFT-1","GAP_Raptor","raptor",1}
    }
  end
  local out={ru and "КУДА ПОСТАВИТЬ МАКРОСЫ:" or "WHERE TO PUT THE MACROS:"}
  for _,row in ipairs(rows) do
    if lvl>=row[4] then
      local status="[OK]"
      if row[3] then
        local fake={key=row[3]}
        local learned=defSpellInfo(class,fake)
        if not learned then status=ru and "[НЕТ НАВЫКА]" or "[NOT LEARNED]" end
      end
      out[#out+1]=row[1].." = "..row[2].."  "..status
    end
  end
  out[#out+1]=""
  out[#out+1]=ru and
    "1) Открой /macro.\n2) Выбери вкладку макросов персонажа.\n3) Перетащи GAP_ макросы на панель.\n4) В Настройки -> Клавиши назначь 1-6 и Shift+1/2/3 на эти слоты.\n5) Если рядом написано [НЕТ НАВЫКА], сначала сходи к тренеру." or
    "1) Open /macro.\n2) Choose character macros.\n3) Drag GAP_ macros to the action bar.\n4) In Key Bindings assign 1-6 and Shift+1/2/3 to those slots.\n5) If you see [NOT LEARNED], visit your trainer first."
  return table.concat(out,"\n")
end

local function removeGuideMacros()
  if InCombatLockdown and InCombatLockdown() then print(T("combat")); return end
  -- Iterate backwards to avoid shifting macro indices during deletion.
  local global,character=GetNumMacros()
  local offset=MAX_ACCOUNT_MACROS or 120
  for idx=offset+(character or 0),offset+1,-1 do
    local name=GetMacroInfo(idx)
    if name and string.sub(name,1,4)=="GAP_" then DeleteMacro(idx) end
  end
  for idx=(global or 0),1,-1 do
    local name=GetMacroInfo(idx)
    if name and string.sub(name,1,4)=="GAP_" then DeleteMacro(idx) end
  end
  print(uiLang()=="ru" and "Макросы GAPer удалены." or "GAPer macros deleted.")
end

local function removeAllMacros()
  if InCombatLockdown and InCombatLockdown() then print(T("combat")); return end
  local global,character=GetNumMacros()
  local offset=MAX_ACCOUNT_MACROS or 120
  for idx=offset+(character or 0),offset+1,-1 do DeleteMacro(idx) end
  for idx=(global or 0),1,-1 do DeleteMacro(idx) end
  print(uiLang()=="ru" and "Все макросы WoW удалены." or "All WoW macros deleted.")
end

StaticPopupDialogs["GAPER_DELETE_OWN"]={
  text="Delete all GAP_ macros? / Удалить все макросы GAP_?",
  button1=YES,button2=NO,OnAccept=removeGuideMacros,timeout=0,whileDead=1,hideOnEscape=1,preferredIndex=3,
}
StaticPopupDialogs["GAPER_DELETE_ALL"]={
  text="DELETE ALL WoW MACROS (including other addons and personal macros)? / УДАЛИТЬ ВСЕ макросы WoW?",
  button1=YES,button2=NO,OnAccept=removeAllMacros,timeout=0,whileDead=1,hideOnEscape=1,preferredIndex=3,
}

-- Build the icon panel from the ACTUAL talent tree reported by the game client.
-- The current talent plan is a provisional reference; no icon is fabricated.
local function findTalentTexture(name)
  if not name or not GetNumTalentTabs or not GetNumTalents or not GetTalentInfo then
    return "Interface\\Icons\\INV_Misc_QuestionMark"
  end
  local base=name:gsub(" %d+/%d+","")
  local ruMap={
    ["Deadly Aspects"]="Смертоносные аспекты",
    ["Focused Fire"]="Сосредоточенный огонь",
    ["Lethal Attacks"]="Смертельные атаки",
    ["Deflection"]="Отражение",
    ["Improved Judgement"]="Улучшенное правосудие",
    ["Conviction"]="Приговор",
    ["Benediction"]="Благословение",
    ["Holy Conduit"]="Священный проводник",
    ["Pursuit of Justice"]="Погоня за справедливостью",
    ["Divine Intellect"]="Божественный интеллект",
    ["Improved Seals"]="Улучшенные печати",
    ["Healing Light"]="Исцеляющий Свет",
    ["Reverence"]="Благоговение",
  }
  local wantedRU=ruMap[base]
  for tab=1,GetNumTalentTabs() do
    local n=GetNumTalents(tab) or 0
    for i=1,n do
      local liveName,icon=GetTalentInfo(tab,i)
      if liveName and (liveName==base or (wantedRU and liveName==wantedRU)) then
        return icon or "Interface\\Icons\\INV_Misc_QuestionMark"
      end
    end
  end
  return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function renderTalentIcons(class,spec,lvl)
  if not UI or not UI.talentRows then return end
  for _,r in ipairs(UI.talentRows) do r:Hide() end
  if UI.page~=3 then return end
  local plan=talentTable(class,spec)
  if not plan then return end
  for level=10,20 do
    local entry=plan[level]
    local r=UI.talentRows[level-9]
    if r and entry then
      r.icon:SetTexture(findTalentTexture(entry))
      local status=""
      if level<lvl then status=uiLang()=="ru" and " [взято/проверь]" or " [done/check]"
      elseif level==lvl then status=uiLang()=="ru" and "  < СЕЙЧАС" or "  < NOW"
      end
      r.label:SetText(tostring(level).." - "..localizedTalentName(entry)..status)
      if level==lvl then r.label:SetTextColor(1,.82,.15)
      elseif level<lvl then r.label:SetTextColor(.55,1,.55)
      else r.label:SetTextColor(1,1,1) end
      r:Show()
    end
  end
end

local function refresh()
  if not UI then return end
  local localizedClass,class=classInfo()
  local lvl=levelInfo()
  local spec=selectedSpec(class)

  UI.title:SetText(T("title"))
  UI.langRU:SetText("RU")
  UI.langEN:SetText("EN")
  UI.langRU:SetAlpha(uiLang()=="ru" and 1 or .55)
  UI.langEN:SetAlpha(uiLang()=="en" and 1 or .55)

  for i,b in ipairs(UI.tabs) do
    local keys={"character","macros","talents","play","updates"}
    b:SetText(T(keys[i]))
  end

  for i,b in ipairs(UI.specButtons) do b:Hide() end
  if specs[class] then
    for i,s in ipairs(specs[class]) do
      local b=UI.specButtons[i]
      b.specID=s.id; b:SetText(s[uiLang()]); b:Show()
      b:SetAlpha(spec==s.id and 1 or .55)
    end
  end

  local page=UI.page or 1
  if page==1 then UI.body:SetText(characterText(class,localizedClass,lvl,spec))
  elseif page==2 then UI.body:SetText(macroText(class,lvl))
  elseif page==3 then UI.body:SetText(getTalentText(class,spec,lvl))
  elseif page==4 then UI.body:SetText(playText(class,spec,lvl).."\n\n"..assignmentText(class,spec,lvl))
  elseif page==5 then UI.body:SetText(updateText()) end

  renderTalentIcons(class,spec,lvl)
  UI.createButton:SetText(T("create"))
  UI.deleteOwn:SetText(uiLang()=="ru" and "Удалить GAP_" or "Delete GAP_")
  UI.deleteAll:SetText(uiLang()=="ru" and "Удалить ВСЕ..." or "Delete ALL...")
  UI.deleteOwn:SetShown(page==2)
  UI.deleteAll:SetShown(page==2)
  if page==3 then
    UI.body:SetText((uiLang()=="ru" and
      "ЧТО КАЧАТЬ ПО УРОВНЯМ\n\nСлева показан план; справа - те же уровни с иконками из живого дерева талантов клиента, когда GAPer может сопоставить название.\nТекущий уровень выделен жёлтым.\n\n" or
      "WHAT TO TAKE EACH LEVEL\n\nThe plan is shown on the left; the right side shows the same levels with icons read from the live client talent tree when GAPer can match the name.\nYour current level is highlighted in yellow.\n\n")..getTalentText(class,spec,lvl))
  end
  if page==2 and (class=="PALADIN" or class=="HUNTER") then
    UI.createButton:Show()
  else
    UI.createButton:Hide()
  end
end

local function buildUI()
  local f=CreateFrame("Frame","GAPerMainFrame",UIParent,"BackdropTemplate")
  f:SetSize(720,560)
  f:SetPoint("CENTER")
  f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart",f.StartMoving); f:SetScript("OnDragStop",f.StopMovingOrSizing)
  f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
  f:Hide()

  local title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
  title:SetPoint("TOP",0,-18)
  f.title=title

  local close=CreateFrame("Button",nil,f,"UIPanelCloseButton")
  close:SetPoint("TOPRIGHT",-5,-5)

  local ru=CreateFrame("Button",nil,f,"UIPanelButtonTemplate"); ru:SetSize(42,22); ru:SetPoint("TOPRIGHT",-100,-16)
  local en=CreateFrame("Button",nil,f,"UIPanelButtonTemplate"); en:SetSize(42,22); en:SetPoint("LEFT",ru,"RIGHT",4,0)
  ru:SetScript("OnClick",function() GAPerGuideDB.lang="ru"; refresh() end)
  en:SetScript("OnClick",function() GAPerGuideDB.lang="en"; refresh() end)
  f.langRU=ru; f.langEN=en

  f.tabs={}
  local tabKeys={"character","macros","talents","play","updates"}
  for i=1,5 do
    local b=CreateFrame("Button",nil,f,"UIPanelButtonTemplate")
    b:SetSize(i==4 and 120 or 105,25)
    if i==1 then b:SetPoint("TOPLEFT",20,-55) else b:SetPoint("LEFT",f.tabs[i-1],"RIGHT",4,0) end
    b:SetScript("OnClick",function() f.page=i; refresh() end)
    f.tabs[i]=b
  end

  f.specButtons={}
  for i=1,3 do
    local b=CreateFrame("Button",nil,f,"UIPanelButtonTemplate")
    b:SetSize(150,25)
    if i==1 then b:SetPoint("TOPLEFT",22,-90) else b:SetPoint("LEFT",f.specButtons[i-1],"RIGHT",8,0) end
    b:SetScript("OnClick",function(self)
      local _,class=classInfo()
      GAPerGuideDB.spec=GAPerGuideDB.spec or {}
      GAPerGuideDB.spec[class]=self.specID
      refresh()
    end)
    f.specButtons[i]=b
  end

  local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT",22,-126); scroll:SetPoint("BOTTOMRIGHT",-38,58)
  local child=CreateFrame("Frame",nil,scroll)
  child:SetSize(640,1000)
  scroll:SetScrollChild(child)
  local body=child:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  body:SetPoint("TOPLEFT",4,-4); body:SetWidth(365); body:SetJustifyH("LEFT"); body:SetJustifyV("TOP")
  body:SetSpacing(4)
  child:SetScript("OnSizeChanged",function() end)
  f.body=body

  f.talentRows={}
  for i=1,12 do
    local row=CreateFrame("Frame",nil,child)
    row:SetSize(210,37)
    row:SetPoint("TOPLEFT",395,-8-(i-1)*40)
    local icon=row:CreateTexture(nil,"ARTWORK")
    icon:SetSize(30,30); icon:SetPoint("LEFT",0,0)
    local label=row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    label:SetPoint("LEFT",icon,"RIGHT",6,0)
    label:SetWidth(170); label:SetJustifyH("LEFT")
    row.icon=icon;row.label=label;row:Hide()
    f.talentRows[i]=row
  end

  local create=CreateFrame("Button",nil,f,"UIPanelButtonTemplate")
  create:SetSize(220,30); create:SetPoint("BOTTOMLEFT",18,18)
  create:SetScript("OnClick",createMacros)
  f.createButton=create
  local own=CreateFrame("Button",nil,f,"UIPanelButtonTemplate")
  own:SetSize(170,30);own:SetPoint("LEFT",create,"RIGHT",8,0)
  own:SetScript("OnClick",function() StaticPopup_Show("GAPER_DELETE_OWN") end)
  f.deleteOwn=own
  local all=CreateFrame("Button",nil,f,"UIPanelButtonTemplate")
  all:SetSize(170,30);all:SetPoint("LEFT",own,"RIGHT",8,0)
  all:SetScript("OnClick",function() StaticPopup_Show("GAPER_DELETE_ALL") end)
  f.deleteAll=all

  f.page=1
  UI=f
  refresh()
end


local function GAPer_Toggle()
  if not UI then
    local ok, err = pcall(buildUI)
    if not ok then
      print("|cffff5555GAPer UI error:|r "..tostring(err))
      return
    end
  end
  if UI:IsShown() then UI:Hide() else UI:Show(); refresh() end
end

SLASH_GAPERGUIDE1="/gaperguide"
SLASH_GAPERGUIDE2="/gpg"
SlashCmdList["GAPERGUIDE"]=function(msg)
  if msg=="scan" then dumpSpellbook(); return end
  if msg=="test" then
    local _,class=classInfo()
    print("|cff55ff55GAPer Guide loaded.|r Interface="..tostring(select(4,GetBuildInfo()))..
      " Locale="..tostring(GetLocale()).." Class="..tostring(class).." Level="..tostring(levelInfo()))
    return
  end
  GAPer_Toggle()
end

function GAPerGuide_OnCompartmentClick(addonName, buttonName)
  GAPer_Toggle()
end
function GAPerGuide_OnCompartmentEnter(addonName, menuButtonFrame)
  if GameTooltip then
    GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_LEFT")
    GameTooltip:SetText("GAPer Forever")
    GameTooltip:AddLine("/gaperguide", 1,1,1)
    GameTooltip:Show()
  end
end
function GAPerGuide_OnCompartmentLeave()
  if GameTooltip then GameTooltip:Hide() end
end



local function createMinimapButton()
  if _G.GAPerGuideMinimapButton then return end

  local b=CreateFrame("Button","GAPerGuideMinimapButton",Minimap)
  b:SetSize(30,30)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(8)
  b:RegisterForClicks("LeftButtonUp","RightButtonUp")
  b:RegisterForDrag("LeftButton")

  -- Outer gold ring, centered exactly on the button.
  local ring=b:CreateTexture(nil,"BACKGROUND")
  ring:SetTexture("Interface\\Buttons\\WHITE8X8")
  ring:SetSize(30,30)
  ring:SetPoint("CENTER",b,"CENTER",0,0)
  ring:SetVertexColor(0.85,0.65,0.12,1)

  -- Inner dark disc.
  local inner=b:CreateTexture(nil,"ARTWORK")
  inner:SetTexture("Interface\\Buttons\\WHITE8X8")
  inner:SetSize(24,24)
  inner:SetPoint("CENTER",b,"CENTER",0,0)
  inner:SetVertexColor(0.05,0.05,0.05,1)

  -- "GG" in the visual center.
  local txt=b:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
  txt:SetPoint("CENTER",b,"CENTER",0,0)
  txt:SetText("GG")
  txt:SetTextColor(1.0,0.82,0.15,1)
  txt:SetJustifyH("CENTER")
  txt:SetJustifyV("MIDDLE")

  -- Small hover highlight.
  local hl=b:CreateTexture(nil,"HIGHLIGHT")
  hl:SetTexture("Interface\\Buttons\\WHITE8X8")
  hl:SetSize(24,24)
  hl:SetPoint("CENTER",b,"CENTER",0,0)
  hl:SetVertexColor(1,1,1,0.12)

  b.ring=ring
  b.inner=inner
  b.text=txt

  GAPerGuideDB.minimapAngle=GAPerGuideDB.minimapAngle or 220

  local function updatePosition()
    local angle=math.rad(GAPerGuideDB.minimapAngle or 220)
    local radius=80
    b:ClearAllPoints()
    b:SetPoint("CENTER",Minimap,"CENTER",math.cos(angle)*radius,math.sin(angle)*radius)
  end

  b:SetScript("OnClick",function(self,button)
    if button=="LeftButton" then
      GAPer_Toggle()
    else
      if UI then
        UI.page=5
        UI:Show()
        refresh()
      else
        GAPer_Toggle()
      end
    end
  end)

  b:SetScript("OnEnter",function(self)
    GameTooltip:SetOwner(self,"ANCHOR_LEFT")
    GameTooltip:SetText("GAPer Guide")
    GameTooltip:AddLine(uiLang()=="ru" and "ЛКМ: открыть / закрыть" or "Left click: open / close",1,1,1)
    GameTooltip:AddLine(uiLang()=="ru" and "ПКМ: обновления" or "Right click: updates",1,1,1)
    GameTooltip:AddLine(uiLang()=="ru" and "Перетащи: переместить" or "Drag: move",1,1,1)
    GameTooltip:Show()
  end)

  b:SetScript("OnLeave",function()
    GameTooltip:Hide()
  end)

  b:SetScript("OnDragStart",function(self)
    self:SetScript("OnUpdate",function()
      local mx,my=Minimap:GetCenter()
      local scale=Minimap:GetEffectiveScale()
      local x,y=GetCursorPosition()
      x=x/scale-mx
      y=y/scale-my
      GAPerGuideDB.minimapAngle=math.deg(math.atan2(y,x))
      updatePosition()
    end)
  end)

  b:SetScript("OnDragStop",function(self)
    self:SetScript("OnUpdate",nil)
  end)

  updatePosition()
end

local events=CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_LEVEL_UP")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("SPELLS_CHANGED")
events:RegisterEvent("CHARACTER_POINTS_CHANGED")
events:SetScript("OnEvent",function(self,event,...)
  if event=="PLAYER_LOGIN" then
    createMinimapButton()
    print("|cff55ff55GAPer Guide v0.2.0 loaded.|r Type /gaperguide")
  elseif UI then
    refresh()
  end
end)
