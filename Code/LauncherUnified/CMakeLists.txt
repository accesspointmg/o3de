#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_PATH}/Code/LauncherUnified/Platform/${O3DE_PAL_PLATFORM_NAME} pal_code_launcherunified_path)
set(common_code_launcherunified_path ${O3DE_ENGINE_PATH}/Code/LauncherUnified/Platform/Common)

include(${pal_code_launcherunified_path}/LauncherUnified_traits_${O3DE_PAL_PLATFORM_WART}.cmake)

o3de_add_target(
    NAME Launcher.Static STATIC
    NAMESPACE AZ
    FILES_CMAKE
        launcher_files.cmake
        ${pal_code_launcherunified_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
    PLATFORM_INCLUDE_FILES
        ${pal_code_launcherunified_path}/platform_${O3DE_PAL_PLATFORM_WART}.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            .
            ${pal_code_launcherunified_path}
    BUILD_DEPENDENCIES
        PUBLIC
            AZ::AzCore
            AZ::AzGameFramework
            Legacy::CryCommon
)

o3de_add_target(
    NAME Launcher.Headless.Static STATIC
    NAMESPACE AZ
    FILES_CMAKE
        launcher_files.cmake
        ${pal_code_launcherunified_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
    PLATFORM_INCLUDE_FILES
        ${pal_code_launcherunified_path}/platform_${O3DE_PAL_PLATFORM_WART}.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            .
            ${pal_code_launcherunified_path}
    BUILD_DEPENDENCIES
        PUBLIC
            AZ::AzCore
            AZ::AzGameFramework.Headless
            Legacy::CryCommon
)


o3de_add_target(
    NAME Launcher.Game.Static STATIC
    NAMESPACE AZ
    FILES_CMAKE
        launcher_game_files.cmake
        ${pal_code_launcherunified_path}/launcher_game_${O3DE_PAL_PLATFORM_WART}_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            .
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            AZ::AzGameFramework
            Legacy::CryCommon
)

if(O3DE_PAL_TRAIT_BUILD_SERVER_SUPPORTED)

    o3de_add_target(
        NAME Launcher.Server.Static STATIC
        NAMESPACE AZ
        FILES_CMAKE
            launcher_server_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                .
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzCore
                Legacy::CryCommon
    )

endif()

if(O3DE_PAL_TRAIT_BUILD_UNIFIED_SUPPORTED)

    o3de_add_target(
        NAME Launcher.Unified.Static STATIC
        NAMESPACE AZ
        FILES_CMAKE
            launcher_unified_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                .
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzCore
                AZ::AzGameFramework
                Legacy::CryCommon
    )

endif()

# launcher_generator.cmake consumes ${pal_dir} for per-platform launcher
# project includes
set(pal_dir ${pal_code_launcherunified_path})
include(${O3DE_ENGINE_PATH}/Code/LauncherUnified/launcher_generator.cmake)

################################################################################
# Tests
################################################################################
if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED AND O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    
    o3de_add_target(
        NAME Launcher.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
        NAMESPACE AZ
        FILES_CMAKE
            launcher_test_files.cmake
        COMPILE_DEFINITIONS
            PRIVATE
                O3DE_CMAKE_TARGET="Launcher_Tests"
        INCLUDE_DIRECTORIES
            PRIVATE
                . 
                ${pal_code_launcherunified_path}
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzTest
                AZ::Launcher.Static
    )
    o3de_add_googletest(
        NAME AZ::Launcher.Tests
        LABELS REQUIRES_tiaf
    )

endif()

################################################################################
# Install
################################################################################

o3de_install_files(
    FILES
        launcher_generator.cmake
        launcher_project_files.cmake
        LauncherProject.cpp
        StaticModules.in
    DESTINATION LauncherGenerator
)
o3de_install_directory(
    DIRECTORIES 
        ${pal_code_launcherunified_path}
        ${common_code_launcherunified_path}
    DESTINATION LauncherGenerator/Platform
    VERBATIM
)
o3de_install_files(
    FILES FindLauncherGenerator.cmake
    DESTINATION cmake
)
