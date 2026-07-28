#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED AND O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    o3de_add_pytest(
        NAME NAME AutomatedTesting::SceneTests
        PATH ${CMAKE_CURRENT_LIST_DIR}/scene_tests.py
        TEST_SUITE sandbox
        RUNTIME_DEPENDENCIES
            AZ::AssetProcessorBatch
            AZ::AssetProcessor
    )
endif()
