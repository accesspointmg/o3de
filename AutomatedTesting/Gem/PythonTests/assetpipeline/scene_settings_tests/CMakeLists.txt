#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED AND O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    o3de_add_pytest(
        NAME AutomatedTesting::SceneSettingsTests
        TEST_SUITE periodic
        TEST_SERIAL
        PATH ${CMAKE_CURRENT_LIST_DIR}/scene_settings_tests.py
        PYTEST_MARKS "not REQUIRES_gpu"
        RUNTIME_DEPENDENCIES
            Legacy::Editor
            AZ::AssetProcessor
            AutomatedTesting.Assets
            Gem::EditorPythonBindings.Editor
        COMPONENT TestTools
    )
endif()
