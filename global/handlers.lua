-- Copyright 2021 Snap One, LLC. All rights reserved.

COMMON_HANDLERS = 10

--[[
	Inbound Driver Functions:
		-- ExecuteCommand (strCommand, tParams)
		FinishedWithNotificationAttachment ()
		GetNotificationAttachmentURL ()
		GetNotificationAttachmentFile ()
		GetNotificationAttachmentBytes ()
		GetPrivateKeyPassword (idBinding, nPort)
		ListEvent (strEvent, param1, param2)
		ListMIBReceived (strCommand, nCount, tParams)
		ListNewControl (strContainer, strNavID, idDevice, tParams)
		ListNewList (nListID, nItemCount, strName, nIndex, strContainer, strCategory, strNavID)
		OnBindingChanged (idBinding, strClass, bIsBound, otherDeviceID, otherBindngID)
		--OnConnectionStatusChanged (idBinding, nPort, strStatus)
		OnDriverDestroyed () -- in MSP
		OnDriverInit ()		 -- in MSP
		OnDriverLateInit ()	 -- in MSP
		OnDriverRemovedFromProject ()
		OnDeviceEvent (firingDeviceId, eventId)
		OnNetworkBindingChanged (idBinding, bIsBound)
		OnPoll (idBinding, bIsBound)
		-- OnPropertyChanged (strProperty)
		OnReflashLockGranted ()
		OnReflashLockRevoked ()
		OnServerConnectionStatusChanged (nHandle, nPort, strStatus)
		OnServerDataIn (nHandle, strData, strclientAddress, strPort)
		OnServerStatusChanged (nPort, strStatus)
		-- OnSystemEvent (event)
		OnTimerExpired (idTimer)
		-- OnVariableChanged (strVariable)
		-- OnWatchedVariableChanged (idDevice, idVariable, strValue)
		OnZigbeeOnlineStatusChanged (strStatus, strVersion, strSkew)
		OnZigbeePacketIn (strPacket, nProfileID, nClusterID, nGroupID, nSourceEndpoint, nDestinationEndpoint)
		OnZigbeePacketFailed (strPacket, nProfileID, nClusterID, nGroupID, nSourceEndpoint, nDestinationEndpoint)
		OnZigbeePacketSuccess (strPacket, nProfileID, nClusterID, nGroupID, nSourceEndpoint, nDestinationEndpoint)
		-- ReceivedAsync (ticketId, strData, responseCode, tHeaders, strError)
		-- ReceivedFromNetwork (idBinding, nPort, strData)
		-- ReceivedFromProxy (idBinding, strCommand, tParams)
		ReceivedFromSerial (idBinding, strData)
		--TestCondition (strConditionName, tParams)
		UIRequest (strCommand, tParams)


		DoPersistSave ()
		SetProperty ()
		SetGlobal ()

		OnBindingValidate (idBinding, strClass)

		OnUsbSerialDeviceOnline (idDevice, strManufacturer, strProduct, strSerialNum, strHostname, nFirstPort, nNumPorts)
		OnUsbSerialDeviceOffline ()

		Attach ()
		OnEndDebugSession ()

]]

