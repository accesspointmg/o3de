#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_PATH}/Code/Tools/AWSNativeSDKInit/source/Platform/${O3DE_PAL_PLATFORM_NAME} pal_code_tools_awsnativeinit_source_path)
set(common_code_tools_awsnativeinit_source_path ${O3DE_ENGINE_PATH}/Code/Tools/AWSNativeSDKInit/source/Platform/Common)

o3de_add_target(
    NAME AWSNativeSDKInit STATIC
    NAMESPACE AZ
    FILES_CMAKE
        aws_native_sdk_init_files.cmake
        ${pal_code_tools_awsnativeinit_source_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            include
        PRIVATE
            ${pal_code_tools_awsnativeinit_source_path}
    BUILD_DEPENDENCIES
        PRIVATE
            3rdParty::AWSNativeSDK::AWSCore
            AZ::AzCore
)

################################################################################
# Tests
################################################################################
if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
    o3de_add_target(
        NAME AWSNativeSDKTestLibs STATIC
        NAMESPACE AZ
        FILES_CMAKE
            aws_native_sdk_test_files.cmake
        INCLUDE_DIRECTORIES
            PUBLIC
                include
                tests/libs
            PRIVATE
                source
        BUILD_DEPENDENCIES
            PRIVATE
                3rdParty::AWSNativeSDK::Core
                AZ::AzCore
                AZ::AzTest
    )

    o3de_add_target(
        NAME AWSNativeSDKInit.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
        NAMESPACE AZ
        FILES_CMAKE
            aws_native_sdk_init_tests_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                include
                tests
                source
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzCore
                AZ::AzFramework
                AZ::AzTest
                AZ::AWSNativeSDKInit
                3rdParty::AWSNativeSDK::Core
    )
    o3de_add_googletest(
        NAME AZ::AWSNativeSDKInit.Tests
        LABELS REQUIRES_tiaf
    )
endif()
