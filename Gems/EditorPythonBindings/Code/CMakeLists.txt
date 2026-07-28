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
        editorpythonbindings_common_files.cmake
    PLATFORM_INCLUDE_FILES
        Source/Platform/${O3DE_PAL_PLATFORM_NAME}/platform_${O3DE_PAL_PLATFORM_WART}.cmake
        Source/Platform/Common/${O3DE_PAL_TRAIT_COMPILER_ID}/editorpythonbindings_static_${O3DE_PAL_TRAIT_COMPILER_ID_LOWERCASE}.cmake
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
            3rdParty::pybind11
            AZ::AzToolsFramework
)

o3de_add_target(
    NAME ${gem_name}.Editor GEM_MODULE

    NAMESPACE Gem
    FILES_CMAKE
        editorpythonbindings_editor_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            ${CMAKE_CURRENT_SOURCE_DIR}/Source/Platform/${O3DE_PAL_PLATFORM_NAME}
        PRIVATE
            .
            Source
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::${gem_name}.Static
)

# Inject the gem name into the Module source file
o3de_add_source_properties(
    SOURCES
        Source/EditorPythonBindingsModule.cpp
    PROPERTY COMPILE_DEFINITIONS
        VALUES
            O3DE_GEM_NAME=${gem_name}
            O3DE_GEM_VERSION=${gem_version})

# builders and tools use EditorPythonBindings.Editor
o3de_create_alias(NAME ${gem_name}.Builders NAMESPACE Gem TARGETS ${gem_name}.Editor)
o3de_create_alias(NAME ${gem_name}.Tools    NAMESPACE Gem TARGETS ${gem_name}.Editor)

################################################################################
# Tests
################################################################################
if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
    o3de_add_target(
        NAME ${gem_name}.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
        NAMESPACE Gem
        FILES_CMAKE
            editorpythonbindings_tests_files.cmake
        PLATFORM_INCLUDE_FILES
            Source/Platform/${O3DE_PAL_PLATFORM_NAME}/platform_${O3DE_PAL_PLATFORM_WART}.cmake
            Source/Platform/Common/${O3DE_PAL_TRAIT_COMPILER_ID}/editorpythonbindings_tests_${O3DE_PAL_TRAIT_COMPILER_ID_LOWERCASE}.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                .
                Tests
                Include
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzTest
                Gem::${gem_name}.Static
    )
    o3de_add_googletest(
        NAME Gem::${gem_name}.Tests
        COMPONENT TestTools
        LABELS REQUIRES_tiaf
    )
endif()