--[[
	C4 System Events (from C4SystemEvents global) - valid values for OSE keys
	1	OnAll
	2	OnAlive
	3	OnProjectChanged
	4	OnProjectNew
	5	OnProjectLoaded
	6	OnPIP
	7	OnItemAdded
	8	OnItemNameChanged
	9	OnItemDataChanged
	10	OnDeviceDataChanged
	11	OnItemRemoved
	12	OnItemMoved
	13	OnDriverAdded
	14	OnDeviceIdentified
	15	OnBindingAdded
	16	OnBindingRemoved
	17	OnNetworkBindingAdded
	18	OnNetworkBindingRemoved
	19	OnNetworkBindingRegistered
	20	OnNetworkBindingUnregistered
	21	OnCodeItemAdded
	22	OnCodeItemRemoved
	23	OnCodeItemMoved
	24	OnMediaInfoAdded
	25	OnMediaInfoModified
	26	OnMediaRemovedFromDevice
	27	OnMediaDataRemoved
	28	OnSongAddedToPlaylist
	29	OnSongRemovedFromPlaylist
	30	OnPhysicalDeviceAdded
	31	OnPhysicalDeviceRemoved
	32	OnDataToUI
	33	OnAccessModeChanged
	34	OnVariableAdded
	35	OnUserVariableAdded
	36	OnVariableRemoved
	37	OnVariableRenamed
	38	OnVariableChanged
	39	OnVariableBindingAdded
	40	OnVariableBindingRemoved
	41	OnVariableBindingRenamed
	42	OnVariableAddedToBinding
	43	OnVariableRemovedFromBinding
	44	OnMediaDeviceAdded
	45	OnMediaDeviceRemoved
	46	OnProjectLocked
	47	OnProjectLeaveLock
	48	OnDeviceOnline
	49	OnDeviceOffline
	50	OnSearchTypeFound
	51	OnNetworkBindingStatusChanged
	52	OnZipcodeChanged
	53	OnLatitudeChanged
	54	OnLongitudeChanged
	55	OnDeviceAlreadyIdentified
	56	OnControllerDisabled
	57	OnDeviceFirmwareChanged
	58	OnLocaleChanged
	59	OnZigbeeNodesChanged
	60	OnZigbeeZapsChanged
	61	OnZigbeeMeshChanged
	62	OnZigbeeZserverChanged
	63	OnSysmanResponse
	64	OnTimezoneChanged
	65	OnMediaSessionAdded
	66	OnMediaSessionRemoved
	67	OnMediaSessionChanged
	68	OnMediaDeviceChanged
	69	OnProjectEnterLock
	70	OnDeviceIdentifiedNoLicense
	71	OnZigBeeStickPresent
	72	OnZigBeeStickRemoved
	73	OnZigbeeNodeUpdateStatus
	74	OnZigbeeNodeUpdateSucceeded
	75	OnZigbeeNodeUpdateFailed
	76	OnZigbeeNodeOnline
	77	OnZigbeeNodeOffline
	78	OnSDDPDeviceStatus
	79	OnSDDPDeviceDiscover
	80	OnAccountInfoUpdated
	81	OnAccountInfoUpdating
	82	OnBindingEntryAdded
	83	OnBindingEntryRemoved
	84	OnProjectClear
	85	OnSystemShutDown
	86	OnSystemUpdateStarted
	87	OnDevicePreIdentify
	88	OnDeviceIdentifying
	89	OnDeviceCancelIdentify
	90	OnDirectorIPAddressChanged
	91	OnDeviceDiscovered
	92	OnDeviceUserInitiatedRemove
	93	OnDriverDisabled
	94	OnDiscoveredDeviceAdded
	95	OnDiscoveredDeviceRemoved
	96	OnDiscoveredDeviceChanged
	97	OnDeviceIPAddressChanged
	98	OnCIDRRulesChanged
	99	OnBindingEntryRenamed
	100	OnCodeItemEnabled
	101	OnCodeItemCommandUpdated
	102	OnSystemUpdateFinished
	103	OnTimeChanged
	104	OnMediaSessionDiscreteMuteChanged
	105	OnMediaSessionMuteStateChanged
	106	OnMediaSessionDiscreteVolumeChanged
	107	OnMediaSessionVolumeLevelChanged
	108	OnMediaSessionMediaInfoChanged
	109	OnMediaSessionVolumeSliderStateChanged
	110	OnScheduledEvent
	111	OnMediaSessionSliderTargetVolumeReached
	112	OnCodeItemAddedToExpression
	113	OnProjectPropertyChanged
	114	OnEventAdded
	115	OnEventModified
	116	OnEventRemoved
	117	OnZigbeeNetworkHealth
]]

do	--Globals
	EC = EC or {}
	OBC = OBC or {}
	OCS = OCS or {}
	OPC = OPC or {}
	OSE = OSE or {}
	OVC = OVC or {}
	OWVC = OWVC or {}
	RFN = RFN or {}
	RFP = RFP or {}
	TC = TC or {}
	UIR = UIR or {}
end

function ExecuteCommand (strCommand, tParams)
	tParams = tParams or {}
	if (DEBUGPRINT) then
		local output = {'--- ExecuteCommand', strCommand, '----PARAMS----'}
		for k,v in pairs (tParams) do table.insert (output, tostring (k) .. ' = ' .. tostring (v)) end
		table.insert (output, '---')
		output = table.concat (output, '\r\n')
		print (output)
		C4:DebugLog (output)
	end

	if (strCommand == 'LUA_ACTION') then
		if (tParams.ACTION) then
			strCommand = tParams.ACTION
			tParams.ACTION = nil
		end
	end

	local success, ret

	strCommand = string.gsub (strCommand, '%s+', '_')

	if (EC and EC [strCommand] and type (EC [strCommand]) == 'function') then
		success, ret = pcall (EC [strCommand], tParams)
	end

	if (success == true) then
		return (ret)
	elseif (success == false) then
		print ('ExecuteCommand Lua error: ', strCommand, ret)
	end
end

