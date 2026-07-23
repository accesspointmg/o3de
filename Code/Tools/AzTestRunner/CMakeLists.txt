#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_PATH}/Code/Tools/AzTestRunner/Platform/${O3DE_PAL_PLATFORM_NAME} pal_code_tools_aztestrunner_path)
#set(common_code_tools_aztestrunner_path ${O3DE_ENGINE_PATH}/Code/Tools/AzTestRunner/Platform/Common)

include(${pal_code_tools_aztestrunner_path}/platform_traits_${O3DE_PAL_PLATFORM_WART}.cmake)

if(O3DE_PAL_TRAIT_AZTESTRUNNER_SUPPORTED AND O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
    
    o3de_add_target(
        NAME AzTestRunner ${O3DE_PAL_TRAIT_AZTESTRUNNER_LAUNCHER_TYPE}
        NAMESPACE AZ
        FILES_CMAKE
            aztestrunner_files.cmake
            ${pal_code_tools_aztestrunner_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
        PLATFORM_INCLUDE_FILES
            ${pal_code_tools_aztestrunner_path}/platform_${O3DE_PAL_PLATFORM_WART}.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                src
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzCore
                AZ::AzTest
    )
    
    if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
    
        o3de_add_target(
            NAME AzTestRunner.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
            NAMESPACE AZ
            FILES_CMAKE
                aztestrunner_test_files.cmake
            BUILD_DEPENDENCIES
                PRIVATE
                    AZ::AzTest
        )

        o3de_add_googletest(
            NAME AZ::AzTestRunner.Tests
            LABELS REQUIRES_tiaf
        )

    endif()

endif()
