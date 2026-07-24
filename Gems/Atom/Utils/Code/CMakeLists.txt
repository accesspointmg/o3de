#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

o3de_add_target(
    NAME Atom_Utils.Static STATIC
    NAMESPACE Gem
    FILES_CMAKE
        atom_utils_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            Gem::Atom_RHI.Public
            AzFramework
        PUBLIC
            Gem::Atom_RHI.Reflect
            Gem::Atom_RPI.Public
            Gem::ImGui.imguilib
            3rdParty::PNG
            Gem::ProfilerImGui
)

if(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)

    o3de_add_target(
        NAME Atom_Utils.TestUtils.Static STATIC
        NAMESPACE Gem
        FILES_CMAKE
            atom_utils_editor_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Source
            PUBLIC
                Include
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AtomCore
                AZ::AzCore
                AZ::AzFramework
                AZ::AzToolsFramework
    )
endif()

################################################################################
# Tests
################################################################################
if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)

    set(pal_code_path ${CMAKE_CURRENT_LIST_DIR}/Platform/${O3DE_PAL_PLATFORM_NAME})
    set(pal_common_code_path ${CMAKE_CURRENT_LIST_DIR}/Platform/Common)

    o3de_add_target(
        NAME Atom_Utils.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
        NAMESPACE Gem
        FILES_CMAKE
            atom_utils_tests_files.cmake
        PLATFORM_INCLUDE_FILES
            ${pal_code_path}/platform_${O3DE_PAL_PLATFORM_WART}.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Tests
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzTest
                AZ::AzFramework
                Gem::Atom_Utils.Static
    )
    o3de_add_googletest(
        NAME Gem::Atom_Utils.Tests
        LABELS REQUIRES_tiaf
    )
endif()
