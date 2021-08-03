-- Copyright 2021 Snap One, LLC. All rights reserved.

COMMON_METRICS_VER = 2

local Metrics = {}

function Metrics:new (namespace, options)
	if (type (namespace) ~= 'string') then
		print ('Metric namespace must be a non-empty string')
		return
	end
	if (#namespace == 0) then
		print ('Metric namespace must be a non-empty string')
		return
	end

	if (not (IN_PRODUCTION)) then
		namespace = 'sandbox.' .. namespace
	end

	namespace = string.gsub (namespace, '[%:%|%@% ]+', '_')

	namespace = namespace .. '.' .. tostring (C4:GetDeviceID ())

	if (Metrics.NameSpaces and Metrics.NameSpaces [namespace]) then
		local metric = Metrics.NameSpaces [namespace]
		return metric
	end

	options = options or {}

	local metric = {
		namespace = namespace,
	}

	setmetatable (metric, self)
	self.__index = self

	Metrics.NameSpaces = Metrics.NameSpaces or {}
	Metrics.NameSpaces [namespace] = metric

	return metric
end

function Metrics:SetCounter (key, value, sampleRate)
	if (not C4.StatsdCounter) then
		return
	end

	if (type (value) ~= 'number') then
		print ('Cannot set stats counter ' .. key .. ' to non-number value')
		return
	end

	key = string.gsub (key, '[%:%|%@% ]+', '_')

	C4:StatsdCounter (self.namespace, key, value, (sampleRate or 0))
end

function Metrics:SetGauge (key, value)
	if (not C4.StatsdGauge) then
		return
	end

	if (type (value) ~= 'number') then
		print ('Cannot set stats gauge ' .. key .. ' to non-number value')
		return
	end

	key = string.gsub (key, '[%:%|%@% ]+', '_')

	C4:StatsdGauge (self.namespace, key, value)
end

function Metrics:AdjustGauge (key, value)
	if (not C4.StatsdAdjustGauge) then
		return
	end

	if (type (value) ~= 'number') then
		print ('Trying to adjust stats gauge ' .. key .. ' by non-number value')
		return
	end

	key = string.gsub (key, '[%:%|%@% ]+', '_')

	C4:StatsdAdjustGauge (namespace, key, value)
end

function Metrics:SetTimer (key, value)
	if (not C4.StatsdTimer) then
		return
	end

	if (type (value) ~= 'number') then
		print ('Cannot set stats timer' .. key .. ' to non-number value')
		return
	end

	key = string.gsub (key, '[%:%|%@% ]+', '_')

	C4:StatsdTimer (self.namespace, key, value)
end

function Metrics:SetString (key, value)
	if (not C4.StatsdString) then
		return
	end

	if (type (value) ~= 'string') then
		print ('Cannot set stats string' .. key .. ' to non-string value')
		return
	end

	key = string.gsub (key, '[%:%|%@% ]+', '_')

	value = string.gsub (value, '[\r\n]+', '    ')

	C4:StatsdString (self.namespace, key, value)
end

function Metrics:SetJSON (key, value)
	if (not C4.StatsdJSONObject) then
		return
	end

	if (type (value) ~= 'string') then
		print ('Cannot set stats JSONObject' .. key .. ' to non-string value')
		return
	end

	key = string.gsub (key, '[%:%|%@% ]+', '_')

	value = string.gsub (value, '[\r\n]+', '    ')

	C4:StatsdJSONObject (self.namespace, key, value)
end

function Metrics.SetIncrementingMeter (key, value)
	if (not C4.StatsdIncrementMeter) then
		return
	end

	key = string.gsub (key, '[%:%|%@% ]+', '_')

	C4:StatsdIncrementMeter (self.namespace, key, value)
end

return Metrics