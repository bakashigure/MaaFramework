cmake_minimum_required(VERSION 3.24)
project(MaaFrameworkLuaBinding)

file(
    GLOB
    maa_lua_binding_src
    src/*
    )

#add_library(MaaFrameworkLuaBinding SHARED ${maa_lua_binding_src})
add_executable(MaaFrameworkLuaBinding "src/test.cpp")

find_package(Lua)
target_include_directories(MaaFrameworkLuaBinding PRIVATE ${LUA_INCLUDE_DIR})
target_link_libraries(MaaFrameworkLuaBinding PRIVATE ${LUA_LIBRARIES})

target_include_directories(MaaFrameworkLuaBinding PRIVATE MaaFramework)
target_link_libraries(MaaFrameworkLuaBinding PRIVATE MaaFramework)



install(
    TARGETS MaaFrameworkLuaBinding
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION bin
    ARCHIVE DESTINATION lib)
