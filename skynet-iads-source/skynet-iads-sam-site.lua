do

SkynetIADSSamSite = {}
SkynetIADSSamSite = inheritsFrom(SkynetIADSAbstractRadarElement)

function SkynetIADSSamSite:create(samGroup, iads)
	local sam = self:superClass():create(samGroup, iads)
	setmetatable(sam, self)
	self.__index = self
	sam.targetsInRange = false
	return sam
end

-- TANR Note: Following same logic as previous isDestroyed but separated pieces
function SkynetIADSSamSite:isDestroyed()
	local isDestroyed = true
	if self:areLaunchersDestroyed() == false then
		isDestroyed = false
	end
	if self:areTrackingRadarDestroyed() == false then
		isDestroyed = false
	end
	if self:areSearchRadarDestroyed() == false then
		isDestroyed = false
	end
	return isDestroyed
end

function SkynetIADSSamSite:areLaunchersDestroyed()
    local launchersDestroyed = true
    for i = 1, #self.launchers do
        local launcher = self.launchers[i]
        if launcher:isExist() == true then
            launchersDestroyed = false
        end
    end
    return launchersDestroyed
end

function SkynetIADSSamSite:areTrackingRadarDestroyed()
    local trackRadarDestroyed = true
    local radars = self:getTrackingRadars()
    for i = 1, #radars do
        local radar = radars[i]
        if radar:isExist() then
            trackRadarDestroyed = false
        end
    end
    return trackRadarDestroyed
end

function SkynetIADSSamSite:areSearchRadarDestroyed()
    local searchRadarDestroyed = true
    local radars = self:getSearchRadars()
    for i = 1, #radars do
        local radar = radars[i]
        if radar:isExist() then
            searchRadarDestroyed = false
        end
    end
    return searchRadarDestroyed
end

function SkynetIADSSamSite:targetCycleUpdateStart()
	self.targetsInRange = false
end

function SkynetIADSSamSite:targetCycleUpdateEnd()
	if self.targetsInRange == false and self.actAsEW == false and self:getAutonomousState() == false and self:getAutonomousBehaviour() == SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DCS_AI then
		self:goDark()
	end
end

function SkynetIADSSamSite:informOfContact(contact)
	-- we make sure isTargetInRange (expensive call) is only triggered if no previous calls to this method resulted in targets in range
	if ( self.targetsInRange == false and self:isTargetInRange(contact) and ( contact:isIdentifiedAsHARM() == false or ( contact:isIdentifiedAsHARM() == true and self:getCanEngageHARM() == true ) ) ) then
		self:goLive()
		self.targetsInRange = true
	end
end

end
