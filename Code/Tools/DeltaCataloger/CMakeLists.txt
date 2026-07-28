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

if(O3DE_PAL_HOST_PLATFORM_NAME_LOWERCASE STREQUAL "windows")
o3de_add_target(
    NAME DeltaCataloger EXECUTABLE
    NAMESPACE AZ
    FILES_CMAKE
        deltacataloger_files.cmake
        deltacataloger_win_files.cmake
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            AZ::AzFramework
            AZ::AzToolsFramework
)
else()
o3de_add_target(
    NAME DeltaCataloger EXECUTABLE
    NAMESPACE AZ
    FILES_CMAKE
        deltacataloger_files.cmake
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            AZ::AzFramework
            AZ::AzToolsFramework
)
endif()

if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)

    o3de_add_target(
        NAME DeltaCataloger.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
        NAMESPACE AZ
        FILES_CMAKE
            deltacataloger_test_files.cmake
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzCore
                AZ::AzFramework
                AZ::AzTest
                AZ::AzToolsFramework
                AZ::AzToolsFrameworkTestCommon
    )

    o3de_add_googletest(
        NAME AZ::DeltaCataloger.Tests
        LABELS REQUIRES_tiaf
    )

endif()
