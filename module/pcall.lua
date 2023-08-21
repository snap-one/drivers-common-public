-- Copyright 2023 Snap One, LLC. All rights reserved.

-- By including this module, lua pcall function will be overriden to allow
-- logging any encountered errors in the datalake along with the traceback.

-- If the custom error handler is necessary, the 'OnLuaError' function needs 
-- to be explicitely defined.

COMMON_PCALL_VERSION = 1

do
    local metrics = require('drivers-common-public.module.metrics'):new()
    local __pcall = pcall
    function pcall(f, ...)
        local output = {__pcall(f, ...)}
        if not output[1] then
            __pcall(function()
                C4:ErrorLog(output[2])
            end)
            __pcall(function()
                C4:ErrorLog(debug.traceback(output[2]))
            end)
            __pcall(function()
                metrics:SetCounter("LuaErrorCount")
            end)
            __pcall(function()
                local data = {}
                data["message"] = output[2]
                data["traceback"] = debug.traceback(output[2])
                metrics:SetJSON("LuaError", C4:JsonEncode(data))
            end)
            __pcall(OnLuaError, output[2])
        end
        return unpack(output)
    end
end