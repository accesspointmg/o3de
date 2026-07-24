#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(pal_code_include_path ${CMAKE_CURRENT_LIST_DIR}/Include/Platform/${O3DE_PAL_PLATFORM_NAME})
set(pal_common_code_include_path ${CMAKE_CURRENT_LIST_DIR}/Include/Platform/Common)

o3de_add_target(
    NAME ${gem_name}.Headers HEADERONLY
    NAMESPACE Gem
    FILES_CMAKE
        gamestatesamples_headers_files.cmake
    INCLUDE_DIRECTORIES
        INTERFACE
            Include
            ${pal_code_include_path}
    BUILD_DEPENDENCIES
        INTERFACE
            Gem::GameState
            Gem::LocalUser
            Gem::LyShine.Clients.API
            Gem::SaveData.Static
            Gem::MessagePopup.Static
            Legacy::CryCommon
)

o3de_add_target(
    NAME ${gem_name} ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        gamestatesamples_shared_files.cmake
        ${pal_code_include_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            AZ::AzFramework
            Gem::LmbrCentral
            Gem::${gem_name}.Headers
    RUNTIME_DEPENDENCIES
        Gem::GameState
        Gem::LocalUser
        Gem::LmbrCentral
)

# Inject the gem name into the Module source file
o3de_add_source_properties(
    SOURCES
        Source/GameStateSamplesModule.cpp
    PROPERTY COMPILE_DEFINITIONS
        VALUES
            O3DE_GEM_NAME=${gem_name}
            O3DE_GEM_VERSION=${gem_version})

# Clients and Servers use the above module, and it contains assets so is needed by builders.
o3de_create_alias(NAME ${gem_name}.Clients  NAMESPACE Gem TARGETS Gem::${gem_name})
o3de_create_alias(NAME ${gem_name}.Servers  NAMESPACE Gem TARGETS Gem::${gem_name})
o3de_create_alias(NAME ${gem_name}.Unified  NAMESPACE Gem TARGETS Gem::${gem_name})
o3de_create_alias(NAME ${gem_name}.Builders NAMESPACE Gem TARGETS Gem::UiBasics.Builders Gem::LyShineExamples.Builders)