function UIRequest (strCommand, tParams)
	strCommand = strCommand or ''
	tParams = tParams or {}

	if (DEBUGPRINT) then
		local output = {'--- UIRequest: ' .. strCommand, '----PARAMS----'}
		for k,v in pairs (tParams) do table.insert (output, tostring (k) .. ' = ' .. tostring (v)) end
		table.insert (output, '---')
		output = table.concat (output, '\r\n')
		print (output)
		C4:DebugLog (output)
	end

	local success, ret

	if (UIR and UIR [strCommand] and type (UIR [strCommand]) == 'function') then
		success, ret = pcall (UIR [strCommand], strCommand, tParams)
	end

	if (success == true) then
		return (ret)
	elseif (success == false) then
		print ('UIRequest Lua error: ', strCommand, ret)
	end
end

function OnBindingChanged (idBinding, strClass, bIsBound, otherDeviceId, otherBindingId)
	if (DEBUGPRINT) then
		local output = {'--- OnBindingChanged: ' .. idBinding, strClass, tostring (bIsBound), otherDeviceId, otherBindingId}
		output = table.concat (output, '\r\n')
		print (output)
		C4:DebugLog (output)
	end

	local success, ret

	if (OBC and OBC [idBinding] and type (OBC [idBinding]) == 'function') then
		success, ret = pcall (OBC [idBinding], idBinding, strClass, bIsBound, otherDeviceId, otherBindingId)
	end

	if (success == true) then
		return (ret)
	elseif (success == false) then
		print ('OnBindingChanged Lua error: ', idBinding, strClass, bIsBound, otherDeviceId, otherBindingId)
	end

end

function OnConnectionStatusChanged (idBinding, nPort, strStatus)
	if (DEBUGPRINT) then
		local output = {'--- OnConnectionStatusChanged: ' .. idBinding, nPort, strStatus}
		output = table.concat (output, '\r\n')
		print (output)
		C4:DebugLog (output)
	end

	local success, ret

	if (OCS and OCS [idBinding] and type (OCS [idBinding]) == 'function') then
		success, ret = pcall (OCS [idBinding], idBinding, nPort, strStatus)
	end

	if (success == true) then
		return (ret)
	elseif (success == false) then
		print ('OnConnectionStatusChanged Lua error: ', idBinding, nPort, strStatus, ret)
	end
end

function UpdateProperty (strProperty, strValue, notifyChange)
	if (Properties [strProperty] ~= strValue) then
		C4:UpdateProperty (strProperty, strValue)
	end
	if (notifyChange == true) then
		OnPropertyChanged (strProperty)
	end
end

function OnPropertyChanged (strProperty)
	local value = Properties [strProperty]
	if (value == nil) then
		value = ''
	end

	if (DEBUGPRINT) then
		local output = {'--- OnPropertyChanged: ' .. strProperty, value}
		output = table.concat (output, '\r\n')
		print (output)
		C4:DebugLog (output)
	end

	local success, ret

	strProperty = string.gsub (strProperty, '%s+', '_')

	if (OPC and OPC [strProperty] and type (OPC [strProperty]) == 'function') then
		success, ret = pcall (OPC [strProperty], value)
	end

	if (success == true) then
		return (ret)
	elseif (success == false) then
		print ('OnPropertyChanged Lua error: ', strProperty, ret)
	end
end

function OnSystemEvent (event)
	local eventName = string.match (event, '.-name="(.-)"')

	local success, ret

	if (OSE) then
		eventName = string.gsub (eventName, '%s+', '_')
		if (OSE [eventName] and type (OSE [eventName]) == 'function') then
			success, ret = pcall (OSE [eventName], event)
		end
	end

	if (success == true) then
		return (ret)
	elseif (success == false) then
		print ('OnSystemEvent Lua error: ', event, ret)
	end
end

function SetVariable (strVariable, strValue, notifyChange)
	C4:SetVariable (strVariable, strValue)
	if (notifyChange == true) then
		OnVariableChanged (strVariable)
	end
end

function OnVariableChanged (strVariable)
	local value = Variables [strVariable]
	if (value == nil) then
		value = ''
	end

	if (DEBUGPRINT) then
		local output = {'--- OnVariableChanged: ' .. strVariable, value}
		output = table.concat (output, '\r\n')
		print (output)
		C4:DebugLog (output)
	end

	local success, ret

	strVariable = string.gsub (strVariable, '%s+', '_')

	if (OVC and OVC [strVariable] and type (OVC [strVariable]) == 'function') then
		success, ret = pcall (OVC [strVariable], value)
	end

	if (success == true) then
		return (ret)
	elseif (success == false) then
		print ('OnVariableChanged Lua error: ', strVariable, ret)
	end
