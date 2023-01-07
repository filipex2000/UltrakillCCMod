function Ultrakill:GetActionFactor(self)
	if self.enemyPositions and #self.enemyPositions and self.heroActor then
		local factor = 0
		
		for i = 1, #self.enemyPositions do
			local pos = self.enemyPositions[i]
			local dif = SceneMan:ShortestDistance(pos, self.heroActor.Pos, SceneMan.SceneWrapsX)
			
			local debugColor = 13
			
			if dif.Magnitude < 500 then
				factor = 1
				
				debugColor = 122
			else
				local terrCheck = SceneMan:CastStrengthRay(self.heroActor.Pos, dif, 30, Vector(), math.random(5,8), 0, SceneMan.SceneWrapsX);
				if not terrCheck then
					factor = 1
					
					debugColor = 162
				end
			end
			
			if self.DEBUG then
				PrimitiveMan:DrawLinePrimitive(pos, pos + dif, debugColor)
			end
		end
		
		return factor
	else
		return 0
	end
end

function Ultrakill:UpdateActionFactor(self)
	if not self.actionFactor then
		self.actionFactor = 0
		
		self.actionForceFactor = 0
		self.actionForceFactorTimer = Timer()
		self.actionForceFactorDuration = 0
	end
	
	local target = Ultrakill:GetActionFactor(self)
	if self.actionForceFactorDuration > 0 then
		if self.actionForceFactorTimer:IsPastSimMS(self.actionForceFactorDuration) then
			self.actionForceFactorDuration = 0
			self.actionForceFactor = 0
		else
			target = self.actionForceFactor
		end
	end
	
	local dif = target - self.actionFactor
	self.actionFactor = self.actionFactor + dif * TimerMan.DeltaTimeSecs * 2.5
	
	return self.actionFactor
end

function Ultrakill:ForceActionFactor(self, factor, duration)
	if not self.actionFactor then
		self.actionFactor = 0
		
		self.actionForceFactor = 0
		self.actionForceFactorTimer = Timer()
		self.actionForceFactorDuration = 0
	end
	
	self.actionForceFactorDuration = duration
	self.actionForceFactorTimer:Reset()
	self.actionForceFactor = factor
end