-- Simple Activate/Deactivate by group name
-- Base idea from https://github.com/Markoudstaal/DCS-Simple-Spawn-Menu
-- Requires MIST to be loaded first


-- Spawn or respawns a group
local function spawnGroup(groupName)
  if Group.getByName(groupName) then
    Group.activate(Group.getByName(groupName))
  else
    mist.respawnGroup(groupName, true)
  end
end

-- Despawns a group
local function despawnGroup(groupName)
  Group.destroy(Group.getByName(groupName))
end

-- Destroys a specific unit
local function exterminateUnit(unitName)
  Unit.destroy(Unit.getByName(unitName))
end

-- Create submenu and add groups to it

local groupMenuSEAD = missionCommands.addSubMenu("Auto-SA-11-Test-Menu")

local KillSSNOWDRIFT = missionCommands.addCommand("KILL SNOWDRIFT", groupMenuSEAD, exterminateUnit, "SAMVODY-SA-11-SD")
local KillEWRADAR = missionCommands.addCommand("KILL EW RADAR", groupMenuSEAD, exterminateUnit, "EWVODY-1L13-NW")
