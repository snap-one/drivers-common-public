-- Copyright 2025 Snap One, LLC. All rights reserved.

COMMON_URL_VER = 27

JSON = require ('drivers-common-public.module.json')

require ('drivers-common-public.global.lib')

Metrics = require ('drivers-common-public.module.metrics')


do --Globals
	GlobalTicketHandlers = GlobalTicketHandlers or {}

	ETag = ETag or {}
	MAX_CACHE = 100

	USE_NEW_URL = VersionCheck ('3.0.0')

	DEBUG_URL = DEBUG_URL or false

	SEND_SUCCESS_METRICS = SEND_SUCCESS_METRICS or false
end

do -- Globals defined by importing drivers
	-- functions

	--tables
	DEFAULT_URL_ARGS = DEFAULT_URL_ARGS
	APIBase = APIBase

	--string or bool
end



do --Setup Metrics
	MetricsURL = Metrics:new ('dcp_url', COMMON_URL_VER)
end

function MakeURL (path, args, suppressDefaultArgs)
	local url = {}
	local args = (type (args) == 'table' and args) or {}

	local schemePart, authorityPart, pathPart, pagePart, queryPart, fragmentPart

	if (DEFAULT_URL_ARGS and type (DEFAULT_URL_ARGS) == 'table' and suppressDefaultArgs ~= true) then
		for k, v in pairs (DEFAULT_URL_ARGS) do
			args [k] = v
		end
	end

	if (APIBase and path and not (string.find ((path or ''), '^http'))) then
		path = APIBase .. path
	end

	if (path) then
		local rest
		schemePart, rest = string.match (path, '(%a+:)(.*)')
		if (not (schemePart == 'http:' or schemePart == 'https:')) then
			return
		end

		authorityPart, path = string.match (rest, '(//.-/)(.*)')

		pathPart, pagePart = string.match (path, '(.*/)(.*)')
		if (pathPart == nil and pagePart == nil) then
			pagePart = path
		end

		local p, q = string.match (pagePart, '(.*)%?(.*)')
		if (p and q) then
			pagePart = p
			queryPart = q
		end

		if (queryPart) then
			local q, f = string.match (queryPart, '(.*)%#(.*)')
			if (q and f) then
				queryPart = q
				fragmentPart = f
			end
		else
			local p, f = string.match (pagePart, '(.*)%#(.*)')
			if (p and f) then
				pagePart = p
				fragmentPart = f
			end
		end

		if (pathPart) then
			local parts = {}
			for part in string.gmatch (pathPart, '([^%/]+)') do
				if (string.match (part, '%.%.$')) then
					table.remove (parts, #parts)
				else
					if (not (string.find (part, '?') or string.find (part, '#'))) then
						table.insert (parts, part)
					end
				end
			end
			table.insert (parts, '') --ensure trailing slash
			pathPart = table.concat (parts, '/')
		end

		if (queryPart) then
			args = args or {}
			for pair in string.gmatch (queryPart or '', '[^%&]+') do
				local k, v = string.match (pair, '(.+)%=(.+)')
				if (args [k] == nil) then
					args [k] = v
				end
			end
		end
	end

	if (schemePart) then
		table.insert (url, schemePart)
	end
	if (authorityPart) then
		table.insert (url, authorityPart)
	end
	if (pathPart) then
		table.insert (url, pathPart)
	end
	if (pagePart) then
		table.insert (url, pagePart)
	end

	local urlargs = {}
	for k, v in pairs (args) do
		table.insert (urlargs, URLEncode (k) .. '=' .. URLEncode (v))
	end

	if (#urlargs > 0) then
		table.sort (urlargs)
		if (path) then
			table.insert (url, '?')
		end

		local urlargs = table.concat (urlargs, '&')
		table.insert (url, urlargs)
	end

	if (fragmentPart) then
		table.insert (url, '#')
		table.insert (url, fragmentPart)
	end

	local url = table.concat (url)

	return (url)
end

function URLDecode (s, plusIsSpace)
	if (s == nil) then return '' end
	s = tostring (s)

	if (plusIsSpace == true) then
		s = string.gsub (s, '%+', ' ')
	end

	local _gsub = function (byte)
		local b = tonumber (byte, 16)
		return (string.char (b))
	end

	s = string.gsub (s, '%%(%x%x)', _gsub)

	return s
end

function URLEncode (s, spaceAsPercent)
	if (s == nil) then return '' end
	s = tostring (s)

	local _gsub = function (c)
		return string.format ('%%%02X', string.byte (c))
	end

	s = string.gsub (s, '([^%w%-%.%_%~% ])', _gsub)

	if (spaceAsPercent) then
		s = string.gsub (s, ' ', '%%20')
	else
		s = string.gsub (s, ' ', '+')
	end
	return s
end

function PrintCookies ()
	local cookies = {}

	for url, tab in pairs (C4:urlGetCookies ()) do
		table.insert (cookies, '------------------------')
		table.insert (cookies, url)
		for cookie, data in pairs (tab) do
			table.insert (cookies, '----> ' .. cookie)
			table.insert (cookies, data.value)
		end
		table.insert (cookies, '------------------------')
	end

	print (table.concat (cookies, '\r\n'))
end

function ReceivedAsync (ticketId, strData, responseCode, tHeaders, strError)
	for k, info in pairs (GlobalTicketHandlers) do
		if (info.TICKET == ticketId) then
			if (SEND_SUCCESS_METRICS) then
				MetricsURL:SetCounter ('RX')
			end
			table.remove (GlobalTicketHandlers, k)
			ProcessResponse (strData, responseCode, tHeaders, strError, info)
		end
	end
end

function ProcessResponse (strData, responseCode, tHeaders, strError, info)
	local eTagHit
	local eTagURL

	if (ETag) then
		local tag
		for k, v in pairs (tHeaders) do
			if (string.upper (k) == 'ETAG') then
				tag = v
			end
		end

		local url = info.URL

		for k, v in pairs (ETag) do
			if (v.url == url) then
				eTagURL = k
			end
		end

		if (responseCode == 200 and strError == nil) then
			if (strData == nil) then
				strData = ''
			end

			if (eTagURL) then
				table.remove (ETag, eTagURL)
			end
			if (tag and info.METHOD ~= 'DELETE') then
				local etagInfo = {
					url = url,
					strData = strData,
					tHeaders = tHeaders,
					tag = tag,
				}
				table.insert (ETag, 1, etagInfo)
			end
		elseif (tag and responseCode == 304 and strError == nil) then
			if (eTagURL) then
				eTagHit = true
				strData = ETag [eTagURL].strData
				tHeaders = ETag [eTagURL].tHeaders
				table.remove (ETag, eTagURL)
				local etagInfo = {
					url = url,
					strData = strData,
					tHeaders = tHeaders,
					tag = tag,
				}
				table.insert (ETag, 1, etagInfo)
				responseCode = 200
			end
		end

		while (#ETag > MAX_CACHE) do
			table.remove (ETag, #ETag)
		end
	end

	if (DEBUG_URL) then
		local t, ms
		if (C4.GetTime) then
			t = C4:GetTime ()
			ms = '.' .. tostring (t % 1000)
			t = math.floor (t / 1000)
		else
			t = os.time ()
			ms = ''
		end
		local s = os.date ('%x %X') .. ms

		local d = {
			'---',
			'RX ' .. s,
		}

		if (eTagHit) then
			table.insert (d, '---- ETAG CACHE HIT ----')
		end

		table.insert (d, '')
		table.insert (d, info.METHOD .. ' ' .. info.URL .. ' ' .. responseCode)

		if (strError ~= nil) then
			table.insert (d, '---- URL ERROR ----')
			table.insert (d, strError)
			table.insert (d, '-------------------')
		end

		for k, v in pairs (tHeaders) do
			if (k == 'Authorization') then
				table.insert (d, k .. ' = <hidden in print>')
			else
				table.insert (d, k .. ' = ' .. v)
			end
		end
		table.insert (d, '')
		table.insert (d, '-:PAYLOAD:-')
		table.insert (d, strData)
		table.insert (d, '-:PAYLOAD_ENDS:-')
		table.insert (d, '---')
		local d = table.concat (d, '\r\n')

		print (d)

		C4:DebugLog (d)
	end

	local data, isJSON, len

	for k, v in pairs (tHeaders) do
		if (string.upper (k) == 'CONTENT-TYPE') then
			if (string.find (v, 'application/json')) then
				isJSON = true
			end
		end
		if (string.upper (k) == 'CONTENT-LENGTH') then
			len = tonumber (v) or 0
		end
	end

	if (isJSON and strError == nil) then
		data = JSON:decode (strData)
		if (data == nil and len ~= 0) then
			print ('dcp_url: Content-Type indicated JSON but content is not valid JSON')

			MetricsURL:SetCounter ('Error_RX_JSON')

			data = { strData, }
		end
	else
		data = strData
	end

	if (DEBUG_URL) then
		DATA = data
		CONTEXT = info.CONTEXT
	end

	if (strError) then
		MetricsURL:SetString ('Error_RX', strError)
	end

	if (info.METHOD) then
		if (SEND_SUCCESS_METRICS) then
			MetricsURL:SetCounter ('RX_' .. info.METHOD)
		end
	end

	local success, ret
	if (info.CALLBACK and type (info.CALLBACK) == 'function') then
		success, ret = pcall (info.CALLBACK, strError, responseCode, tHeaders, data, info.CONTEXT, info.URL)
	end

	if (success == true) then
		return (ret)
	elseif (success == false) then
		MetricsURL:SetCounter ('Error_Callback')
		print ('URL response callback error: ', ret, info.URL)
	end
end

---@diagnostic disable-next-line: lowercase-global
function urlDo (method, url, data, headers, callback, context, options)
	local info = {}
	if (type (callback) == 'function') then
		info.CALLBACK = callback
	end

	if (context == nil) then
		context = {}
	end

	method = string.upper (method)

	info.CONTEXT = context
	info.URL = url
	info.METHOD = method

	headers = CopyTable (headers) or {}

	data = data or ''

	if (USER_AGENT == nil) then
		USER_AGENT = 'Control4/' .. C4:GetVersionInfo ().version .. '/' .. C4:GetDriverConfigInfo ('model') .. '/' .. C4:GetDriverConfigInfo ('version')
	end

	if (headers ['User-Agent'] == nil) then
		headers ['User-Agent'] = USER_AGENT
	end

	if (type (data) == 'table') then
		data = JSON:encode (data)
		headers ['Content-Type'] = 'application/json'
	end

	for _, etag in pairs (ETag or {}) do
		if (etag.url == url) then
			headers ['If-None-Match'] = etag.tag
		end
	end

	if (DEBUG_URL) then
		local t, ms
		if (C4.GetTime) then
			t = C4:GetTime ()
			ms = '.' .. tostring (t % 1000)
			t = math.floor (t / 1000)
		else
			t = os.time ()
			ms = ''
		end
		local s = os.date ('%x %X') .. ms


		local d = {
			'---',
			'TX ' .. s,
		}

		table.insert (d, '')
		table.insert (d, method .. ' ' .. url)
		for k, v in pairs (headers) do
			if (k == 'Authorization') then
				table.insert (d, k .. ' = <hidden in print>')
			else
				table.insert (d, k .. ' = ' .. v)
			end
		end
		table.insert (d, '')
		table.insert (d, '-:PAYLOAD:-')
		table.insert (d, data)
		table.insert (d, '-:PAYLOAD_ENDS:-')
		table.insert (d, '---')

		local d = table.concat (d, '\r\n')

		print (d)

		C4:DebugLog (d)
	end

	if (USE_NEW_URL) then
		local t = C4:url ()

		local startTime
		if (C4.GetTime) then
			startTime = C4:GetTime ()
		else
			startTime = os.time () * 1000
		end

		options = CopyTable (options) or {}

		if (options ['cookies_enable'] == nil) then
			options ['cookies_enable'] = true
		end

		if (options ['fail_on_error'] == nil) then
			options ['fail_on_error'] = false
		end

		t:SetOptions (options)

		local _onDone = function (transfer, responses, errCode, errMsg)
			if (SEND_SUCCESS_METRICS) then
				MetricsURL:SetCounter ('RX')
			end

			local endTime
			if (C4.GetTime) then
				endTime = C4:GetTime ()
			else
				endTime = os.time () * 1000
			end
			local interval = endTime - startTime
			if (SEND_SUCCESS_METRICS) then
				MetricsURL:SetTimer ('TXtoRX', interval)
			end

			if (errCode == -1 and errMsg == nil) then
				errMsg = 'Transfer cancelled'
			end

			local strError = errMsg

			local strData, responseCode, tHeaders = '', 0, {}

			if (errCode == 0) then
				strData = responses [#responses].body
				responseCode = responses [#responses].code
				tHeaders = responses [#responses].headers
			end

			ProcessResponse (strData, responseCode, tHeaders, strError, info)

			local processTime
			if (C4.GetTime) then
				processTime = C4:GetTime ()
			else
				processTime = os.time () * 1000
			end
			local interval = processTime - startTime
			if (SEND_SUCCESS_METRICS) then
				MetricsURL:SetTimer ('TXtoDone', interval)
			end
		end

		t:OnDone (_onDone)

		if (SEND_SUCCESS_METRICS) then
			MetricsURL:SetCounter ('TX')
		end

		if (method == 'GET') then
			t:Get (url, headers)
		elseif (method == 'POST') then
			t:Post (url, data, headers)
		elseif (method == 'PUT') then
			t:Put (url, data, headers)
		elseif (method == 'DELETE') then
			t:Delete (url, headers)
		else
			t:Custom (url, method, data, headers)
		end

		return t
	else
		local flags = CopyTable (options)

		if (flags == nil) then
			flags = {
				--response_headers_merge_redirects = false,
				cookies_enable = true,
			}
		end

		if (SEND_SUCCESS_METRICS) then
			MetricsURL:SetCounter ('TX')
		end

		if (method == 'GET') then
			info.TICKET = C4:urlGet (url, headers, false, ReceivedAsync, flags)
		elseif (method == 'POST') then
			info.TICKET = C4:urlPost (url, data, headers, false, ReceivedAsync, flags)
		elseif (method == 'PUT') then
			info.TICKET = C4:urlPut (url, data, headers, false, ReceivedAsync, flags)
		elseif (method == 'DELETE') then
			info.TICKET = C4:urlDelete (url, headers, false, ReceivedAsync, flags)
		else
			info.TICKET = C4:urlCustom (url, method, data, headers, false, ReceivedAsync, flags)
		end

		if (info.TICKET and info.TICKET ~= 0) then
			table.insert (GlobalTicketHandlers, info)
		else
			MetricsURL:SetCounter ('Error_TX')

			dbg ('C4.Curl error: ' .. info.METHOD .. ' ' .. url)
			if (callback) then
				pcall (callback, 'No ticket', nil, nil, '', context, url)
			end
		end

		return info
	end
end

---@diagnostic disable-next-line: lowercase-global
function urlGet (url, headers, callback, context, options)
	if (SEND_SUCCESS_METRICS) then
		MetricsURL:SetCounter ('TX_GET')
	end
	urlDo ('GET', url, nil, headers, callback, context, options)
end

---@diagnostic disable-next-line: lowercase-global
function urlPost (url, data, headers, callback, context, options)
	if (SEND_SUCCESS_METRICS) then
		MetricsURL:SetCounter ('TX_POST')
	end
	urlDo ('POST', url, data, headers, callback, context, options)
end

---@diagnostic disable-next-line: lowercase-global
function urlPut (url, data, headers, callback, context, options)
	if (SEND_SUCCESS_METRICS) then
		MetricsURL:SetCounter ('TX_PUT')
	end
	urlDo ('PUT', url, data, headers, callback, context, options)
end

---@diagnostic disable-next-line: lowercase-global
function urlDelete (url, headers, callback, context, options)
	if (SEND_SUCCESS_METRICS) then
		MetricsURL:SetCounter ('TX_DELETE')
	end
	urlDo ('DELETE', url, nil, headers, callback, context, options)
end

---@diagnostic disable-next-line: lowercase-global
function urlCustom (url, method, data, headers, callback, context, options)
	if (SEND_SUCCESS_METRICS) then
		MetricsURL:SetCounter ('TX_' .. method)
	end
	urlDo (method, url, data, headers, callback, context, options)
end
