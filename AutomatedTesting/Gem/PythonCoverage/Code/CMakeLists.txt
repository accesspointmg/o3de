#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

o3de_pal_dir(pal_dir ${CMAKE_CURRENT_LIST_DIR}/Platform/${O3DE_PAL_PLATFORM_NAME} "${gem_restricted_path}" "${gem_path}" "${gem_parent_relative_path}")
include(${pal_dir}/PAL_${O3DE_PAL_PLATFORM_WART}.cmake)

if(O3DE_PAL_TRAIT_PYTHONCOVERAGE_SUPPORTED)
    if(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
        o3de_add_target(
            NAME ${gem_name}.Editor.Static STATIC
            NAMESPACE Gem
            FILES_CMAKE
                pythoncoverage_editor_files.cmake
            INCLUDE_DIRECTORIES
                PRIVATE
                    Source
                PUBLIC
                    Include
            COMPILE_DEFINITIONS
                PUBLIC
                    PYTHON_COVERAGE_EDITOR
                PRIVATE
                    ${O3DE_TEST_IMPACT_CONFIG_FILE_PATH_DEFINITION}
            BUILD_DEPENDENCIES
                PUBLIC
                    AZ::AzToolsFramework
            RUNTIME_DEPENDENCIES
                Gem::EditorPythonBindings.Editor
        )

        o3de_add_target(
            NAME ${gem_name}.Editor GEM_MODULE
            NAMESPACE Gem
            AUTOMOC
            OUTPUT_NAME Gem.${gem_name}.Editor
            FILES_CMAKE
                pythoncoverage_editor_shared_files.cmake
            COMPILE_DEFINITIONS
                PRIVATE
                    PYTHON_COVERAGE_EDITOR
            INCLUDE_DIRECTORIES
                PRIVATE
                    Source
                PUBLIC
                    Include
            BUILD_DEPENDENCIES
                PUBLIC
                    Gem::${gem_name}.Editor.Static
        )

        # Inject the gem name into the Module source file
        o3de_add_source_properties(
            SOURCES
                Source/PythonCoverageEditorModule.cpp
            PROPERTY COMPILE_DEFINITIONS
                VALUES
                    O3DE_GEM_NAME=${gem_name}
                    O3DE_GEM_VERSION=${gem_version})

        o3de_create_alias(NAME ${gem_name}.Tools    NAMESPACE Gem TARGETS Gem::${gem_name}.Editor)
        o3de_create_alias(NAME ${gem_name}.Builders NAMESPACE Gem TARGETS Gem::${gem_name}.Editor)
    endif()
endif()
