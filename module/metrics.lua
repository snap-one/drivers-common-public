-- Copyright 2025 Snap One, LLC. All rights reserved.

COMMON_METRICS_VER = 9

local metricsObject = {}

do -- define globals
	DEBUG_METRICS = DEBUG_METRICS or false
end

function metricsObject:new (group, version, identifier)
	if (group == nil) then
		group = tostring (C4:GetDriverConfigInfo ('name'))
		version = tostring (C4:GetDriverConfigInfo ('version'))
	elseif (type (group) == 'string') then
		if (type (version) == 'number') then
			version = tostring (version)
		end
		if (type (version) ~= 'string') then
			error ('metricsObject:new - version is required when specifying a metric group', 2)
		end
	else
		error ('metricsObject:new - group must be a string or nil', 2)
		return
	end

	if (type (identifier) ~= 'string') then
		identifier = ''
	end

	local driverName = C4:GetDriverConfigInfo ('name')
	local driverId = tostring (C4:GetDeviceID ())

	group = self:GetSafeString (group)
	version = self:GetSafeString (version)
	identifier = self:GetSafeString (identifier, true)
	driverName = self:GetSafeString (driverName)
	driverId = self:GetSafeString (driverId)

	local namespace = {
		'drivers',
		group,
		version,
		identifier,
		driverName,
		driverId,
	}

	if (not (IN_PRODUCTION)) then
		table.insert (namespace, 1, 'sandbox')
	end

	local namespace = table.concat (namespace, '.')

	if (self.NameSpaces and self.NameSpaces [namespace]) then
		local metric = self.NameSpaces [namespace]
		return metric
	end

	local metric = {
		namespace = namespace,
	}

	setmetatable (metric, self)
	self.__index = self

	self.NameSpaces = self.NameSpaces or {}
	self.NameSpaces [namespace] = metric

	return metric
end

function metricsObject:SetCounter (key, value, sampleRate)
	---@diagnostic disable-next-line: undefined-field
	if (not C4.StatsdCounter) then
		return
	end

	if (type (key) ~= 'string') then
		error ('metricsObject:SetCounter - key must be a string', 2)
	end

	if (value == nil) then
		value = 1
	end

	if (type (value) ~= 'number') then
		error ('metricsObject:SetCounter - Cannot set counter ' .. tostring (key) .. ' to non-number value', 2)
	end

	key = self:GetSafeString (key)

	C4:StatsdCounter (self.namespace, key, value, (sampleRate or 0))
	if (DEBUG_METRICS) then
		print ('metricsObject:SetCounter:', self.namespace, key, tostring (value))
	end
end

function metricsObject:SetGauge (key, value)
	---@diagnostic disable-next-line: undefined-field
	if (not C4.StatsdGauge) then
		return
	end

	if (type (key) ~= 'string') then
		error ('metricsObject:SetGauge - Metric key must be a string', 2)
	end

	if (type (value) ~= 'number') then
		error ('metricsObject:SetGauge - Cannot set stats gauge ' .. tostring (key) .. ' to non-number value', 2)
	end

	key = self:GetSafeString (key)

	C4:StatsdGauge (self.namespace, key, value)
	if (DEBUG_METRICS) then
		print ('metricsObject:SetGauge:', self.namespace, key, tostring (value))
	end
end

function metricsObject:AdjustGauge (key, value)
	---@diagnostic disable-next-line: undefined-field
	if (not C4.StatsdAdjustGauge) then
		return
	end

	if (type (key) ~= 'string') then
		error ('metricsObject:AdjustGauge - Metric key must be a string', 2)
	end

	if (type (value) ~= 'number') then
		error ('metricsObject:AdjustGauge - Trying to adjust stats gauge ' .. tostring (key) .. ' by non-number value', 2)
	end

	key = self:GetSafeString (key)

	C4:StatsdAdjustGauge (self.namespace, key, value)
	if (DEBUG_METRICS) then
		print ('metricsObject:AdjustGauge:', self.namespace, key, tostring (value))
	end
end

function metricsObject:SetTimer (key, value)
	---@diagnostic disable-next-line: undefined-field
	if (not C4.StatsdTimer) then
		return
	end

	if (type (key) ~= 'string') then
		error ('metricsObject:SetTimer - Metric key must be a string', 2)
	end

	if (type (value) ~= 'number') then
		error ('metricsObject:SetTimer - Cannot set stats timer ' .. tostring (key) .. ' to non-number value', 2)
	end

	key = self:GetSafeString (key)

	C4:StatsdTimer (self.namespace, key, value)
	if (DEBUG_METRICS) then
		print ('metricsObject:SetTimer:', self.namespace, key, tostring (value))
	end
end

function metricsObject:SetString (key, value)
	---@diagnostic disable-next-line: undefined-field
	if (not C4.StatsdString) then
		return
	end

	if (type (key) ~= 'string') then
		error ('metricsObject:SetString - Metric key must be a string', 2)
	end

	if (type (value) ~= 'string') then
		error ('metricsObject:SetString - Cannot set stats string ' .. tostring (key) .. ' to non-string value', 2)
	end

	key = self:GetSafeString (key)

	value = string.gsub (value, '[\r\n]+', '    ')

	C4:StatsdString (self.namespace, key, value)
	if (DEBUG_METRICS) then
		print ('metricsObject:SetString:', self.namespace, key, tostring (value))
	end
end

function metricsObject:SetJSON (key, value)
	---@diagnostic disable-next-line: undefined-field
	if (not C4.StatsdJSONObject) then
		return
	end

	if (type (key) ~= 'string') then
		error ('metricsObject:SetJSON - Metric key must be a string', 2)
	end

	if (type (value) ~= 'string') then
		error ('metricsObject:SetJSON - Cannot set stats JSONObject ' .. tostring (key) .. ' to non-string value', 2)
	end

	key = self:GetSafeString (key)

	value = string.gsub (value, '[\r\n]+', '    ')

	C4:StatsdJSONObject (self.namespace, key, value)
	if (DEBUG_METRICS) then
		print ('metricsObject:SetJSON:', self.namespace, key, tostring (value))
	end
end

function metricsObject:SetIncrementingMeter (key, value)
	---@diagnostic disable-next-line: undefined-field
	if (not C4.StatsdIncrementMeter) then
		return
	end

	if (type (key) ~= 'string') then
		error ('metricsObject:SetIncrementingMeter - Metric key must be a string', 2)
	end

	if (type (value) ~= 'number') then
		error ('metricsObject:SetIncrementingMeter - Cannot set incremeting meter ' .. tostring (key) .. ' to non-number value', 2)
		return
	end

	key = self:GetSafeString (key)

	C4:StatsdIncrementMeter (self.namespace, key, value)
	if (DEBUG_METRICS) then
		print ('metricsObject:SetIncrementMeter:', self.namespace, key, tostring (value))
	end
end

function metricsObject:GetSafeString (s, ignoreUselessStrings)
	if (s == nil) then
		return
	end

	s = tostring (s)
	local p = '[^%w%-%_]+'
	local safe = string.gsub (s, p, '_')

	if (ignoreUselessStrings ~= true and string.gsub (safe, '_', '') == '') then
		error ('metricsObject:GetSafeString - generated a non-useful string', 3)
	end

	return safe
end

return metricsObject
