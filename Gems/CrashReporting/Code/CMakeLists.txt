#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

o3de_pal_path_object_json(${gem_json_path} ${CMAKE_CURRENT_LIST_DIR}/Platform/${O3DE_PAL_PLATFORM_NAME} pal_code_path)
set(pal_common_code_path ${CMAKE_CURRENT_LIST_DIR}/Platform/Common)

include(${pal_code_path}/PAL_${O3DE_PAL_PLATFORM_WART}.cmake)

if(NOT O3DE_PAL_TRAIT_BUILD_EXTERNAL_CRASH_HANDLER_SUPPORTED)
    return()
endif()

o3de_add_target(
    NAME ${gem_name} ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        crashreporting_static_files.cmake
        ${pal_code_path}/crashreporting_static_${O3DE_PAL_PLATFORM_WART}_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::CrashHandler
            AZ::AzCore
)

# Inject the gem name into the Module source file
o3de_add_source_properties(
    SOURCES
        Source/GameCrashHandler.cpp
    PROPERTY COMPILE_DEFINITIONS
        VALUES
            O3DE_GEM_NAME=${gem_name}
            O3DE_GEM_VERSION=${gem_version})

# Load the "Gem::${gem_name}" module in Clients and Servers
o3de_create_alias(NAME ${gem_name}.Clients NAMESPACE Gem TARGETS Gem::${gem_name})
o3de_create_alias(NAME ${gem_name}.Servers NAMESPACE Gem TARGETS Gem::${gem_name})
o3de_create_alias(NAME ${gem_name}.Unified NAMESPACE Gem TARGETS Gem::${gem_name})

if(NOT O3DE_MONOLITHIC_GAME)

    o3de_add_target(
        NAME ${gem_name}.Uploader APPLICATION
        NAMESPACE AZ
        FILES_CMAKE
            game_crash_uploader_files.cmake
            ${pal_code_path}/game_crash_uploader_${O3DE_PAL_PLATFORM_WART}_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Include
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::CrashUploaderSupport
    )

endif()
