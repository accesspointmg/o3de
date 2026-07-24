#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

if(NOT O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    return()
endif()

o3de_pal_path(${O3DE_ENGINE_PATH}/Code/Tools/LuaIDE/Platform/${O3DE_PAL_PLATFORM_NAME} pal_code_tools_luaide_source_path)
#set(common_code_tools_luaide_source_path ${O3DE_ENGINE_PATH}/Code/Tools/LuaIDE/Platform/Common)

o3de_add_target(
    NAME LuaIDE APPLICATION
    NAMESPACE AZ
    AUTOMOC
    AUTOUIC
    FILES_CMAKE
        lua_ide_files.cmake
        ${pal_code_tools_luaide_source_path}/lua_ide_${O3DE_PAL_PLATFORM_WART}_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            .
            Source/Editor
            Source/LUA
    BUILD_DEPENDENCIES
        PRIVATE
            Legacy::CryCommon
            AZ::AzCore
            AZ::AzFramework
            AZ::AzToolsFramework
            AZ::AzNetworking
            AZ::AzQtComponents
            ${additional_dependencies}
    COMPILE_DEFINITIONS 
        PRIVATE
            STANDALONETOOLS_ENABLE_LUA_IDE
)

if(O3DE_PAL_TRAIT_BUILD_EXTERNAL_CRASH_HANDLER_SUPPORTED)
    ly_target_link_libraries(LuaIDE PRIVATE AZ::ToolsCrashHandler)
endif()

o3de_set_gem_variant_to_load(TARGETS LuaIDE VARIANTS LuaTools)
o3de_add_dependencies(Editor LuaIDE)
