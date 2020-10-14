-- Copyright 2020 Wirepath Home Systems, LLC. All rights reserved.

--[[

	PLEASE ENSURE THAT YOU SQUISH AND ENCRYPT THIS WITH YOUR DRIVER

	Call with:

	--------------

	oauth_auth_code_grant = require ('oauth.auth_code_grant')

	SCOPES = {
		--insert required scopes here, or leave as nil if not needed
	}

	local tParams ={
		AUTHORIZATION = 'C4 API Key for OAuth ', -- provided by C4 on per-application basis

		REDIRECT_URI = 'aaa',		-- URL of the root of the redirect server implementing the OAuth-Node package from C4

		AUTH_ENDPOINT_URI = 'bbb',		-- URL of the API provided server that will return the authorization grant code token
		TOKEN_ENDPOINT_URI = 'ccc',		-- URL of the API provided server that will exchange a code token or refresh token for a new access token and refresh token

		REDIRECT_DURATION = 5 * ONE_MINUTE,	-- sets the time in seconds that the redirect server will be polled

		API_CLIENT_ID = 'ddd',
		API_SECRET = 'eee',

		SCOPES = SCOPES,

		USE_BASIC_AUTH_HEADER = nil,	--set to true if the OAuth API needs the Basic OAuth header set
	}

	auth = oauth_auth_code_grant:new (tParams)

	-----------------

	Then create handlers as needed for success/failure modes


	-----------------


	auth.notifyHandler.ActivationTimeOut = function (contextInfo) end
	auth.notifyHandler.LinkCodeReceived = function (contextInfo) end
	auth.notifyHandler.LinkCodeConfirmed = function (contextInfo, link) end
	auth.notifyHandler.LinkCodeWaiting = function (contextInfo) end
	auth.notifyHandler.LinkCodeError = function (contextInfo) end
	auth.notifyHandler.LinkCodeDenied = function (contextInfo, err, err_description, err_uri) end
	auth.notifyHandler.LinkCodeExpired = function (contextInfo) end
	auth.notifyHandler.AccessTokenGranted = function (contextInfo, accessToken, refreshToken) end
	auth.notifyHandler.AccessTokenDenied = function (contextInfo, err, err_description, err_uri) end

	-----------------

	Then start the auth process going with

	-----------------

		local contextInfo = {
			-- example values; these will be maintained and passed back to the handler functions
			value = math.random (1,100),
			time = os.time (),
		}

		-- any extra values to pass to the AUTH_ENDPOINT_URI during the request
		local extras = {
			show_dialog = 'true',
		}

		auth:MakeState (contextInfo, extras, uriToCompletePage)

]]

AUTH_CODE_GRANT_VER = 10

require ('drivers-common-public.global.url')
require ('drivers-common-public.global.timer')

local oauth = {}

function oauth:new (tParams)
	local o = {
		AUTHORIZATION = tParams.AUTHORIZATION,

		REDIRECT_URI = tParams.REDIRECT_URI,
		AUTH_ENDPOINT_URI = tParams.AUTH_ENDPOINT_URI,
		TOKEN_ENDPOINT_URI = tParams.TOKEN_ENDPOINT_URI,

		REDIRECT_DURATION = tParams.REDIRECT_DURATION,

		API_CLIENT_ID = tParams.API_CLIENT_ID,
		API_SECRET = tParams.API_SECRET,

		SCOPES = tParams.SCOPES,

		notifyHandler = {},
		Timer = {},
	}

	if (tParams.USE_BASIC_AUTH_HEADER) then
		o.BasicAuthHeader = 'Basic ' .. C4:Base64Encode (tParams.API_CLIENT_ID .. ':' .. tParams.API_SECRET)
	end

	setmetatable (o, self)
	self.__index = self

	return o
end

function oauth:MakeState (contextInfo, extras, uriToCompletePage)
	--print ('MakeState', contextInfo, extras, uriToCompletePage)
	if (type (contextInfo) ~= 'table') then
		contextInfo = {}
	end

	local state = GetRandomString (50)

	local url = MakeURL (self.REDIRECT_URI .. 'state')

	local headers = {
		Authorization = self.AUTHORIZATION,
	}

	local data = {
		duration = self.REDIRECT_DURATION,
		clientId = self.API_CLIENT_ID,
		authEndpointURI = self.AUTH_ENDPOINT_URI,
		state = state,
		redirectURI = uriToCompletePage,
	}

	local context = {
		contextInfo = contextInfo,
		state = state,
		extras = extras
	}

	self:urlPost (url, data, headers, 'MakeStateResponse', context)
