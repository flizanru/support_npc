include('shared.lua')
ENT.RenderGroup = RENDERGROUP_BOTH

surface.CreateFont('cp2077_font_npc_title', {
	font = 'Blender Pro Medium',
	size = 30,
	weight = 5000,
	extended = true,
})

surface.CreateFont('cp2077_font_npc', {
	font = 'Blender Pro Medium',
	size = 20,
	weight = 500,
	extended = true,
})

surface.CreateFont('cp2077_font_npc_2', {
	font = 'Blender Pro Medium',
	size = 30,
	weight = 500,
	extended = true,
})

isCustomMenuOpen = false

hook.Add("HUDPaint", "DrawInteractionText", function()
    if isCustomMenuOpen then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local tr = util.GetPlayerTrace(ply)
    local trace = util.TraceLine(tr)
    if not trace.Hit or not IsValid(trace.Entity) then return end

    local distance = ply:GetPos():DistToSqr(trace.Entity:GetPos())
    if distance > (128 * 128) then return end

    if trace.Entity:GetClass() == "cp2077_npc" then
        local screenPos = trace.HitPos:ToScreen()
        surface.SetDrawColor(Color(255, 255, 255, 175))
        surface.SetMaterial(Material("cp2077/chat/textentry.png"))
        surface.DrawTexturedRect(screenPos.x * .8, screenPos.y - 15, 375, 30)
        draw.SimpleText("Кликните Е, чтобы взаимодействовать", "cp2077_font_npc", screenPos.x, screenPos.y, Color(136, 223, 204), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)

local function textPlate(text,y)
	surface.SetFont("cp2077_font_npc_title")
	local tw,th = surface.GetTextSize(text)
	local bx,by = -tw / 2 - 60, y - 25
	local bw,bh = tw + 125, th + 50

	surface.SetDrawColor(color_white)
	surface.SetMaterial(Material("cp2077/npc/cp2077_npc_titlebg.png"))
	surface.DrawTexturedRect(bx, by, bw, bh)

	surface.SetTextColor(Color(1, 231, 255))
	surface.SetTextPos(-tw / 2,y)
	surface.DrawText(text)
end

local function drawInfo(ent, text, dist)
	dist = dist or EyePos():DistToSqr(ent:GetPos())

	if dist < 60000 then
		surface.SetAlphaMultiplier( math.Clamp(3 - (dist / 20000), 0, 1) )

		local _,max = ent:GetRotatedAABB(ent:OBBMins(), ent:OBBMaxs() )
		local rot = (ent:GetPos() - EyePos()):Angle().yaw - 90
		local sin = math.sin(CurTime() + ent:EntIndex()) / 3 + .5
		local center = ent:LocalToWorld(ent:OBBCenter())

		cam.Start3D2D(center + Vector(0, 0, math.abs(max.z / 2) + 12 + sin), Angle(0, rot, 90), 0.13)
			textPlate(text,15)
		cam.End3D2D()

		surface.SetAlphaMultiplier(1)
	end
end

NPC_HIDE_ON_DISTANCE = nil
function ENT:Draw()

	local dist = EyePos():DistToSqr(self:GetPos())
	if NPC_HIDE_ON_DISTANCE and dist > NPC_HIDE_ON_DISTANCE then return end

	self:DrawModel()
	drawInfo(self, "Ахрамович Ярослав Адамович", dist)
end

net.Receive("OpenCustomMenu", function(len)
	isCustomMenuOpen = true
    local ply = LocalPlayer()

    local frame = vgui.Create("DFrame")
    frame:SetTitle("")
    frame:SetSize(300, 200)
    frame:Center()
    frame:MakePopup()
	frame:ShowCloseButton(false)
	frame.Paint = function(self, w, h)
		surface.SetDrawColor(color_white)
		surface.SetMaterial(Material("cp2077/hud/bg.png"))
		surface.DrawTexturedRect(0, 0, w, h)

		surface.SetDrawColor(color_white)
		surface.SetMaterial(Material("cp2077/hud/random_shit_4a.png"))
		surface.DrawTexturedRect(12, 4, 255, 17)

		surface.SetDrawColor(color_white)
		surface.SetMaterial(Material("cp2077/f4/random_shit_4.png"))
		surface.DrawTexturedRect(w - 10, 30, 4, 158)
	end
	
    local button1 = vgui.Create("DButton", frame)
    button1:SetText("Обменять валюту")
    button1:SetFont("cp2077_font_npc")
    button1:SetTextColor(Color(186, 80, 85))
    button1:SetPos(50, 50)
    button1:SetSize(200, 30)
	button1.Paint = function(self, w, h)
		surface.SetDrawColor(color_white)
		surface.SetMaterial(Material("cp2077/f4/info_bg.png"))
		surface.DrawTexturedRect(0, 0, w, h)
	end
	button1.OnCursorEntered = function(self)
		self:SetTextColor(color_white)
	end
	button1.OnCursorExited = function(self)
		self:SetTextColor(Color(186, 80, 85))
	end
    button1.DoClick = function()
		frame:Hide()

local DonateFrame = vgui.Create("DFrame")
DonateFrame:SetTitle("")
DonateFrame:SetSize(600, 400)
DonateFrame:Center()
DonateFrame:MakePopup()
DonateFrame:ShowCloseButton(false)
DonateFrame.Paint = function(self, w, h)
    surface.SetDrawColor(color_white)
    surface.SetMaterial(Material("cp2077/hud/bg.png"))
    surface.DrawTexturedRect(0, 0, w, h)
end

local titleLabel = vgui.Create("DLabel", DonateFrame)
titleLabel:SetText("Обмен виртуальный валюты")
titleLabel:SetFont("cp2077_font_npc_2")
titleLabel:SetTextColor(Color(186, 80, 85))
titleLabel:SizeToContents()
titleLabel:SetPos((DonateFrame:GetWide() - titleLabel:GetWide()) / 2, 10)

local exchangeInProgress = false
local currentCheckID = nil

net.Receive("ExchangeStatus", function()
    local canExchange = net.ReadBool()

    if canExchange and not exchangeInProgress then
        exchangeInProgress = true 
        currentCheckID = nil 
        Derma_Query(
            "Хотите ли вы обменять валюту на донат валюту?",
            "Подтверждение обмена",
            "Да",
            function()
                net.Start("ConfirmExchange")
                net.WriteBool(true)
                net.SendToServer()
            end,
            "Нет"
        )
    elseif not canExchange then
        Derma_Message("Недостаточно средств или лимит обмениваний исчерпан", "Ошибка", "OK")
        surface.PlaySound("ambient/voices/citizen_beaten1.wav")
    end
end)

net.Receive("ConfirmExchange", function(_, ply)
    local confirm = net.ReadBool()

    if confirm then
        net.Start("ExchangeCompleted")
        net.Send(ply)
    end
end)

net.Receive("ExchangeInfo", function()
    currentCheckID = net.ReadTable().checkid
end)

net.Receive("ExchangeCompleted", function()
    Derma_Message("Обмен успешно завершен!")
    surface.PlaySound("ambient/office/coinslot1.wav")

    if IsValid(DonateFrame) then
        DonateFrame:Close()
    end

    if IsValid(frame) then
        frame:Close()
    end
end)

net.Receive("ExchangeInfoDelayed", function()
    local infoTable = net.ReadTable()
    local checkid = infoTable.checkid
    chat.AddText( Color( 220, 20, 60 ), "[ДОНАТ]", Color( 255, 255, 255 ), " Вы успешно обменяли донат валюту. Чек: " .. (checkid or "N/A"))
end)


local function exchangeCurrency(amount)
    net.Start("ExchangeDonateCurrency")
    net.WriteInt(amount, 32)
    net.SendToServer()
end

local buttonWidth = 300
local buttonHeight = 30 
local verticalSpacing = 10  

local startY = 110  

local buttonDonate = vgui.Create("DButton", DonateFrame)
buttonDonate:SetText("1.000.000$ = 1 донат валюты")
buttonDonate:SetFont("cp2077_font_npc")
buttonDonate:SetTextColor(Color(186, 80, 85))
buttonDonate:SetPos((DonateFrame:GetWide() - buttonWidth) / 2, startY)
buttonDonate:SetSize(buttonWidth, buttonHeight)
buttonDonate.Paint = function(self, w, h)
    surface.SetDrawColor(color_white)
    surface.SetMaterial(Material("cp2077/f4/info_bg.png"))
    surface.DrawTexturedRect(0, 0, w, h)
end
buttonDonate.OnCursorEntered = function(self)
    self:SetTextColor(color_white)
end
buttonDonate.OnCursorExited = function(self)
    self:SetTextColor(Color(186, 80, 85))
end
buttonDonate.DoClick = function()
    exchangeCurrency(1000000)
end

local buttonDonate1 = vgui.Create("DButton", DonateFrame)
buttonDonate1:SetText("10.000.000$ = 10 донат валюты")
buttonDonate1:SetFont("cp2077_font_npc")
buttonDonate1:SetTextColor(Color(186, 80, 85))
buttonDonate1:SetPos((DonateFrame:GetWide() - buttonWidth) / 2, startY + buttonHeight + verticalSpacing)
buttonDonate1:SetSize(buttonWidth, buttonHeight)
buttonDonate1.Paint = function(self, w, h)
    surface.SetDrawColor(color_white)
    surface.SetMaterial(Material("cp2077/f4/info_bg.png"))
    surface.DrawTexturedRect(0, 0, w, h)
end
buttonDonate1.OnCursorEntered = function(self)
    self:SetTextColor(color_white)
end
buttonDonate1.OnCursorExited = function(self)
    self:SetTextColor(Color(186, 80, 85))
end
buttonDonate1.DoClick = function()
    exchangeCurrency(10000000)
end

local buttonDonate2 = vgui.Create("DButton", DonateFrame)
buttonDonate2:SetText("20.000.000$ = 30 донат валюты")
buttonDonate2:SetFont("cp2077_font_npc")
buttonDonate2:SetTextColor(Color(186, 80, 85))
buttonDonate2:SetPos((DonateFrame:GetWide() - buttonWidth) / 2, startY + 2 * (buttonHeight + verticalSpacing))
buttonDonate2:SetSize(buttonWidth, buttonHeight)
buttonDonate2.Paint = function(self, w, h)
    surface.SetDrawColor(color_white)
    surface.SetMaterial(Material("cp2077/f4/info_bg.png"))
    surface.DrawTexturedRect(0, 0, w, h)
end
buttonDonate2.OnCursorEntered = function(self)
    self:SetTextColor(color_white)
end
buttonDonate2.OnCursorExited = function(self)
    self:SetTextColor(Color(186, 80, 85))
end
buttonDonate2.DoClick = function()
    exchangeCurrency(20000000)
end

local buttonDonate3 = vgui.Create("DButton", DonateFrame)
buttonDonate3:SetText("Вернуться")
buttonDonate3:SetFont("cp2077_font_npc")
buttonDonate3:SetTextColor(Color(186, 80, 85))
buttonDonate3:SetPos((DonateFrame:GetWide() - buttonWidth) / 2, startY + 3 * (buttonHeight + verticalSpacing))
buttonDonate3:SetSize(buttonWidth, buttonHeight)
buttonDonate3.Paint = function(self, w, h)
    surface.SetDrawColor(color_white)
    surface.SetMaterial(Material("cp2077/f4/info_bg.png"))
    surface.DrawTexturedRect(0, 0, w, h)
end
buttonDonate3.OnCursorEntered = function(self)
    self:SetTextColor(color_white)
end
buttonDonate3.OnCursorExited = function(self)
    self:SetTextColor(Color(186, 80, 85))
end
buttonDonate3.DoClick = function()
    DonateFrame:Close()
    frame:Show()
end


local closebtn = vgui.Create("DButton", DonateFrame)
closebtn:SetText("")
closebtn:SetFont("cp2077_font_npc")
closebtn:SetTextColor(color_white)
closebtn:SetPos(DonateFrame:GetWide() - 25, 3)
closebtn:SetSize(20, 20)
closebtn.Paint = function(self, w, h)
    surface.SetDrawColor(color_white)
    surface.SetMaterial(Material("cp2077/f4/random_shit_2b.png"))
    surface.DrawTexturedRect(0, 0, w, h)
end
		closebtn.DoClick = function()
			DonateFrame:Close()
			isCustomMenuOpen = false
		end
	end

    local button2 = vgui.Create("DButton", frame)
    button2:SetText("Экскурсия по серверу")
    button2:SetFont("cp2077_font_npc")
    button2:SetTextColor(Color(186, 80, 85))
    button2:SetPos(50, 90)
    button2:SetSize(200, 30)
	button2.Paint = function(self, w, h)
		surface.SetDrawColor(color_white)
		surface.SetMaterial(Material("cp2077/f4/info_bg.png"))
		surface.DrawTexturedRect(0, 0, w, h)
	end
	button2.OnCursorEntered = function(self)
		self:SetTextColor(color_white)
	end
	button2.OnCursorExited = function(self)
		self:SetTextColor(Color(186, 80, 85))
	end
button2.DoClick = function()
    gui.OpenURL("https://docs.google.com/document/d/1qeixXNaNBGFDwVCUOZRa6LE3cdcOcIpNFcj5CJi0GKM/edit") 
end


    local button3 = vgui.Create("DButton", frame)
    button3:SetText("Отправить цитату")
    button3:SetFont("cp2077_font_npc")
    button3:SetTextColor(Color(186, 80, 85))
    button3:SetPos(50, 130)
    button3:SetSize(200, 30)
	button3.Paint = function(self, w, h)
		surface.SetDrawColor(color_white)
		surface.SetMaterial(Material("cp2077/f4/info_bg.png"))
		surface.DrawTexturedRect(0, 0, w, h)
	end
	button3.OnCursorEntered = function(self)
		self:SetTextColor(color_white)
	end
	button3.OnCursorExited = function(self)
		self:SetTextColor(Color(186, 80, 85))
	end
    button3.DoClick = function()
        net.Start("RequestRandomMessage")
        net.SendToServer()
    end

    local button4 = vgui.Create("DButton", frame)
    button4:SetText("")
    button4:SetFont("cp2077_font_npc")
    button4:SetTextColor(color_white)
    button4:SetPos(frame:GetWide() - 25, 3)
    button4:SetSize(20, 20)
	button4.Paint = function(self, w, h)
		surface.SetDrawColor(color_white)
		surface.SetMaterial(Material("cp2077/f4/random_shit_2b.png"))
		surface.DrawTexturedRect(0, 0, w, h)
	end
    button4.DoClick = function()
        frame:Close()
		isCustomMenuOpen = false
    end
end)

net.Receive("ReceiveRandomMessage", function(len)
    local quote = net.ReadString()
    chat.AddText(quote)
end)