file(
    GLOB_RECURSE
    dlopen_testing_src
    *.cpp
    *.h
    *.hpp)
    
add_executable(DlopenTesting ${dlopen_testing_src})

target_include_directories(DlopenTesting 
    PRIVATE ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/../../source/include ${CMAKE_CURRENT_SOURCE_DIR}/../../include)

target_link_libraries(DlopenTesting LibraryHolder)

if (WITH_ADB_CONTROLLER)
    target_compile_definitions(DlopenTesting PRIVATE WITH_ADB_CONTROLLER)
endif()
if (WITH_WIN32_CONTROLLER)
    target_compile_definitions(DlopenTesting PRIVATE WITH_WIN32_CONTROLLER)
endif()
if(WITH_THRIFT_CONTROLLER)
    target_compile_definitions(DlopenTesting PRIVATE WITH_THRIFT_CONTROLLER)
endif()
if (WITH_DBG_CONTROLLER)
    target_compile_definitions(DlopenTesting PRIVATE WITH_DBG_CONTROLLER)
endif()

add_dependencies(DlopenTesting LibraryHolder)

set_target_properties(DlopenTesting PROPERTIES FOLDER Testing)

install(TARGETS DlopenTesting RUNTIME DESTINATION bin)
