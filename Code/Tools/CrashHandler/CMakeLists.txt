#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_PATH}/Code/Tools/CrashHandler/Platform/${O3DE_PAL_PLATFORM_NAME} pal_code_tools_crashhandler_path)
#set(common_code_tools_crashhandler_path ${O3DE_ENGINE_PATH}/Code/Tools/CrashHandler/Platform/Common)

include(${pal_code_tools_crashhandler_path}/PAL_${O3DE_PAL_PLATFORM_WART}.cmake)

if(NOT O3DE_PAL_TRAIT_BUILD_EXTERNAL_CRASH_HANDLER_SUPPORTED)
    return()
endif()

add_subdirectory(Support)

o3de_add_target(
    NAME CrashHandler STATIC
    NAMESPACE AZ
    FILES_CMAKE
        crash_handler_files.cmake
        ${pal_code_tools_crashhandler_path}/crash_handler_${O3DE_PAL_PLATFORM_WART}_files.cmake
        ${pal_code_tools_crashhandler_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            Shared
        PRIVATE
            ${pal_code_tools_crashhandler_path}
    COMPILE_DEFINITIONS
        PUBLIC
            EXTERNAL_CRASH_REPORTING
    BUILD_DEPENDENCIES
        PUBLIC
            AZ::CrashSupport
        PRIVATE
            3rdParty::Crashpad
            AZ::AzFramework
)

# Derive the EXE version fields. O3DE_INSTALL_VERSION_STRING is only set
# for installer builds; fall back to the engine version, then 0.0.0.0.
set(_crash_handler_version "${O3DE_INSTALL_VERSION_STRING}")
if(NOT _crash_handler_version)
    get_property(_crash_handler_version GLOBAL PROPERTY O3DE_ENGINE_VERSION)
endif()
if(NOT _crash_handler_version)
    set(_crash_handler_version "0.0.0.0")
endif()
string(REPLACE "." ";" version_list "${_crash_handler_version}")
list(LENGTH version_list version_component_count)
while(version_component_count LESS 2)
    list(APPEND version_list 0)
    list(LENGTH version_list version_component_count)
endwhile()
list(GET version_list 0 EXE_VERSION_INFO_0)
list(GET version_list 1 EXE_VERSION_INFO_1)

list(LENGTH version_list version_component_count)
if(${version_component_count} GREATER_EQUAL 3)
    list(GET version_list 2 EXE_VERSION_INFO_2)
else()
    set(EXE_VERSION_INFO_2 0)
endif()

if(${version_component_count} GREATER_EQUAL 4)
    list(GET version_list 3 EXE_VERSION_INFO_3)
else()
    set(EXE_VERSION_INFO_3 0)
endif()

# O3DE_INSTALL_BUILD_VERSION is only set for installer builds; fall back to
# the engine build number, then 0, so O3DE_BUILD never expands empty.
if(NOT O3DE_INSTALL_BUILD_VERSION)
    get_property(O3DE_INSTALL_BUILD_VERSION GLOBAL PROPERTY O3DE_ENGINE_BUILD)
endif()
if(NOT O3DE_INSTALL_BUILD_VERSION)
    set(O3DE_INSTALL_BUILD_VERSION 0)
endif()
o3de_add_source_properties(
    SOURCES Shared/CrashHandler.cpp
    PROPERTY COMPILE_DEFINITIONS 
    VALUES
        O3DE_BUILD=${O3DE_INSTALL_BUILD_VERSION}
        EXE_VERSION_INFO_0=${EXE_VERSION_INFO_0}
        EXE_VERSION_INFO_1=${EXE_VERSION_INFO_1}
        EXE_VERSION_INFO_2=${EXE_VERSION_INFO_2}
        EXE_VERSION_INFO_3=${EXE_VERSION_INFO_3}
)

o3de_add_target(
    NAME CrashUploaderSupport STATIC
    NAMESPACE AZ
    FILES_CMAKE
        crash_uploader_support_files.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            Uploader/include
        PRIVATE
            Uploader/include/Uploader
    BUILD_DEPENDENCIES
        PUBLIC
            3rdParty::Crashpad::Handler
            AZ::CrashSupport
)

add_subdirectory(Tools)
