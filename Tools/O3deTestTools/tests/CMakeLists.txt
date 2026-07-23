#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#
# O3deTestTools tests.
#

# Unit tests.
o3de_add_pytest(
    NAME O3deTestTools_Unit
    TEST_SUITE smoke
    PATH ${CMAKE_CURRENT_LIST_DIR}/unit/
    COMPONENT TestTools
)

get_property(O3DE_PROJECTS_NAME GLOBAL PROPERTY O3DE_PROJECTS_NAME)
if(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS AND O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED AND AutomatedTesting IN_LIST O3DE_PROJECTS_NAME)
    # Integration tests.

    o3de_add_pytest(
        NAME O3deTestTools_Integ_Sanity
        PATH ${CMAKE_CURRENT_LIST_DIR}/integ/sanity_tests.py
        TEST_SERIAL
        TEST_SUITE smoke
        RUNTIME_DEPENDENCIES
            Legacy::Editor
            AssetProcessor
            AutomatedTesting.GameLauncher
            AutomatedTesting.ServerLauncher
            AutomatedTesting.Assets
        COMPONENT TestTools
    )

    o3de_add_pytest(
        NAME O3deTestTools_Integ_Codeowners
        PATH ${CMAKE_CURRENT_LIST_DIR}/integ/test_o3de_codeowners.py
        TEST_SUITE smoke
        COMPONENT TestTools
    )

    o3de_add_pytest(
        NAME O3deTestTools_Integ_ProcessUtils
        PATH ${CMAKE_CURRENT_LIST_DIR}/integ/test_process_utils.py
        TEST_SERIAL
        TEST_SUITE smoke
        COMPONENT TestTools
    )
    
    o3de_add_pytest(
        NAME O3deTestTools_Integ_ProcessUtilsLinux
        PATH ${CMAKE_CURRENT_LIST_DIR}/integ/test_process_utils_linux.py
        TEST_SERIAL
        TEST_SUITE smoke
        COMPONENT TestTools
    )

    # Regression tests.
    o3de_add_pytest(
        NAME O3deTestTools_Integ_RegressionTests
        PATH ${CMAKE_CURRENT_LIST_DIR}/integ/test_regression.py
        TEST_SERIAL
        TEST_SUITE periodic
        RUNTIME_DEPENDENCIES
            Legacy::Editor
            AssetProcessor
            AutomatedTesting.GameLauncher
            AutomatedTesting.Assets
        COMPONENT TestTools
    )
endif()
