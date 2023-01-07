
function Create(self)
	self.parent = ToAHuman(self:GetParent())
end

function OnDetach(self)
	self.parent = nil;
	self:GibThis()
end

function Update(self)
	if self.parent then
		self.Frame = self.parent.Frame
	end
end