end

function oauth:MakeStateResponse (strError, responseCode, tHeaders, data, context, url)
	--print ('MakeStateResponse', strError, responseCode, tHeaders, data, context, url)
	if (strError) then
		dbg ('Error with MakeState', strError)
		return
	end

	local contextInfo = context.contextInfo

	if (responseCode == 200) then
		local state = context.state
		local extras = context.extras

		local nonce = data.nonce
		local expiresAt = data.expiresAt or (os.time () + self.REDIRECT_DURATION)

		local timeRemaining = expiresAt - os.time ()

		local _timedOut = function (timer)
			CancelTimer (self.Timer.CheckState)

			if (self.notifyHandler.ActivationTimeOut) then
				self.notifyHandler.ActivationTimeOut (contextInfo)
			end
		end

		self.Timer.GetCodeStatusExpired = SetTimer (self.Timer.GetCodeStatusExpired, timeRemaining * ONE_SECOND, _timedOut)

		local _timer = function (timer)
			self:CheckState (state, contextInfo, nonce)
		end
		self.Timer.CheckState = SetTimer (self.Timer.CheckState, 5 * ONE_SECOND, _timer, true)

		self:GetLinkCode (state, contextInfo, extras)
	end
end

function oauth:GetLinkCode (state, contextInfo, extras)
	--print ('GetLinkCode', state, contextInfo, extras)
	if (type (contextInfo) ~= 'table') then
		contextInfo = {}
	end

	local scope
	if (self.SCOPES) then
		if (type (self.SCOPES) == 'table') then
			scope = table.concat (self.SCOPES, ' ')
		elseif (type (self.SCOPES) == 'string') then
			scope = self.SCOPES
		end
	end

	local args = {
		client_id = self.API_CLIENT_ID,
		response_type = 'code',
		redirect_uri = self.REDIRECT_URI .. 'callback',
		state = state,
		scope = scope,
	}

	if (extras and type (extras) == 'table') then
		for k, v in pairs (extras) do
			args [k] = v
		end
	end

	local link = MakeURL (self.AUTH_ENDPOINT_URI, args)

	self.notifyHandler.LinkCodeReceived (contextInfo, link)
end

function oauth:CheckState (state, contextInfo, nonce)
	--print ('CheckState', state, contextInfo, nonce)
	if (type (contextInfo) ~= 'table') then
		contextInfo = {}
	end

	local url = MakeURL (self.REDIRECT_URI .. 'state', {state = state, nonce = nonce})

	self:urlGet (url, nil, 'CheckStateResponse', {state = state, contextInfo = contextInfo})
end

function oauth:CheckStateResponse (strError, responseCode, tHeaders, data, context, url)
	--print ('CheckStateResponse', strError, responseCode, tHeaders, data, context, url)
	if (strError) then
		dbg ('Error with CheckState:', strError)
		return
	end

	local contextInfo = context.contextInfo

	if (responseCode == 200 and data.code) then
		-- state exists and has been authorized
		CancelTimer (self.Timer.CheckState)
		CancelTimer (self.Timer.GetCodeStatusExpired)

		if (self.notifyHandler.LinkCodeConfirmed) then
			self.notifyHandler.LinkCodeConfirmed (contextInfo)
		end

		self:GetUserToken (data.code, contextInfo)

	elseif (responseCode == 204) then
		if (self.notifyHandler.LinkCodeWaiting) then
			self.notifyHandler.LinkCodeWaiting (contextInfo)
		end

	elseif (responseCode == 401) then
		-- nonce value incorrect or missing for this state

		if (self.notifyHandler.LinkCodeError) then
			self.notifyHandler.LinkCodeError (contextInfo)
		end

		CancelTimer (self.Timer.CheckState)
		CancelTimer (self.Timer.GetCodeStatusExpired)

	elseif (responseCode == 403) then
		-- state exists and has been denied authorization by the service

		if (self.notifyHandler.LinkCodeDenied) then
			self.notifyHandler.LinkCodeDenied (contextInfo, data.error, data.error_description, data.error_uri)
		end

		CancelTimer (self.Timer.CheckState)
		CancelTimer (self.Timer.GetCodeStatusExpired)

	elseif (responseCode == 404) then
		-- state doesn't exist

		if (self.notifyHandler.LinkCodeExpired) then
			self.notifyHandler.LinkCodeExpired (contextInfo)
		end

		CancelTimer (self.Timer.CheckState)
		CancelTimer (self.Timer.GetCodeStatusExpired)
	end
