do

SkynetIADSAbstractElement = {}

function SkynetIADSAbstractElement:create()
	local instance = {}
	setmetatable(instance, self)
	self.__index = self
	instance.connectionNodes = {}
	instance.powerSources = {}
	return instance
end


function SkynetIADSAbstractElement:getLife()
	return self:getDCSRepresentation():getLife()
end

function SkynetIADSAbstractElement:addPowerSource(powerSource)
	table.insert(self.powerSources, powerSource)
end

function SkynetIADSAbstractElement:addConnectionNode(connectionNode)
	table.insert(self.connectionNodes, connectionNode)
end

function SkynetIADSAbstractElement:hasActiveConnectionNode()
	return self:genericCheckOneObjectIsAlive(self.connectionNodes)
end

function SkynetIADSAbstractElement:hasWorkingPowerSource()
	return self:genericCheckOneObjectIsAlive(self.powerSources)
end

function SkynetIADSAbstractElement:getDCSName()
	return self:getDCSRepresentation():getName()
end

-- generic function to theck if power plants, command centers, connection nodes are still alive
function SkynetIADSAbstractElement:genericCheckOneObjectIsAlive(objects)
	local isAlive = (#objects == 0)
	for i = 1, #objects do
		local object = objects[i]
		--trigger.action.outText("life: "..object:getLife(), 1)
		--if we find one object that is not fully destroyed we assume the IADS is still working
		if object:getLife() > 0 then
			isAlive = true
			break
		end
	end
	return isAlive
end

function SkynetIADSAbstractElement:setDCSRepresentation(representation)
	self.dcsRepresentation = representation
end

function SkynetIADSAbstractElement:getDCSRepresentation()
	return self.dcsRepresentation
end

function SkynetIADSAbstractElement:getController()
	return self:getDCSRepresentation():getController()
end

function SkynetIADSAbstractElement:getDBValues()
	local units = {}
	units[1] = self:getDCSRepresentation()
	if getmetatable(self:getDCSRepresentation()) == Group then
		units = self:getDCSRepresentation():getUnits()
	end
	local samDB = {}
	local unitData = nil
	local typeName = nil
	local natoName = ""
	for i = 1, #units do
		typeName = units[i]:getTypeName()
		for samName, samData in pairs(SkynetIADS.database) do
			--all Sites have a unique launcher, if we find one, we got the internal designator of the SAM unit
			unitData = SkynetIADS.database[samName]
			if unitData['launchers'] and unitData['launchers'][typeName] or unitData['searchRadar'] and unitData['searchRadar'][typeName] then
				samDB = self:extractDBName(samName)
				break
			end
		end
	end
	return samDB
end

function SkynetIADSAbstractElement:extractDBName(samName)
	local samDB = {}
	samDB['key'] =  samName
--	trigger.action.outText("Element is a: "..samName, 1)
	natoName = SkynetIADS.database[samName]['name']['NATO']
	local pos = natoName:find(" ")
	local prefix = natoName:sub(1, 2)
	--we shorten the SA-XX names and don't return their code names eg goa, gainful
	if string.lower(prefix) == 'sa' and pos ~= nil then
		natoName = natoName:sub(1, (pos-1))
	end
	samDB['nato'] = natoName
	return samDB
end

function SkynetIADSAbstractElement:getDBName()
	local dbName =  self:getDBValues()['key']
	if dbName == nil then
		dbName = "UNKNOWN"
	end
	return dbName
end

function SkynetIADSAbstractElement:getNatoName()
	local natoName = self:getDBValues()['nato']
	if natoName == nil then
		natoName = "UNKNOWN"
	end
	return natoName
end

function SkynetIADSAbstractElement:getDescription()
	return "IADS ELEMENT: "..self:getDCSRepresentation():getName().." | Type : "..tostring(self:getNatoName())
end

-- helper code for class inheritance
function inheritsFrom( baseClass )

    local new_class = {}
    local class_mt = { __index = new_class }

    function new_class:create()
        local newinst = {}
        setmetatable( newinst, class_mt )
        return newinst
    end

    if nil ~= baseClass then
        setmetatable( new_class, { __index = baseClass } )
    end

    -- Implementation of additional OO properties starts here --

    -- Return the class object of the instance
    function new_class:class()
        return new_class
    end

    -- Return the super class object of the instance
    function new_class:superClass()
        return baseClass
    end

    -- Return true if the caller is an instance of theClass
    function new_class:isa( theClass )
        local b_isa = false

        local cur_class = new_class

        while ( nil ~= cur_class ) and ( false == b_isa ) do
            if cur_class == theClass then
                b_isa = true
            else
                cur_class = cur_class:superClass()
            end
        end

        return b_isa
    end

    return new_class
end

end
