#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

o3de_pal_path(${CMAKE_CURRENT_LIST_DIR}/Platform/${O3DE_PAL_PLATFORM_NAME} pal_code_path)
set(pal_common_code_path ${CMAKE_CURRENT_LIST_DIR}/Platform/Common)

o3de_add_target(
    NAME ${gem_name}.Static STATIC
    NAMESPACE Gem
    FILES_CMAKE
        lmbrcentral_headers_files.cmake
        lmbrcentral_files.cmake
        ${pal_code_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
            ${pal_code_path}
        PUBLIC
            include
    BUILD_DEPENDENCIES
        PRIVATE
            Legacy::CryCommon
            AZ::AzFramework
        PUBLIC
            Gem::AudioSystem.API
)

o3de_add_target(
    NAME ${gem_name}.API HEADERONLY
    NAMESPACE Gem
    FILES_CMAKE
        lmbrcentral_headers_files.cmake
    INCLUDE_DIRECTORIES
        INTERFACE
            include
)

o3de_add_target(
    NAME ${gem_name} ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        lmbrcentral_shared_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
            ${pal_code_path}
        PUBLIC
            include
    BUILD_DEPENDENCIES
        PRIVATE
            Legacy::CryCommon
            AZ::AzFramework
            Gem::${gem_name}.Static
)

# Inject the gem name into the Module source file
o3de_add_source_properties(
    SOURCES
        Source/LmbrCentral.cpp
    PROPERTY COMPILE_DEFINITIONS
        VALUES
            O3DE_GEM_NAME=${gem_name}
            O3DE_GEM_VERSION=${gem_version})

# by default, load the above "Gem::${gem_name}" module in Client and Server
o3de_create_alias(NAME ${gem_name}.Clients NAMESPACE Gem TARGETS Gem::${gem_name})
o3de_create_alias(NAME ${gem_name}.Servers NAMESPACE Gem TARGETS Gem::${gem_name})
o3de_create_alias(NAME ${gem_name}.Unified NAMESPACE Gem TARGETS Gem::${gem_name})


if (O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    o3de_add_target(
        NAME ${gem_name}.Editor.Static STATIC
        NAMESPACE Gem
        FILES_CMAKE
            lmbrcentral_editor_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Source
                ${pal_code_path}
            PUBLIC
                include
        COMPILE_DEFINITIONS
            PUBLIC
                LMBR_CENTRAL_EDITOR
        BUILD_DEPENDENCIES
            PRIVATE
                ${additional_dependencies}
            PUBLIC
                3rdParty::Qt::Widgets
                Legacy::CryCommon
                Legacy::Editor.Headers
                AZ::AzToolsFramework
                AZ::AssetBuilderSDK
                Gem::AudioSystem.API
    )

    o3de_add_target(
        NAME ${gem_name}.Editor GEM_MODULE

        NAMESPACE Gem
        FILES_CMAKE
            lmbrcentral_editor_shared_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Source
                ${pal_code_path}
            PUBLIC
                include
        BUILD_DEPENDENCIES
            PRIVATE
                3rdParty::Qt::Gui
                AZ::AzCore
                Gem::${gem_name}.Static
                Gem::${gem_name}.Editor.Static
                ${additional_dependencies}
    )

    # Inject the gem name into the Module source file
    o3de_add_source_properties(
        SOURCES
            Source/LmbrCentralEditor.cpp
        PROPERTY COMPILE_DEFINITIONS
            VALUES
                O3DE_GEM_NAME=${gem_name}
                O3DE_GEM_VERSION=${gem_version})

    include(${pal_code_path}/lrelease_${O3DE_PAL_PLATFORM_WART}.cmake)

    o3de_add_target_files(
        TARGETS ${gem_name}.Editor
        FILES ${lrelease_files}
    )

    # by default, load the above "Gem::${gem_name}.Editor" module in dev tools
    o3de_create_alias(NAME ${gem_name}.Builders NAMESPACE Gem TARGETS Gem::${gem_name}.Editor)
    o3de_create_alias(NAME ${gem_name}.Tools NAMESPACE Gem TARGETS Gem::${gem_name}.Editor)

endif()

add_subdirectory(Tests)
