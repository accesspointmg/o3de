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

o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_PATH}/Code/Tools/SceneAPI/SceneData/Platform/${O3DE_PAL_PLATFORM_NAME} pal_code_tools_sceneapi_scenedata_path)
#set(common_code_tools_sceneapi_scenedata_path ${O3DE_ENGINE_PATH}/Code/Tools/SceneAPI/SceneData/Platform/Common)

o3de_add_target(
    NAME SceneData SHARED
    NAMESPACE AZ
    FILES_CMAKE
        SceneData_files.cmake
        ${pal_code_tools_sceneapi_scenedata_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
    COMPILE_DEFINITIONS
        PRIVATE
            SCENE_DATA_EXPORTS
    INCLUDE_DIRECTORIES
        PUBLIC
            ../..
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            AZ::AzFramework
            AZ::AzToolsFramework
            AZ::SceneCore
)

if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
    o3de_add_target(
        NAME SceneData.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
        NAMESPACE AZ
        FILES_CMAKE
            SceneData_testing_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Tests
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzTest
                AZ::AzFramework
                AZ::AzToolsFramework
                AZ::SceneCore
                AZ::SceneData
    )
    o3de_add_googletest(
        NAME AZ::SceneData.Tests
        LABELS REQUIRES_tiaf
    )
endif()
