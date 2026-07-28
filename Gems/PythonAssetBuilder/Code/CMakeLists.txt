#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

if(NOT O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    return()
endif()

o3de_add_target(
    NAME ${gem_name}.Static STATIC
    NAMESPACE Gem
    FILES_CMAKE
        pythonassetbuilder_common_files.cmake
    PLATFORM_INCLUDE_FILES
        Source/Platform/Common/${O3DE_PAL_TRAIT_COMPILER_ID}/pythonassetbuilder_static_${O3DE_PAL_TRAIT_COMPILER_ID_LOWERCASE}.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            .
            Source
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
        PUBLIC
            3rdParty::Python
            Gem::EditorPythonBindings.Static
            AZ::AssetBuilderSDK
            AZ::AzToolsFramework
)

o3de_add_target(
    NAME ${gem_name}.Editor GEM_MODULE

    NAMESPACE Gem
    FILES_CMAKE
        pythonassetbuilder_editor_files.cmake
        pythonassetbuilder_shared_files.cmake
    PLATFORM_INCLUDE_FILES
        Source/Platform/Common/${O3DE_PAL_TRAIT_COMPILER_ID}/pythonassetbuilder_static_${O3DE_PAL_TRAIT_COMPILER_ID_LOWERCASE}.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            .
            Source
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::EditorPythonBindings.Static
            AZ::AssetBuilderSDK
    RUNTIME_DEPENDENCIES
        Gem::EditorPythonBindings.Editor
)

# Inject the gem name into the Module source file
o3de_add_source_properties(
    SOURCES
        Source/PythonAssetBuilderModule.cpp
    PROPERTY COMPILE_DEFINITIONS
        VALUES
            O3DE_GEM_NAME=${gem_name}
            O3DE_GEM_VERSION=${gem_version})

# the above target is used in both builders like AssetProcessor and Tools like the Editor
# but is not used in clients or servers
o3de_create_alias(NAME ${gem_name}.Tools     NAMESPACE Gem TARGETS Gem::${gem_name}.Editor)
o3de_create_alias(NAME ${gem_name}.Builders  NAMESPACE Gem TARGETS Gem::${gem_name}.Editor)

################################################################################
# Tests
################################################################################
if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
    o3de_add_target(
        NAME ${gem_name}.Tests MODULE
        NAMESPACE Gem
        FILES_CMAKE
            pythonassetbuilder_tests_files.cmake
        PLATFORM_INCLUDE_FILES
            Source/Platform/Common/${O3DE_PAL_TRAIT_COMPILER_ID}/pythonassetbuilder_tests_${O3DE_PAL_TRAIT_COMPILER_ID_LOWERCASE}.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                .
                Source
                Tests
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzTest
                Gem::${gem_name}.Static
    )
    o3de_add_googletest(
        NAME Gem::${gem_name}.Tests
        LABELS REQUIRES_tiaf
    )
endif()
