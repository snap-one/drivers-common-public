-- Copyright 2021 Snap One, LLC. All rights reserved.

COMMON_URL_VER = 20

JSON = require ('drivers-common-public.module.json')

require ('drivers-common-public.global.lib')

Metrics = require ('drivers-common-public.module.metrics')


do	--Globals
	GlobalTicketHandlers = GlobalTicketHandlers or {}

	ETag = ETag or {}
	MAX_CACHE = 100

	USE_NEW_URL = VersionCheck ('3.0.0')
end

do	--Setup Metrics
	local namespace = {
		'driver.common.url.',
		C4:GetDriverConfigInfo ('name'),
	}
	namespace = table.concat (namespace)
	MetricsURL = Metrics:new (namespace)
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
			for part in string.gmatch (pathPart , '([^%/]+)') do
				if (string.match (part, '%.%.$')) then
					table.remove (parts, #parts)
				else
					if (not (string.find (part, '?') or string.find (part, '#'))) then
						table.insert (parts, part)
					end
				end
			end
			table.insert (parts, '')	--ensure trailing slash
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

		urlargs = table.concat (urlargs, '&')
		table.insert (url, urlargs)
	end

	if (fragmentPart) then
		table.insert (url, '#')
		table.insert (url, fragmentPart)
	end

	url = table.concat (url)

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
			MetricsURL:SetCounter ('RX', 1)
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
				table.insert (ETag, 1, {url = url, strData = strData, tHeaders = tHeaders, tag = tag})
			end

		elseif (tag and responseCode == 304 and strError == nil) then
			if (eTagURL) then
				eTagHit = true
				strData = ETag [eTagURL].strData
				tHeaders = ETag [eTagURL].tHeaders
				table.remove (ETag, eTagURL)
				table.insert (ETag, 1, {url = url, strData = strData, tHeaders = tHeaders, tag = tag})
				responseCode = 200
			end
		end

		while (#ETag > MAX_CACHE) do
			table.remove (ETag, #ETag)
		end
	end

	if (DEBUG_URL) then
		local d = {
			'---',
			'RX',
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
		d = table.concat (d, '\r\n')

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
			print ('Content-Type indicated JSON but content is not valid JSON')

			MetricsURL:SetCounter ('Error_RX_JSON', 1)

			data = {strData}
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
		MetricsURL:SetCounter ('RX_' .. info.METHOD, 1)
	end

	if (info.CALLBACK) then
		info.CALLBACK (strError, responseCode, tHeaders, data, info.CONTEXT, info.URL)
	end
	return
end

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
		local d = {
			'---',
			'TX',
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

		d = table.concat (d, '\r\n')

		print (d)

		C4:DebugLog (d)
	end

	if (USE_NEW_URL) then
		local t = C4:url ()

		options = CopyTable (options) or {}

		if (options ['cookies_enable'] == nil) then
			options ['cookies_enable'] = true
		end

		if (options ['fail_on_error'] == nil) then
			options ['fail_on_error'] = false
		end

		t:SetOptions (options)

		local _onDone = function (transfer, responses, errCode, errMsg)
			MetricsURL:SetCounter ('RX', 1)

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
		end

		t:OnDone (_onDone)

		MetricsURL:SetCounter ('TX', 1)

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
				cookies_enable = true
			}
		end

		MetricsURL:SetCounter ('TX', 1)

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
			MetricsURL:SetCounter ('Error_TX', 1)

			dbg ('C4.Curl error: ' .. info.METHOD .. ' ' .. url)
			if (callback) then
				pcall (callback, 'No ticket', nil, nil, '', context, url)
			end
		end

		return info
	end
end

function urlGet (url, headers, callback, context, options)
	MetricsURL:SetCounter ('TX_GET', 1)
	urlDo ('GET', url, data, headers, callback, context, options)
end

function urlPost (url, data, headers, callback, context, options)
	MetricsURL:SetCounter ('TX_POST', 1)
	urlDo ('POST', url, data, headers, callback, context, options)
end

function urlPut (url, data, headers, callback, context, options)
	MetricsURL:SetCounter ('TX_PUT', 1)
	urlDo ('PUT', url, data, headers, callback, context, options)
end

function urlDelete (url, headers, callback, context, options)
	MetricsURL:SetCounter ('TX_DELETE', 1)
	urlDo ('DELETE', url, data, headers, callback, context, options)
end

function urlCustom (url, method, data, headers, callback, context, options)
	MetricsURL:SetCounter ('TX_' .. method, 1)
	urlDo (method, url, data, headers, callback, context, options)
end
