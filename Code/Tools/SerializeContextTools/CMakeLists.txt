#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

if (NOT O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    return()
endif()

o3de_add_target(
    NAME SerializeContextTools.Private.Object OBJECT
    NAMESPACE AZ
    FILES_CMAKE
        serializecontexttools_object_files.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            .
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            AZ::AzFramework
            AZ::AzToolsFramework
)

o3de_add_target(
    NAME SerializeContextTools EXECUTABLE
    NAMESPACE AZ
    FILES_CMAKE
        serializecontexttools_files.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            .
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            AZ::AzFramework
            AZ::AzToolsFramework
            SerializeContextTools.Private.Object
)

if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
    o3de_add_target(
        NAME SerializeContextTools.Tests EXECUTABLE
        NAMESPACE AZ
        FILES_CMAKE
            serializecontexttools_tests_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                .
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzCore
                AZ::AzFramework
                AZ::AzToolsFramework
                AZ::AzToolsFrameworkTestCommon
                AZ::AzTest
                SerializeContextTools.Private.Object
    )

    o3de_add_googletest(
        NAME AZ::SerializeContextTools.Tests
        TEST_COMMAND $<TARGET_FILE:AZ::SerializeContextTools.Tests> AzRunUnitTests
    )
endif()
