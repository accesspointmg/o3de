#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(pal_code_source_path ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/${O3DE_PAL_PLATFORM_NAME})
set(pal_common_code_source_path ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/Common)

o3de_add_target(
    NAME ${gem_name}.Static STATIC
    NAMESPACE Gem
    PLATFORM_INCLUDE_FILES
        ${pal_code_source_path}/platform_${O3DE_PAL_PLATFORM_WART}.cmake
    FILES_CMAKE
        achievements_files.cmake
        ${pal_code_source_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            Include
        PRIVATE
            Source
    BUILD_DEPENDENCIES
        PUBLIC
            AZ::AzCore
            AZ::AzFramework
)

o3de_add_target(
    NAME ${gem_name} ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        achievements_shared_files.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            Include
        PRIVATE
            Source
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::${gem_name}.Static
)

# Inject the gem name into the Module source file
o3de_add_source_properties(
    SOURCES
        Source/AchievementsModule.cpp
    PROPERTY COMPILE_DEFINITIONS
        VALUES
            O3DE_GEM_NAME=${gem_name}
            O3DE_GEM_VERSION=${gem_version})

# we'll load the above "Gem::Achievements" module in clients only.
o3de_create_alias(NAME ${gem_name}.Clients NAMESPACE Gem TARGETS Gem::${gem_name})
