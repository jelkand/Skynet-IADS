do

SkynetIADSSamSite = {}
SkynetIADSSamSite.__index = SkynetIADSSamSite

SkynetIADSSamSite.AUTONOMOUS_STATE_DCS_AI = 0
SkynetIADSSamSite.AUTONOMOUS_STATE_DARK = 1

function SkynetIADSSamSite:create(samGroup)
	local sam = {}
	setmetatable(sam, SkynetIADSSamSite)
	sam.powerSources = {}
	sam.connectionNodes = {}
	sam.aiState = true
	sam.samSite = samGroup
	sam.isAutonomous = false
	sam.targetsInRange = {}
	sam.jammerID = nil
	sam.lastJammerUpdate = 0
	sam.autonomousMode = SkynetIADSSamSite.AUTONOMOUS_STATE_DCS_AI
	sam:goDark()
	world.addEventHandler(sam)
	return sam
end

function SkynetIADSSamSite:goDark(enforceGoDark)

	-- if the sam site has contacts in range, it will refuse to go dark
	if ( self:getNumTargetsInRange() > 0 ) and ( enforceGoDark ~= true ) then
		return
	end

	if self.aiState == true then
		local sam = self.samSite
		local controller = sam:getController()
		-- we will turn off AI for all SAM Sites added to the IADS, Skynet decides when a site will go online.
		--cont:setOnOff(false)
		controller:setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.GREEN)
		controller:setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_HOLD)
		self.aiState = false
		mist.removeFunction(self.jammerID)
		trigger.action.outText(self:getDescription().." going dark", 1)
	end
end

--this function is currently a simple placeholder, should read the radar units of the SAM system an return them
function SkynetIADSSamSite:getRadarUnits()
	return self.samSite:getUnits()
end

function SkynetIADSSamSite:jam(distance)
	if self.lastJammerUpdate == 0 then
		trigger.action.outText("setting jammer chance", 1)
		self.lastJammerUpdate = 10
		local jammerChance = math.random(0, 100)
		mist.removeFunction(self.jammerID)
		self.jammerID = mist.scheduleFunction(SkynetIADSSamSite.setJamState, {self, jammerChance}, 1, 1)
	end
end

function SkynetIADSSamSite.setJamState(self, jammerChance)
	local controller = self.samSite:getController()
	if jammerChance > 50 then
		controller:setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_HOLD)
		trigger.action.outText(self:getDescription()..": is beeing jammend, setting to weapon hold", 1)
	else
		controller:setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_FREE)
		trigger.action.outText(self:getDescription()..": is beeing jammend, setting to weapon free", 1)
	end
	self.lastJammerUpdate = self.lastJammerUpdate - 1
end

function SkynetIADSSamSite:getNumTargetsInRange()
	local contacts = 0
	for description, aircraft in pairs(self.targetsInRange) do
		contacts = contacts + 1
	end
	--trigger.action.outText("num Contacts in Range: "..contacts, 1)
	return contacts
end

function SkynetIADSSamSite:isActive()
	return self.aiState
end

function SkynetIADSSamSite:getDescription()
	return "SAM Group: "..self.samSite:getName().." Type : "..self:getDBName(true)
end

function SkynetIADSSamSite:addPowerSource(powerSource)
	table.insert(self.powerSources, powerSource)
end

function SkynetIADSSamSite:addConnectionNode(connectionNode)
	table.insert(self.connectionNodes, connectionNode)
end

function SkynetIADSSamSite:hasActiveConnectionNode()
	return SkynetIADS.genericCheckOneObjectIsAlive(self.connectionNodes)
end

function SkynetIADSSamSite:hasWorkingPowerSource()
	return SkynetIADS.genericCheckOneObjectIsAlive(self.powerSources)
end

function SkynetIADSSamSite:getDBName(natoName)
	return SkynetIADS.getDBName(self.samSite, natoName)
end

function SkynetIADSSamSite:goAutonomous()
	self.isAutonomous = true
	if self.autonomousMode == SkynetIADSSamSite.AUTONOMOUS_STATE_DARK then
		self:goDark()
		trigger.action.outText(self:getDescription().." is Autonomous: DARK", 1)

	else
		self:goLive()
		trigger.action.outText(self:getDescription().." is Autonomous: DCS AI", 1)
	end
	return
end

function SkynetIADSSamSite:setAutonomousMode(mode)
	self.autonomousMode = mode
end

function SkynetIADSSamSite:goLive()
	if self.aiState == false then
		local  cont = self.samSite:getController()
		cont:setOnOff(true)
		cont:setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.RED)	
		cont:setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_FREE)
		---cont:knowTarget(ewrTarget, true, true) check to see if this will help for a faster shot of the SAM
		self.aiState = true
		trigger.action.outText(self:getDescription().." going live", 1)
	end
end

function SkynetIADSSamSite:handOff(aircraft)
	-- if the sam has no power, it won't do anything
	if self:hasWorkingPowerSource() == false then
		self:goDark(true)
		trigger.action.outText(self:getDescription().." has no Power", 1)
		return
	end
	if self:isTargetInRange(aircraft) then
		self.targetsInRange[aircraft:getName()] = aircraft
		self:goLive()
	else
		self:removeContact(aircraft)
		self:goDark()
	end
end

