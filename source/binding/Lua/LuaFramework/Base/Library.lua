require "Base.Class"

MaaFramework = MaaFramework or Class()

---get os type
---@return OsType?
function GetOsType()
    if package.config:sub(1,1) == '\\' then
        return 'Windows'
    else
        local handle = io.popen("uname -s")
        if not handle then
            return
        end
        local uname_ret = handle:read("*a")
        handle:close()
        uname_ret = string.gsub(uname_ret, '[\n\r]+', '')
        if uname_ret == "Linux" then
            return 'Linux'
        elseif uname_ret == "darwin" then
            return 'macOS'
        end
    end
end

function GetLibPrefix(os_type)
    if os_type == "Windows" then
        return ''
    else
        return 'lib'
    end
end

function GetLibSuffix(os_type)
    if os_type == 'Windows' then
        return 'dll'
    elseif os_type == 'Linux' then
        return 'so'
    elseif os_type == 'macOS' then
        return 'dylib'
    end
end

local libName = {
    ["Windows"] = function (lib)
        return lib..'.dll'
    end,
    ["Linux"] = function (lib)
        return 'lib'..lib..'.so'
    end,
    ["macOS"] = function (lib)
        return 'lib'..lib..'.dylib'
    end
}


---load library by xpcall
---@param lib string
function LoadLib(lib)
    local ok, library
    local lib_prefix = GetLibPrefix(GetOsType())
    assert(lib_prefix, '[Error] [Lua] unsupported os')

    lib = lib_prefix..lib


    ok, library = xpcall(function ()
        return require(lib)
    end, debug.traceback)

    if ok then
        print('load lib on: '..lib)
        return ok, library
    end
end



function MaaFramework:Ctor()
    -- local ok, lib = LoadLib('MaaFrameworkLuaBinding')
    self.lib = require "libMaaFrameworkLuaBinding"
    print(self.lib)
end

if not MaaFramework.__inited then
    package.cpath = package.cpath .. ";../../bin/?.so"


    MaaFramework:Ctor()
    MaaFramework.__inited = true
end

function MaaFramework:get_version()
    return self.lib.get_version()
end


return MaaFramework