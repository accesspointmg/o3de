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

set(pal_code_source_path ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/${O3DE_PAL_PLATFORM_NAME})
set(pal_common_code_source_path ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/Common)

include(${pal_code_source_path}/PAL_${O3DE_PAL_PLATFORM_WART}.cmake) # O3DE_PAL_TRAIT_ATOM_MATERIAL_CANVAS_APPLICATION_SUPPORTED

if(NOT O3DE_PAL_TRAIT_ATOM_MATERIAL_CANVAS_APPLICATION_SUPPORTED)
    return()
endif()

o3de_add_target(
    NAME MaterialCanvas APPLICATION
    NAMESPACE Gem
    AUTOMOC
    AUTORCC
    FILES_CMAKE
        materialcanvas_files.cmake
        ${pal_code_source_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
    PLATFORM_INCLUDE_FILES
        ${pal_code_source_path}/tool_dependencies_${O3DE_PAL_PLATFORM_WART}.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            .
            Source
            ${pal_code_source_path}
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::CommonFeaturesAtom.Static
            Gem::AtomToolsFramework.Editor
            Gem::AtomToolsFramework.Static
    RUNTIME_DEPENDENCIES
        Gem::AtomToolsFramework.Editor
)

if(O3DE_PAL_TRAIT_BUILD_EXTERNAL_CRASH_HANDLER_SUPPORTED)
    ly_target_link_libraries(MaterialCanvas PRIVATE AZ::ToolsCrashHandler)
endif()

o3de_set_gem_variant_to_load(TARGETS MaterialCanvas VARIANTS Tools)

# Add a 'builders' alias to allow the MaterialCanvas root gem path to be added to the generated
# cmake_dependencies.<project>.assetprocessor.setreg to allow the asset scan folder for it to be added
o3de_create_alias(NAME MaterialCanvas.Builders NAMESPACE Gem)

# Add build dependency to Editor for the MaterialCanvas application since
# Editor opens up the MaterialCanvas
o3de_add_dependencies(Editor Gem::MaterialCanvas)

# Inject the project path into the MaterialCanvas VS debugger command arguments if the build system being invoked
# in a project centric view
if(NOT PROJECT_NAME STREQUAL "O3DE")
    set_property(TARGET MaterialCanvas APPEND PROPERTY VS_DEBUGGER_COMMAND_ARGUMENTS "--project-path=\"${CMAKE_SOURCE_DIR}\"")
endif()

# Adds the MaterialCanvas target as a C preprocessor define so that it can be used as a Settings Registry
# specialization in order to look up the generated .setreg which contains the dependencies
# specified for the target.
if(TARGET MaterialCanvas)
    set_source_files_properties(
        Source/MaterialCanvasApplication.cpp
        PROPERTIES
            COMPILE_DEFINITIONS
                O3DE_CMAKE_TARGET="MaterialCanvas"
    )
else()
    message(FATAL_ERROR "Cannot set O3DE_CMAKE_TARGET define to MaterialCanvas as the target doesn't exist anymore."
        " Perhaps it has been renamed")
endif()
