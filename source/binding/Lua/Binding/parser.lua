---@diagnostic disable: inject-field
--[[

lua parser for maaframework

convert fw c api to binding code

]]
   --


local io = io
local table = table
local string = string

local api_path = assert(arg[1], 'No MaaDef.h file path given!')
local def_path = api_path .. '/MaaDef.h'

local api_list = {
    "Instance/MaaController.h",
    -- "Instance/MaaCustomController.h",
    "Instance/MaaInstance.h",
    "Instance/MaaResource.h",
    -- "Task/MaaCustomAction.h",
    -- "Task/MaaCustomRecognizer.h",
    "Task/MaaSyncContext.h",
    "Utility/MaaBuffer.h",
    "Utility/MaaUtility.h",
}

local cpp_header =
[[ /* NOTE: This file is auto generated, DO NOT modify it. */
extern "C"
{
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
};

#include <MaaFramework/MaaAPI.h>
]]

local cpp_tail =
[[
extern "C" int luaopen_libMaaFrameworkLuaBinding(lua_State *L) {
    static const struct luaL_Reg maa [] = {
            %s
            {NULL, NULL}
    };

    luaL_newlib(L, maa);
    return 1;
}
]]

string.split = function(s, sep)
    sep = sep or "%s"
    local t = {}
    for str in string.gmatch(s, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

string.trim = function(s, chars)
    chars = chars or "%s" -- 默认去除空白字符
    local pattern = "^[" .. chars .. "]*(.-)[" .. chars .. "]*$"
    return (s:gsub(pattern, "%1"))
end

function table.serialize(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0

    local tmp = string.rep(" ", depth)

    if name then tmp = tmp .. name .. " = " end

    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

        for k, v in pairs(val) do
            tmp = tmp .. table.serialize(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end

        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[unsupported type]\""
    end

    return tmp
end

function table.count(tbl)
    local cnt = 0
    for _, v in pairs(tbl) do
        cnt = cnt + 1
    end
    return cnt
end

function table.contains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
end

function table.clone(tab)
    if tab == nil then
        return nil
    end
    local copy = {}
    for k, v in pairs(tab) do
        if type(v) == 'table' then
            copy[k] = table.clone(v)
        else
            copy[k] = v
        end
    end
    setmetatable(copy, table.clone(getmetatable(tab)))
    return copy
end


local basic_int_types = { "int8_t", "int16_t", "int32_t", "int64_t", "uint8_t", "uint16_t", "uint32_t", "uint64_t",
    "int_least8_t", "int_least16_t", "int_least32_t", "int_least64_t", "uint_least8_t", "uint_least16_t",
    "uint_least32_t", "uint_least64_t", "int_fast8_t", "int_fast16_t", "int_fast32_t", "int_fast64_t", "uint_fast8_t",
    "uint_fast16_t", "uint_fast32_t", "uint_fast64_t", "intptr_t", "uintptr_t", "intmax_t", "uintmax_t" }
local basic_int_ret_s = "lua_pushinteger(L, ret);"

local ret_s = {
    ["void"] = "",
    ["void*"] = "lua_pushlightuserdata(L, ret);",
    ["const char*"] = "lua_pushstring(L, ret);",
    ["default"] = "lua_pushlightuserdata(L, ret);", -- Default type, assume as void*
}

for _, v in ipairs(basic_int_types) do
    ret_s[v] = basic_int_ret_s
end

-- luaL_checkxxx
local param_types = {
    ["void*"] = "lua_touserdata(L, %d)",
    ["const char*"] = "luaL_checkstring(L, %d)",
    ["default"] = "lua_touserdata(L, %d)",
}
local basic_int_param_s = "luaL_checkinteger(L, %d)"
for _, v in ipairs(basic_int_types) do
    param_types[v] = basic_int_param_s
end


local function parse_retrun_type(file_path, types)
    types = types or {}
    local file = assert(io.open(file_path, 'r'), string.format("Open %s failed!", tostring(file_path)))

    local type_map = {}

    local stopFlag = true
    local param_list = {}
    for line in file:lines() do
        if line:match("^typedef") then
            -- note: will skip *MaaAPICallback
            local origin_type, alias_type = line:match("^typedef%s([%w%s*_]-)%s(%w+);$")
            if origin_type and alias_type then
                table.insert(param_list, {origin_type, alias_type})
            end
            -- print('#######')
            -- print(line)
            -- print(originType)
            -- print(aliasType)
        end
    end

    -- step1. fill basic types
    for _,v in pairs(param_list) do
        if ret_s[v[1]] and not types[v[2]] then
            types[v[2]] = v[1]
        end
    end

    -- step2. fill alias types
    while 1 do
        stopFlag = true
        for _,v in pairs(param_list) do
            if not types[v[2]] and types[v[1]] then
                types[v[2]] = types[v[1]]
                stopFlag = false
            end
        end

        if stopFlag then
            return types
        end
    end
end

local function parse_declaration(declaration)
    -- 匹配返回类型，函数名和参数列表
    local return_type, function_name, param_list = declaration:match("^([%w_%*]+)%s+(%w+)%((.-)%)%s*;*$")
    local parameters = {}

    -- 检查并解析参数列表，如果存在的话
    if param_list and #param_list > 0 then
        for param in param_list:gmatch("([^,]+)") do
            param = param:gsub("^%s+", ""):gsub("%s+$", "") -- 清除前后空格
            local type, name = param:match("([%w_%*]+)%s+([%w_]+)$")
            table.insert(parameters, { type = type, name = name })
        end
    end

    return {
        return_type = return_type,
        function_name = function_name,
        parameters = parameters
    }
end


local function parser_api(file_path)
    local file = assert(io.open(file_path, 'r'), string.format("Open %s failed!", tostring(file_path)))
    local ret = {}
    local content = file:read("a") --[[@as string]]
    --[[
        1. 行头空格
        2. typedef
        3. 注释
        4. 注释
        5. #endif之类
        6. 无用定义
        7. extern开头的行
        8. 大括号丢掉
        9. 格式化(后的空格
        10. 格式化)前的空格
    ]]--

    content = content:gsub("^%s+", ""):gsub("typedef.-\n",""):gsub("/%*.-%*/", ""):gsub("//.-\n", ""):gsub("#.-\n", ""):gsub("MAA_FRAMEWORK_API", ""):gsub("extern.-\n", ""):gsub("[{}\n]", ""):gsub("%(%s*", "("):gsub(",%s*", ", ")
    local funcs = string.split(content, ";")
    for k, v in pairs(funcs) do
        funcs[k] = string.trim(v)
    end
    for _, line in pairs(funcs) do
        local parse_result = parse_declaration(line)
        table.insert(ret, parse_result)
        -- (table.serialize(ret))
    end
    return ret
end

local cpp_func_template_header = "static int %s(lua_State *L){\n"
local cpp_func_template_arg = "    %s %s = (%s)%s;\n"
local cpp_func_template_normal_ret = "    %s %s = %s(%s);\n    %s\n    return 1;\n}\n" -- return type no ';'
local cpp_func_template_void_ret   = "    %s(%s);\n    return 0;\n}\n"

local function get_arg_cpp(key, real_types)
    local param_key = real_types[key]
    if not param_key then
        param_key = "default"
    end
    return param_types[param_key]
end

local function get_ret_cpp(key, real_types)
    local ret_key = real_types[key]
    if not ret_key then
        ret_key = "default"
    end
    return string.format(ret_s[ret_key])
end

local function ast2cpp(ast, real_types, funcs)
    local content = ""
    for _,v in pairs(ast) do
        content = content..string.format(cpp_func_template_header, "Lua_"..v.function_name)
        table.insert(funcs, "Lua_"..v.function_name)
        local arg_cnt = 1
        local arg_str = ""
        for _, arg in ipairs(v.parameters) do
            local get_arg_func_str = string.format(get_arg_cpp(arg.type, real_types), arg_cnt)
            content = content..string.format(cpp_func_template_arg, arg.type, arg.name, arg.type, get_arg_func_str)
            arg_str = arg_str..arg.name..", "
            arg_cnt = arg_cnt + 1
        end
        arg_str = string.trim(arg_str,", ")
        local get_ret_func_str = get_ret_cpp(v.return_type, real_types)
        if string.len(get_ret_func_str) > 0 then
            content = content..string.format(cpp_func_template_normal_ret, v.return_type, "ret", v.function_name, arg_str, get_ret_func_str)
        else
            content = content..string.format(cpp_func_template_void_ret, v.function_name, arg_str, get_ret_func_str)
        end
    end

    return content, funcs
end

local function ast2lua(ast)
end

-- parser_api(api_path..'/'..api_list[1])

local function run()
    local basic_types = parse_retrun_type(def_path, {void="void"})

    -- print(table.serialize(basic_types))

    local cpp = assert(io.open("source/binding/Lua/Binding/src/cpp_test.cpp", "w+"))

    cpp:write(cpp_header)

    local cpp_content = ""..cpp_header
    for _,api in pairs(api_list) do
        print(api)
        local file_path = api_path..'/'..api
        local real_types = table.clone(basic_types)
        real_types = parse_retrun_type(file_path, real_types)
        local func_ast = parser_api(file_path)
        local funcs = {}
        local content = ast2cpp(func_ast, real_types, funcs)
        print(content)
        cpp:write(content)
    end

    cpp:close()
end

run()