end

function oauth:GetUserToken (code, contextInfo)
	--print ('GetUserToken', code, contextInfo)
	if (type (contextInfo) ~= 'table') then
		contextInfo = {}
	end

	if (code) then
		local args = {
			client_id = self.API_CLIENT_ID,
			client_secret = self.API_SECRET,
			grant_type = 'authorization_code',
			code = code,
			redirect_uri = self.REDIRECT_URI .. 'callback',
		}

		local url = self.TOKEN_ENDPOINT_URI

		local data = MakeURL (nil, args)

		local headers = {
			['Content-Type'] = 'application/x-www-form-urlencoded',
			['Authorization'] = self.BasicAuthHeader,
		}

		self:urlPost (url, data, headers, 'GetTokenResponse', {contextInfo = contextInfo})
	end
end

function oauth:RefreshToken (contextInfo, newRefreshToken)
	--print ('RefreshToken')

	if (newRefreshToken) then
		self.REFRESH_TOKEN = newRefreshToken
	end

	if (self.REFRESH_TOKEN == nil) then
		return
	end

	if (type (contextInfo) ~= 'table') then
		contextInfo = {}
	end

	local args = {
		refresh_token = self.REFRESH_TOKEN,
		client_id = self.API_CLIENT_ID,
		client_secret = self.API_SECRET,
		grant_type = 'refresh_token',
	}

	local url = self.TOKEN_ENDPOINT_URI

	local data = MakeURL (nil, args)

	local headers = {
		['Content-Type'] = 'application/x-www-form-urlencoded',
		['Authorization'] = self.BasicAuthHeader,
	}

	self:urlPost (url, data, headers, 'GetTokenResponse', {contextInfo = contextInfo})
end

function oauth:GetTokenResponse (strError, responseCode, tHeaders, data, context, url)
	--print ('GetTokenResponse', strError, responseCode, tHeaders, data, context, url)
	if (strError) then
		dbg ('Error with GetToken:', strError)
		local _timer = function (timer)
			self:RefreshToken ()
		end
		self.Timer.RefreshToken = SetTimer (self.Timer.RefreshToken, 30 * 1000, _timer)
		return
	end

	local contextInfo = context.contextInfo

	if (responseCode == 200) then
		self.ACCESS_TOKEN = data.access_token
		self.REFRESH_TOKEN = data.refresh_token or self.REFRESH_TOKEN

		self.SCOPE = data.scope or self.SCOPE

		self.EXPIRES_IN = data.expires_in

		if (self.EXPIRES_IN and self.REFRESH_TOKEN) then
			local _timer = function (timer)
				self:RefreshToken ()
			end

			self.Timer.RefreshToken = SetTimer (self.Timer.RefreshToken, self.EXPIRES_IN * 950, _timer)
		end

		if (self.notifyHandler.AccessTokenGranted) then
			self.notifyHandler.AccessTokenGranted (contextInfo, self.ACCESS_TOKEN, self.REFRESH_TOKEN)
		end

	elseif (responseCode >= 400 and responseCode < 500) then
		self.ACCESS_TOKEN = nil
		self.REFRESH_TOKEN = nil

		if (self.notifyHandler.AccessTokenDenied) then
			self.notifyHandler.AccessTokenDenied (contextInfo, data.error, data.error_description, data.error_uri)
		end
	end
end

function oauth:urlDo (method, url, data, headers, callback, context)
	local ticketHandler = function (strError, responseCode, tHeaders, data, context, url)
		local func = self [callback]
		local success, ret = pcall (func, self, strError, responseCode, tHeaders, data, context, url)
	end

	urlDo (method, url, data, headers, ticketHandler, context)
end

function oauth:urlGet (url, headers, callback, context)
	self:urlDo ('GET', url, data, headers, callback, context)
end

function oauth:urlPost (url, data, headers, callback, context)
	self:urlDo ('POST', url, data, headers, callback, context)
end

function oauth:urlPut (url, data, headers, callback, context)
	self:urlDo ('PUT', url, data, headers, callback, context)
end

function oauth:urlDelete (url, headers, callback, context)
	self:urlDo ('DELETE', url, data, headers, callback, context)
end

function oauth:urlCustom (url, method, data, headers, callback, context)
	self:urlDo (method, url, data, headers, callback, context)
end

return oauth
