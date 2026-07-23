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

set(common_source_dir ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/Common)

include(${CMAKE_CURRENT_SOURCE_DIR}/Source/Platform/${O3DE_PAL_PLATFORM_NAME}/PAL_${O3DE_PAL_PLATFORM_WART}.cmake)

if(NOT O3DE_PAL_TRAIT_BUILD_QTFORPYTHON_SUPPORTED)
    return()
endif()

o3de_add_target(
    NAME ${gem_name}.Editor.Static STATIC
    NAMESPACE Gem
    FILES_CMAKE
        qtforpython_editor_files.cmake
        ${CMAKE_CURRENT_SOURCE_DIR}/Source/Platform/${O3DE_PAL_PLATFORM_NAME}/qtforpython_editor_${O3DE_PAL_PLATFORM_WART}_files.cmake
    PLATFORM_INCLUDE_FILES
        ${common_source_dir}/${O3DE_PAL_TRAIT_COMPILER_ID}/qtforpython_${O3DE_PAL_TRAIT_COMPILER_ID_LOWERCASE}.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            Include
            Source
    BUILD_DEPENDENCIES
        PUBLIC
            AZ::AzCore
            AZ::AzFramework
            AZ::AzToolsFramework
            3rdParty::Qt::Widgets
            Gem::EditorPythonBindings.Static
    RUNTIME_DEPENDENCIES
        3rdParty::pyside6
        3rdParty::Qt::Test
)

o3de_add_target(
    NAME ${gem_name}.Editor GEM_MODULE
    NAMESPACE Gem
    FILES_CMAKE
        qtforpython_shared_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            ${CMAKE_CURRENT_SOURCE_DIR}/Source/Platform/${O3DE_PAL_PLATFORM_NAME}
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::${gem_name}.Editor.Static
    RUNTIME_DEPENDENCIES
        3rdParty::pyside6::Tools
        Gem::EditorPythonBindings.Editor
)

# Inject the gem name into the Module source file
o3de_add_source_properties(
    SOURCES
        Source/QtForPythonModule.cpp
    PROPERTY COMPILE_DEFINITIONS
        VALUES
            O3DE_GEM_NAME=${gem_name}
            O3DE_GEM_VERSION=${gem_version})

# the above target is used in both builders like AssetProcessor and Tools like the Editor
# but is not used in clients or servers
o3de_create_alias(NAME ${gem_name}.Tools     NAMESPACE Gem TARGETS Gem::${gem_name}.Editor)
o3de_create_alias(NAME ${gem_name}.Builders  NAMESPACE Gem TARGETS Gem::${gem_name}.Editor)

