do

redVodyIADS = SkynetIADS:create('VODYIADS')

-- Debug
-- Debug local object creation block commented out below
--[[
local iadsDebug = redVodyIADS:getDebugSettings()  
iadsDebug.IADSStatus = true
iadsDebug.contacts = true
--]]

-- Debug options block commented out below
--[[
iadsDebug.radarWentDark = true
iadsDebug.radarWentLive = true
iadsDebug.ewRadarNoConnection = true
iadsDebug.samNoConnection = true
iadsDebug.jammerProbability = true
iadsDebug.addedEWRadar = true
iadsDebug.hasNoPower = true
iadsDebug.addedSAMSite = true
iadsDebug.warnings = true
iadsDebug.harmDefence = true
iadsDebug.samSiteStatusEnvOutput = true
iadsDebug.earlyWarningRadarStatusEnvOutput = true
--]]

-- Will load separate red EW Radars 
-- each has GROUP=UNIT = EWVODY-1L13-NW & -E and -S
-- Previous had red AWACS named EWVODY-AWACS 1-1 so it would load too, but no longer
redVodyIADS:addEarlyWarningRadarsByPrefix('EWVODY')

redVodyIADS:addSAMSitesByPrefix('SAMVODY')


-- add a command center:
-- BUG BUG BUG - Without a command center, destroying the EW radar doesn't cause SAMS to go autonomous
commandCenter = StaticObject.getByName('Command-Center')
redVodyIADS:addCommandCenter(commandCenter)

-- Set the SA-15 by SA-11 as point defence for the SA-11 site, 
local sa15sa11 = redVodyIADS:getSAMSiteByGroupName('SAMVODY-SA-15-SA-11-DEFENSE')
local sa11 = redVodyIADS:getSAMSiteByGroupName('SAMVODY-SA-11')
sa11:addPointDefence(sa15sa11)
sa11:setHARMDetectionChance(97)
-- Skynet SAMs by default are set to have their engagement zone be when targets are in kill zone
-- This can be set for kill zone or search zone with
-- SkynetIADSAbstractRadarElement.GO_LIVE_WHEN_IN_KILL_ZONE
-- SkynetIADSAbstractRadarElement.GO_LIVE_WHEN_IN_SEARCH_RANGE
sa11:setEngagementZone(SkynetIADSAbstractRadarElement.GO_LIVE_WHEN_IN_KILL_ZONE)
-- Skynet SAMs can have their GoLive range as a percentage of their engagement zone (can be more than 100%)
-- Set this SA-11 site to go live at 105% of it's kill zone
sa11:setGoLiveRangeInPercent(105)

-- Force SA-15s to turn on earlier - in their default settings they're sometimes too late to block HARMS at the EW radar otherwise
sa15sa11:setEngagementZone(SkynetIADSAbstractRadarElement.GO_LIVE_WHEN_IN_SEARCH_RANGE):setGoLiveRangeInPercent(150)


-- Set the SA-15 by NW EW Radar as point defence for it
-- Set it to always react to a HARM so we can demonstrate the point defence mechanism in Skynet
local ewNW = redVodyIADS:getEarlyWarningRadarByUnitName('EWVODY-1L13-NW')
local sa15ewnw = redVodyIADS:getSAMSiteByGroupName('SAMVODY-SA-15-EW-NW-DEFENSE')
ewNW:addPointDefence(sa15ewnw):setHARMDetectionChance(96)

-- Force SA-15s to turn on earlier - in their default settings they're sometimes too late to block HARMS at the EW radar otherwise
sa15ewnw:setEngagementZone(SkynetIADSAbstractRadarElement.GO_LIVE_WHEN_IN_SEARCH_RANGE):setGoLiveRangeInPercent(150)

redVodyIADS:setUpdateInterval(1)

-- Have a menu item - shows IADS is actually running!
redVodyIADS:addRadioMenu()

-- In case this wasn't getting set by default
sa11:setAutonomousBehaviour(SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DCS_AI)

--local telars = sa11:getLaunchers()
--for i = 1, #telars do
--  local launcher = telars[i]
--  launcher:setAutonomousBehaviour(SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DCS_AI)
--end

local radars = sa11:getTrackingRadars()
for i = 1, #radars do
  local radar = radars[i]
  radar:setAutonomousBehaviour(SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DCS_AI)
end

redVodyIADS:activate()

end