--
-- DeepCultivator for LS 22
--
-- Glowins Modschmiede
 
DeepCultivator = {}

if DeepCultivator.MOD_NAME == nil then DeepCultivator.MOD_NAME = g_currentModName end
DeepCultivator.MODSETTINGSDIR = g_currentModSettingsDirectory

source(g_currentModDirectory.."tools/gmsDebug.lua")
GMSDebug:init(DeepCultivator.MOD_NAME, true, 2)

DeepCultivator.showKeys = true

-- Standards / Basics
function DeepCultivator.prerequisitesPresent(specializations)
  return true
end

function DeepCultivator.initSpecialization()
	dbgprint("initSpecialization : start", 2)
    local schemaSavegame = Vehicle.xmlSchemaSavegame
	local key = DeepCultivator.MOD_NAME..".DeepCultivator"
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)."..key.."#deepMode", "Deep mode enabled", false)
	dbgprint("initSpecialization: finished xmlSchemaSavegame registration process", 2)
end

function DeepCultivator.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", DeepCultivator)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", DeepCultivator)
	SpecializationUtil.registerEventListener(vehicleType, "saveToXMLFile", DeepCultivator)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", DeepCultivator)
 	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", DeepCultivator)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", DeepCultivator)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", DeepCultivator)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", DeepCultivator)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", DeepCultivator)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", DeepCultivator)
end

function DeepCultivator:onLoad(savegame)
	dbgprint("onLoad", 2)

	DeepCultivator.isDedi = g_server ~= nil and g_currentMission.connectedToDedicatedServer
	
	-- Make Specialization easier accessible
	self.spec_DeepCultivator = self["spec_"..DeepCultivator.MOD_NAME..".DeepCultivator"]
	
	local spec = self.spec_DeepCultivator
	spec.dirtyFlag = self:getNextDirtyFlag()
	
	spec.deepMode = false			
end

function DeepCultivator:onPostLoad(savegame)
	dbgprint("onPostLoad: "..self:getFullName(), 2)
	if savegame ~= nil then	
		local spec = self.spec_DeepCultivator
		dbgprint("onPostLoad : loading saved data", 2)
		local xmlFile = savegame.xmlFile
		local key = savegame.key .."."..DeepCultivator.MOD_NAME..".DeepCultivator"
		spec.deepMode = xmlFile:getValue(key.."#deepMode", spec.deepMode)
		dbgprint("onPostLoad : Loaded data for "..self:getName(), 1)
	end
end

function DeepCultivator:saveToXMLFile(xmlFile, key, usedModNames)
	dbgprint("saveToXMLFile", 2)
	local spec = self.spec_DeepCultivator
	if spec.deepMode then
		dbgprint("saveToXMLFile : key: "..tostring(key), 2)
		xmlFile:setValue(key.."#deepMode", spec.deepMode)
		dbgprint("saveToXMLFile : saving data finished", 2)
	end
end

function DeepCultivator:onReadStream(streamId, connection)
	dbgprint("onReadStream", 3)
	local spec = self.spec_DeepCultivator
	spec.deepMode = streamReadBool(streamId, connection)
end

function DeepCultivator:onWriteStream(streamId, connection)
	dbgprint("onWriteStream", 3)
	local spec = self.spec_DeepCultivator
	streamWriteBool(streamId, spec.deepMode)
end
	
function DeepCultivator:onReadUpdateStream(streamId, timestamp, connection)
	if not connection:getIsServer() then
		local spec = self.spec_DeepCultivator
		if streamReadBool(streamId) then
			dbgprint("onReadUpdateStream: receiving data...", 4)
			spec.deepMode = streamReadBool(streamId)
		end
	end
end

function DeepCultivator:onWriteUpdateStream(streamId, connection, dirtyMask)
	if connection:getIsServer() then
		local spec = self.spec_DeepCultivator
		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			dbgprint("onWriteUpdateStream: sending data...", 4)
			streamWriteBool(streamId, spec.deepMode)
		end
	end
end

-- inputBindings / inputActions
	
function DeepCultivator:onRegisterActionEvents(isActiveForInput)
	dbgprint("onRegisterActionEvents", 4)
	if self.isClient then
		local spec = self.spec_DeepCultivator
		DeepCultivator.actionEvents = {} 
		if self:getIsActiveForInput(true) and spec ~= nil then 
			local prio = GS_PRIO_LOW
			_, spec.actionEventMainSwitch = self:addActionEvent(DeepCultivator.actionEvents, 'TOGGLEDM', self, DeepCultivator.TOGGLE, false, true, false, true, nil)
			if spec.deepMode then
				g_inputBinding:setActionEventText(spec.actionEventMainSwitch, "Umschalten auf Grubber")
			else
				g_inputBinding:setActionEventText(spec.actionEventMainSwitch, "Umschalten auf Tiefengrubber")
			end
			g_inputBinding:setActionEventTextPriority(spec.actionEventMainSwitch, prio)
		end		
	end
end

function DeepCultivator:TOGGLE(actionName, keyStatus, arg3, arg4, arg5)
	dbgprint("TOGGLE", 4)
	local spec = self.spec_DeepCultivator
	dbgprint_r(spec, 4)
	
	spec.deepMode = not spec.deepMode
	if spec.deepMode then
		g_currentMission:addGameNotification(g_i18n.modEnvironments[DeepCultivator.MOD_NAME]:getText("deepModeHeader"), g_i18n.modEnvironments[DeepCultivator.MOD_NAME]:getText("deepModeOn"), "", 2500)
	else
		g_currentMission:addGameNotification(g_i18n.modEnvironments[DeepCultivator.MOD_NAME]:getText("deepModeHeader"), g_i18n.modEnvironments[DeepCultivator.MOD_NAME]:getText("deepModeOff"), "", 2500)
	end
	self:raiseDirtyFlags(spec.dirtyFlag)
end

-- change setting

function DeepCultivator:onUpdate(dt)
	local spec = self.spec_DeepCultivator
	local specCV = self.spec_cultivator
	
	if spec ~= nil and specCV ~= nil and spec.deepMode ~= specCV.isSubsoiler then
		specCV.isSubsoiler = spec.deepMode
	end
end

function DeepCultivator:onDraw(dt)
	local spec = self.spec_DeepCultivator
	if spec ~= nil and spec.deepMode then
		g_currentMission:addExtraPrintText(g_i18n.modEnvironments[DeepCultivator.MOD_NAME]:getText("deepModeShort"))
	end
end