end

function RegisterVariableListener (idDevice, idVariable, callback)
	C4:UnregisterVariableListener (idDevice, idVariable)

	OWVC [idDevice] = OWVC [idDevice] or {}

	OWVC [idDevice] [idVariable] = function (idDevice, idVariable, strValue)
		pcall (callback, idDevice, idVariable, strValue)
	end

	C4:RegisterVariableListener (idDevice, idVariable)
end

function UnregisterVariableListener (idDevice, idVariable)
	if (OWVC and OWVC [idDevice]) then
		OWVC [idDevice] [idVariable] = nil
	end

	C4:UnregisterVariableListener (idDevice, idVariable)
end

function OnWatchedVariableChanged (idDevice, idVariable, strValue)
	if (DEBUGPRINT) then
		local output = {'--- OnWatchedVariableChanged: ' .. idDevice, idVariable, strValue}
		output = table.concat (output, '\r\n')
		print (output)
		C4:DebugLog (output)
	end

	local success, ret

	if (OWVC and
			OWVC [idDevice] and
			OWVC [idDevice] [idVariable] and
			type (OWVC [idDevice] [idVariable]) == 'function') then
		success, ret = pcall (OWVC [idDevice] [idVariable], idDevice, idVariable, strValue)
	end

	if (success == true) then
		return (ret)
	elseif (success == false) then
		print ('OnWatchedVariableChanged Lua error: ', strVariable, ret)
	end
end

function ReceivedFromNetwork (idBinding, nPort, strData)
	if (DEBUGPRINT) then
		local output = {'--- ReceivedFromNetwork: ' .. idBinding, nPort, #strData}
		if (DEBUG_RFN) then
			table.insert (output, strData)
		end
		output = table.concat (output, '\r\n')
		print (output)
		C4:DebugLog (output)
	end

	local success, ret

	if (RFN and RFN [idBinding] and type (RFN [idBinding]) == 'function') then
		success, ret = pcall (RFN [idBinding], idBinding, nPort, strData)
	end

	if (success == true) then
		return (ret)
	elseif (success == false) then
		print ('ReceivedFromNetwork Lua error: ', idBinding, nPort, strData, ret)
	end
end

function ReceivedFromProxy (idBinding, strCommand, tParams)
	strCommand = strCommand or ''
	tParams = tParams or {}
	local args = {}
	if (tParams.ARGS) then
		local parsedArgs = C4:ParseXml (tParams.ARGS)
		for _, v in pairs (parsedArgs.ChildNodes) do
			args [v.Attributes.name] = v.Value
		end
		tParams.ARGS = nil
	end

	if (DEBUGPRINT) then
		local output = {'--- ReceivedFromProxy: ' .. idBinding, strCommand, '----PARAMS----'}
		for k,v in pairs (tParams) do table.insert (output, tostring (k) .. ' = ' .. tostring (v)) end
		table.insert (output, '-----ARGS-----')
		for k,v in pairs (args) do table.insert (output, tostring (k) .. ' = ' .. tostring (v)) end
		table.insert (output, '---')
		output = table.concat (output, '\r\n')
		print (output)
		C4:DebugLog (output)
	end

	local success, ret

	if (RFP and RFP [strCommand] and type (RFP [strCommand]) == 'function') then
		success, ret = pcall (RFP [strCommand], idBinding, strCommand, tParams, args)

	elseif (RFP and RFP [idBinding] and type (RFP [idBinding]) == 'function') then
		success, ret = pcall (RFP [idBinding], idBinding, strCommand, tParams, args)
	end

	if (success == true) then
		return (ret)
	elseif (success == false) then
		print ('ReceivedFromProxy Lua error: ', idBinding, strCommand, ret)
	end
end

function TestCondition (strConditionName, tParams)
	strCommand = strConditionName or ''
	tParams = tParams or {}

	if (DEBUGPRINT) then
		local output = {'--- TestCondition: ' .. strConditionName, '----PARAMS----'}
		for k,v in pairs (tParams) do table.insert (output, tostring (k) .. ' = ' .. tostring (v)) end
		output = table.concat (output, '\r\n')
		print (output)
		C4:DebugLog (output)
	end

	local success, ret

	if (TC and TC [strConditionName] and type (TC [strConditionName]) == 'function') then
		success, ret = pcall (TC [strCommand], strConditionName, tParams)
	end

	if (success == true) then
		return (ret)
	elseif (success == false) then
		print ('TestCondition Lua error: ', idBinding, strCommand, ret)
	end
end