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
    NAME SceneBuilder.Static STATIC
    NAMESPACE AZ
    FILES_CMAKE
        scenebuilder_files.cmake
        Platform/${O3DE_PAL_PLATFORM_NAME}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
    COMPILE_DEFINITIONS
        PRIVATE
            SCENE_BUILDER_EXPORTS
    INCLUDE_DIRECTORIES
        PUBLIC
            ../..
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            AZ::AzFramework
        PUBLIC
            AZ::AzToolsFramework
            AZ::SceneCore
            AZ::SceneData
            AZ::SDKWrapper
)

o3de_add_target(
    NAME SceneBuilder MODULE
    NAMESPACE AZ
    FILES_CMAKE
        scenebuilder_shared_files.cmake
    COMPILE_DEFINITIONS
        PRIVATE
            SCENE_BUILDER_EXPORTS
    INCLUDE_DIRECTORIES
        PUBLIC
            ../..
    BUILD_DEPENDENCIES
        PUBLIC
            AZ::SceneBuilder.Static
        PRIVATE
            AZ::AzCore
)

o3de_add_dependencies(AssetBuilder AZ::SceneBuilder)

if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
    o3de_add_target(
        NAME SceneBuilder.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
        NAMESPACE AZ
        FILES_CMAKE
            scenebuilder_testing_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Tests
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzTest
                AZ::SceneBuilder
    )
    o3de_add_googletest(
        NAME AZ::SceneBuilder.Tests
        LABELS REQUIRES_tiaf
    )
endif()
