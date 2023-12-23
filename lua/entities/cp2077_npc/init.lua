AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

util.AddNetworkString("OpenCustomMenu")
util.AddNetworkString("RequestRandomMessage")
util.AddNetworkString("ReceiveRandomMessage")

function ENT:Initialize()
    self:SetModel("models/Splinks/Hotline_Miami/Jacket/Drive/Player_jacket_Drive.mdl")
    self:SetHullType(HULL_HUMAN)
    self:SetHullSizeNormal()
    self:SetNPCState(NPC_STATE_SCRIPT)
    self:SetSolid(SOLID_BBOX)
    self:CapabilitiesAdd(CAP_ANIMATEDFACE, CAP_TURN_HEAD)
    self:SetUseType(SIMPLE_USE)
    self:DropToFloor()
    self:SetMaxYawSpeed(90)
end

function ENT:AcceptInput(name, activator, caller)
    if name == "Use" and IsValid(caller) and caller:IsPlayer() then
        net.Start("OpenCustomMenu")
        net.Send(caller)
    end
end

local function SendRandomMessage(ply)
    local quotes = {
        "Гони бабки, за умные мысли!",
        "Штирлиц гулял по лесу и увидел голубые ели. Присмотрелся и понял, что голубые не только ели, но и те, кто прямо сейчас слушали  этот анекдот.",
        "Решили поговорить два сапога про политику. По итогу выяснили что один левый, другой правый",
		"Всё, что мы можем получить здесь, так это пиды, причём в плохом смысле",
		"Никогда не сдавайся-лучше пивом накидайся!",
		"'Безделье - это игрушка в руках дьявола,ежжи честь имеется такое проповедствовать'",
		"'Неважно, с какой скоростью ты двигаешься, братишка. Главное не останавливайся!'",
		"Весь мир будет против меня я прав, я вдохновляюсь этим.",
		"Не расстраивайся! Все будет ровно, как спина динозавра ",
		"Начнешь эту игру - пути назад уже не будет",
		"Нельзя недооценивать противника, ежжи",
		"Пизди всех, втыкай! Ты будешь прав, я на подхвате",
		"Лишь утратив всё до конца, мы обретаем свободу.",
		"Если не знаешь, чего хочешь, умрешь в куче того, чего не хотел",
		"Заебали эти мусора, да?",
		"Не жуй сопли, лучше иди попиздись в бойцовском клубе",
		"Перестань ты за все цепляться и наплюй на все... Наплюй!",
		"Неповторимая красота снежинки — это не про тебя",
		"Ударь меня... Не хочу умирать без шрамов!",
		"Имея много мыла, можно взорвать всё, что угодно",
		"Самосовершенствование — это онанизм. Саморазрушение — вот ради чего стоит жить!",
		"Повремени, родной. Не стоит обострять",
		"Что может штырить сильнее, чем говяжий дошик?",
		"Я комплиментами сорил. Писал стихи неоднократно. Тебя одну я полюбил.А ты сказала 'мм понятно'.",
		"Разбито сердце, как бокал, И смысла нет в дальнейшей жизни. Я пригласил тебя на бал, А ты сказала: «час — три тыщи»",
		"Если тебе тяжело идти, значит ты жирный",
		"Эх, столько нефоров развелось здесь(",
		"Да пошел ты, не буду я тебе ничего рассказывать ",
		"Только перед лицом смерти человек становится тем, кто он есть на самом деле. Ты ещё вполне успеешь кем-то стать",
		"Не люблю тех, кто живёт в прошлом. Люди должны меняться. И мир вместе с ними",
		"Не хочу показаться грубым, но я всё это в рот е*ал",
		"Посмотри на меня, видишь? Видишь это выражение неудивления на моем лице?",
		"Жить вообще гораздо легче, если не оглядываешься назад и не думаешь о других",
		"Не знаю, чего мы добьёмся, но на уши всех поднимем точно!",
   		"Не жуй трусы, соси концы"
	}
    local quote = quotes[math.random(#quotes)]
    return quote
end

net.Receive("RequestRandomMessage", function(len, ply)
    local quote = SendRandomMessage(ply)
    net.Start("ReceiveRandomMessage")
    net.WriteString(quote)
    net.Send(ply)
end)

function ENT:Think()
    self:SetSequence('idle_all_01')
	self:NextThink( CurTime() + 1 )
	return true
end
