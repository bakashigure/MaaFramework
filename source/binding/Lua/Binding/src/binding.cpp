extern "C"
{
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
};

#include <MaaFramework/MaaAPI.h>


int get_version(lua_State *L) {
    const char* version = MaaVersion();
    lua_pushstring(L, version);
    return 1;
}

// static int maa_create(lua_State *L) {
//     luaL_checkinteger()
//     auto a = MaaCreate()
// }

// static int maa_destroy(lua_State *L) {
//     MaaDestroy()
// }

static int get_test(lua_State *L) {
    int a = 1;
    lua_pushinteger(L, a);
    return 1;
}

extern "C" int luaopen_libMaaFrameworkLuaBinding(lua_State *L) {
    static const struct luaL_Reg maa [] = {
            {"get_version", get_version},
            {"get_test", get_test},
            {NULL, NULL}
    };

    luaL_newlib(L, maa);
    return 1;
}
