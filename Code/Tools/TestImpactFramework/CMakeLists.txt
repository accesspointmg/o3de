#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(pal_code_tools_testimpactframework_path ${O3DE_ENGINE_PATH}/Code/Tools/TestImpactFramework/Platform/${O3DE_PAL_PLATFORM_NAME})
#set(common_code_tools_testimpactframework_path ${O3DE_ENGINE_PATH}/Code/Tools/TestImpactFramework/Platform/Common)

include(${pal_code_tools_testimpactframework_path}/PAL_${O3DE_PAL_PLATFORM_WART}.cmake)

if(O3DE_PAL_TRAIT_TEST_IMPACT_FRAMEWORK_SUPPORTED AND O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED AND NOT O3DE_MONOLITHIC_GAME)
    add_subdirectory(Runtime)
    add_subdirectory(Frontend)

    if(O3DE_TEST_IMPACT_ACTIVE)
        # Only add the TIAF unit tests if one or more runtimes is enabled
        o3de_add_pytest(
            NAME TiafToolsTest
            PATH ${O3DE_ENGINE_PATH}/scripts/build/TestImpactAnalysis/Testing/test_tiaf_tools.py
            TEST_SERIAL
            COMPONENT 
                TestImpactFramework
            LABELS REQUIRES_tiaf
        )
        
        o3de_add_pytest(
            NAME TiafPythonUnitTest
            PATH ${O3DE_ENGINE_PATH}/scripts/build/TestImpactAnalysis/Testing/test_tiaf_unit_tests.py
            TEST_SERIAL
            COMPONENT
                TestImpactFramework
            LABELS REQUIRES_tiaf
        )
    endif()
endif()
