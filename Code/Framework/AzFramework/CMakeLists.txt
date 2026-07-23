#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

include(AzFramework/feature_options.cmake)

o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_PATH}/Code/Framework/AzFramework/Platform/${O3DE_PAL_PLATFORM_NAME} pal_code_framework_azframework_path)
set(common_code_framework_azframework_path ${O3DE_ENGINE_PATH}/Code/Framework/AzFramework/Platform/Common)

if(O3DE_PIX_ENABLED)
    set(AZ_FRAMEWORK_NATIVEUI_PIX_BUILD_DEPENDENCIES 3rdParty::pix)
endif()

o3de_add_target(
    NAME AzFramework STATIC
    NAMESPACE AZ
    FILES_CMAKE
        AzFramework/azframework_files.cmake
        ${pal_code_framework_azframework_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
    PLATFORM_INCLUDE_FILES
        ${pal_code_framework_azframework_path}/platform_${O3DE_PAL_PLATFORM_WART}.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            .
            ${pal_code_framework_azframework_path}
        PRIVATE
            ${common_code_framework_azframework_path}
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
        PUBLIC
            AZ::AzNetworking
            3rdParty::zstd
            3rdParty::lz4
)

o3de_add_target(
    NAME AzFramework.NativeUI STATIC
    NAMESPACE AZ
    FILES_CMAKE
        AzFramework/azframework_nativeui_files.cmake
        ${pal_code_framework_azframework_path}/platform_nativeui_${O3DE_PAL_PLATFORM_WART}_files.cmake
    PLATFORM_INCLUDE_FILES
        ${pal_code_framework_azframework_path}/platform_nativeui_${O3DE_PAL_PLATFORM_WART}.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            .
            ${pal_code_framework_azframework_path}
        PRIVATE
            ${common_code_framework_azframework_path}
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            AZ::AzFramework
            ${AZ_FRAMEWORK_NATIVEUI_PIX_BUILD_DEPENDENCIES}
)

set(O3DE_SEARCH_MODE_DEFINE $<$<BOOL:"${O3DE_ARCHIVE_FILE_SEARCH_MODE}">:O3DE_ARCHIVE_FILE_SEARCH_MODE=${O3DE_ARCHIVE_FILE_SEARCH_MODE}>)

o3de_add_source_properties(
    SOURCES
        AzFramework/Archive/ArchiveVars.cpp
    PROPERTY COMPILE_DEFINITIONS
    VALUES ${O3DE_SEARCH_MODE_DEFINE})

if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)

    o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_PATH}/Code/Framework/AzFramework/Tests/Platform/${O3DE_PAL_PLATFORM_NAME} pal_code_framework_azframework_tests_path)

    o3de_add_target(
        NAME AzFrameworkTestShared STATIC
        NAMESPACE AZ
        FILES_CMAKE
            Tests/framework_shared_tests_files.cmake
            AzFramework/Physics/physics_mock_files.cmake
            Tests/terrain_mock_files.cmake
        INCLUDE_DIRECTORIES
            PUBLIC
                Tests
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzCore
                AZ::AzFramework
            PUBLIC
                AZ::AzTest
                AZ::AzTestShared
    )
    
    if(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)

        o3de_add_target(
            NAME ProcessLaunchTest EXECUTABLE
            NAMESPACE AZ
            FILES_CMAKE
                Tests/process_launch_test_files.cmake
            INCLUDE_DIRECTORIES
                PRIVATE
                    Tests
            BUILD_DEPENDENCIES
                PRIVATE
                    AZ::AzCore
                    AZ::AzFramework
        )

        o3de_add_target(
            NAME AzFramework.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
            NAMESPACE AZ
            FILES_CMAKE
                Tests/frameworktests_files.cmake
                ${pal_code_framework_azframework_tests_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
            INCLUDE_DIRECTORIES
                PRIVATE
                    Tests
                    ${pal_code_framework_azframework_tests_path}
            BUILD_DEPENDENCIES
                PRIVATE
                    AZ::AzFramework
                    AZ::AzTest
                    AZ::AzTestShared
                    AZ::AzFrameworkTestShared
            RUNTIME_DEPENDENCIES
                AZ::ProcessLaunchTest
        )
        o3de_add_googletest(
            NAME AZ::AzFramework.Tests
            LABELS REQUIRES_tiaf;TIAF_shard_fixture
        )

        o3de_add_target(
            NAME AzFramework.NativeUI.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
            NAMESPACE AZ
            FILES_CMAKE
                Tests/framework_nativeui_tests_files.cmake
            INCLUDE_DIRECTORIES
                PRIVATE
                    Tests
                    ${pal_code_framework_azframework_tests_path}
            BUILD_DEPENDENCIES
                PRIVATE
                    AZ::AzFramework
                    AZ::AzFramework.NativeUI
                    AZ::AzTest
                    AZ::AzTestShared
                    AZ::AzFrameworkTestShared
            RUNTIME_DEPENDENCIES
                AZ::ProcessLaunchTest
        )
        o3de_add_googletest(
            NAME AZ::AzFramework.NativeUI.Tests
        )

        include(${pal_code_framework_azframework_tests_path}/platform_specific_test_targets.cmake)

    endif()

endif()
