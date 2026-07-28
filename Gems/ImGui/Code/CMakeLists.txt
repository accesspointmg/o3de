#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(O3DE_IMGUI_RELEASE_ENABLED ON CACHE BOOL "Allow IMGUI in release builds")
if($<CONFIG:release> AND NOT O3DE_IMGUI_RELEASE_ENABLED)
    set(config_base_defines IMGUI_DISABLED)
else()
    set(config_base_defines IMGUI_ENABLED)
endif()

set(pal_code_source_path ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/${O3DE_PAL_PLATFORM_NAME})
set(pal_common_code_source_path ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/Common)

# This library is the 3rdParty imgui that is in the Gem's External
o3de_add_target(
    NAME ${gem_name}.imguilib ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_LIBRARY_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        imgui_lib_files.cmake
        ${pal_code_source_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
    PLATFORM_INCLUDE_FILES
        ${pal_code_source_path}/imgui_${O3DE_PAL_PLATFORM_WART}.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
        INTERFACE
            ../External/ImGui/v1.82
        PUBLIC
            Include
    COMPILE_DEFINITIONS
        PUBLIC
            ${config_base_defines}
        INTERFACE
            $<$<NOT:$<BOOL:${O3DE_MONOLITHIC_GAME}>>:IMGUI_API_IMPORT>
            IMGUI_INCLUDE_IMGUI_USER_H
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
)

o3de_add_target(
    NAME ${gem_name}.ImGuiLYUtils STATIC
    NAMESPACE Gem
    FILES_CMAKE
        imgui_o3deutils_static_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Include
            Source
    BUILD_DEPENDENCIES
        PUBLIC
            Gem::${gem_name}.imguilib
            Legacy::CryCommon
    RUNTIME_DEPENDENCIES
        Gem::${gem_name}.imguilib
)

o3de_add_target(
    NAME ${gem_name}.Static STATIC
    NAMESPACE Gem
    FILES_CMAKE
        imgui_common_files.cmake
    PLATFORM_INCLUDE_FILES
        ${pal_code_source_path}/platform_${O3DE_PAL_PLATFORM_WART}.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PUBLIC
            Gem::${gem_name}.ImGuiLYUtils
        PRIVATE
            Gem::LmbrCentral
)

o3de_add_target(
    NAME ${gem_name} ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        imgui_shared_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
        PUBLIC 
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::${gem_name}.Static
    RUNTIME_DEPENDENCIES
        Gem::LmbrCentral
)

# Inject the gem name into the Module source file
o3de_add_source_properties(
    SOURCES
        Source/ImGuiGem.cpp
    PROPERTY COMPILE_DEFINITIONS
        VALUES
            O3DE_GEM_NAME=${gem_name}
            O3DE_GEM_VERSION=${gem_version})

# Load the above "Gem::${gem_name}" module in Clients and Servers:
o3de_create_alias(NAME ${gem_name}.Clients NAMESPACE Gem TARGETS Gem::${gem_name})
o3de_create_alias(NAME ${gem_name}.Servers NAMESPACE Gem TARGETS Gem::${gem_name})
o3de_create_alias(NAME ${gem_name}.Unified NAMESPACE Gem TARGETS Gem::${gem_name})

if(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    o3de_add_target(
        NAME ${gem_name}.Editor GEM_MODULE

        NAMESPACE Gem
        FILES_CMAKE
            imgui_editor_files.cmake
        COMPILE_DEFINITIONS
            PRIVATE
                IMGUI_GEM_EDITOR
        INCLUDE_DIRECTORIES
            PRIVATE
                .
                Editor
                Source
            PUBLIC
                Include
        BUILD_DEPENDENCIES
            PRIVATE
                Gem::${gem_name}.Static
        RUNTIME_DEPENDENCIES
            Gem::LmbrCentral.Editor
    )

    # Load the above "Gem::${gem_name}.Editor" module in only tools and builders.
    o3de_create_alias(NAME ${gem_name}.Builders NAMESPACE Gem TARGETS Gem::${gem_name}.Editor)
    o3de_create_alias(NAME ${gem_name}.Tools    NAMESPACE Gem TARGETS Gem::${gem_name}.Editor)

endif()
