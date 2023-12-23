ENT.Base = "base_ai"
ENT.Type = "ai"
ENT.PrintName		= "Менюшка на Е"
ENT.Author			= "king_of_the_squirt and flizan.ru"
ENT.Category		= "Экскурсовод"
ENT.Spawnable			= true
ENT.AdminSpawnable		= true
ENT.AutomaticFrameAdvance = true
 
function ENT:SetAutomaticFrameAdvance(bUsingAnim)
	self.AutomaticFrameAdvance = bUsingAnim
end