function SkynetIADSSamSite:removeContact(contact)
	local updatedContacts = {}
	for description, aircraft in pairs(self.targetsInRange) do
		if aircraft ~= contact then
			updatedContacts[description] = aircraft
		end
	end
	self.targetsInRange = updatedContacts
end

function SkynetIADSSamSite:isTargetInRange(target)
	local samSiteUnits = self.samSite:getUnits()
	local samRadarInRange = false
	local samLauncherinRange = false
	--go through sam site units to check launcher and radar distance, they could be positined quite far apart, only activate if both are in reach
	for j = 1, #samSiteUnits do
		local  samElement = samSiteUnits[j]
		local typeName = samElement:getTypeName()	
		--trigger.action.outText("type name: "..typeName, 1)
		local radarData = SkynetIADS.database[self:getDBName()]['searchRadar'][typeName]
		local launcherData = SkynetIADS.database[self:getDBName()]['launchers'][typeName]
		local trackingData = nil
		if radarData == nil then
			--to decide if we should activate the sam we use the tracking radar range if it exists
			trackingData = SkynetIADS.database[self:getDBName()]['trackingRadar']
			if trackingData ~= nil then
				radarData = trackingData[typeName]
			end
		end
		--if we find a radar in a SAM site, we calculate to see if it is within tracking parameters
		if radarData ~= nil then
			if self:isRadarWithinTrackingParameters(target, samElement, radarData) then
				samRadarInRange = true
			end
		end
		--if we find a launcher in a SAM site, we calculate to see if it is within firing parameters
		if launcherData ~= nil then
			if self:isLauncherWithinFiringParameters(target, samElement, launcherData) then
				samLauncherinRange = true
			end
		end		
	end	
	-- we only need to find one radar and one launcher within range in a Group, the AI of DCS will then decide which launcher will fire
	return ( samRadarInRange and samLauncherinRange )
end

-- TODO: could be more acurrate it it would calculate sland range
function SkynetIADSSamSite:isLauncherWithinFiringParameters(aircraft, samLauncherUnit, launcherData)
	local isInRange = false
	local distance = mist.utils.get2DDist(aircraft:getPosition().p, samLauncherUnit:getPosition().p)
	local maxFiringRange = launcherData['range']
--	trigger.action.outText("Launcher Range: "..maxFiringRange,1)
--	trigger.action.outText("current distance: "..distance,1)
	if distance <= maxFiringRange then
		isInRange = true
		--trigger.action.outText(aircraft:getTypeName().." in range of:"..samLauncherUnit:getTypeName(),1)
	end
	return isInRange
end

function SkynetIADSSamSite:isRadarWithinTrackingParameters(aircraft, samRadarUnit, radarData)
	local isInRange = false
	local distance = mist.utils.get2DDist(aircraft:getPosition().p, samRadarUnit:getPosition().p)
	local radarHeight = samRadarUnit:getPosition().p.y
	local aircraftHeight = aircraft:getPosition().p.y	
	local altitudeDifference = math.abs(aircraftHeight - radarHeight)
	local maxDetectionAltitude = radarData['max_alt_finding_target']
	local maxDetectionRange = radarData['max_range_finding_target']	

	--trigger.action.outText("Radar Range: "..maxDetectionRange,1)
--	trigger.action.outText("current distance: "..distance,1)
	
	if altitudeDifference <= maxDetectionAltitude and distance <= maxDetectionRange then
		--trigger.action.outText(aircraft:getTypeName().." in range of:"..samRadarUnit:getTypeName(),1)
		isInRange = true
	end
	return isInRange
end

function SkynetIADSSamSite:onEvent(event)
--[[
	if event.id == world.event.S_EVENT_SHOT then
		local weapon = event.weapon
		targetOfMissile = weapon:getTarget()
		if targetOfMissile ~= nil and SkynetIADS.isWeaponHarm(weapon) then
			self:startHarmDefence(weapon)
		end	
	end
--]]
end

function SkynetIADSSamSite.harmDefence(self, inBoundHarm) 
	local target = inBoundHarm:getTarget()
	local harmDetected = false	
	if target ~= nil then
		local targetController = target:getController()
		trigger.action.outText("HARM TARGET IS: "..target:getName(), 1)	
		local radarContacts = targetController:getDetectedTargets()
		--check to see if targeted Radar Site can see the HARM with its sensors, only then start defensive action
		for i = 1, #radarContacts do
			local detectedObject = radarContacts[i].object
			if SkynetIADS.isWeaponHarm(detectedObject) then
				trigger.action.outText(target:getName().." has detected: "..detectedObject:getTypeName(), 1)
				harmDetected = true
			end
		end
		
		local distance = mist.utils.get2DDist(inBoundHarm:getPosition().p, target:getPosition().p)
		distance = mist.utils.round(mist.utils.metersToNM(distance),2)
		trigger.action.outText("HARM Distance: "..distance, 1)
		
		--TODO: some SAM Sites have HARM defence, so they do not need help from the script
		if distance < 5 and harmDetected then
			local point = inBoundHarm:getPosition().p
			point.y = point.y + 1
			point.x = point.x - 1
			point.z = point.z + 1
		--	trigger.action.explosion(point, 10) 
		end
	else
		trigger.action.outText("target is nil", 1)
	end
end

end