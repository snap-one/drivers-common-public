-- Copyright 2026 Snap One, LLC. All rights reserved.

MAKE_SHORT_LINK_VER = 8

require ('drivers-common-public.global.url')

function MakeShortLink (link, callback, apiKey, duration)
	local url
	if (IN_PRODUCTION) then
		url = 'https://link.ctrl4.co/new'
	else
		url = 'https://link.control4driversdev.com/new'
	end

	if (type (link) ~= 'string') then
		dbg ('Error MakeShortLink: link must be a string', link)
		return
	end

	if (type (apiKey) ~= 'string') then
		dbg ('Error MakeShortLink: apiKey must be a string', apiKey)
		return
	end

	if (type (duration) ~= 'number') then
		dbg ('Warning MakeShortLink: duration must be a number', duration)
		duration = nil
	end

	if (type (callback) ~= 'function') then
		dbg ('Warning MakeShortLink: callback must be a function', callback)
		callback = nil
	end

	local data = {
		url = link,
		duration = duration,
	}

	local headers = {
		Authorization = apiKey,
	}

	local contextInfo = {
		link = link,
		callback = callback,
	}

	urlPost (url, data, headers, MakeShortLinkResponse, contextInfo)
end

function MakeShortLinkResponse (strError, responseCode, tHeaders, data, context, url)
	if (strError) then
		dbg ('Error with MakeShortLinkResponse:', strError)
		return
	end

	local link = context.link -- original link to allow fallback if short link creation fails
	local callback = context.callback

	local expiresAt

	if (responseCode == 200) then
		link = data.url
		expiresAt = data.expiresAt
	end

	if (link) then
		if (type (callback) == 'function') then
			pcall (callback, link, expiresAt)
		end
	end
end
