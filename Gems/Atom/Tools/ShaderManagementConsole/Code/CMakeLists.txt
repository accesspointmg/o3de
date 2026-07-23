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

o3de_pal_path_object_json(${gem_json_path} ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/${O3DE_PAL_PLATFORM_NAME} pal_code_source_path)
set(pal_common_code_source_path ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/Common)

include(${pal_code_source_path}/PAL_${O3DE_PAL_PLATFORM_WART}.cmake) # O3DE_PAL_TRAIT_ATOM_SHADER_MANAGEMENT_CONSOLE_APPLICATION_SUPPORTED

if(NOT O3DE_PAL_TRAIT_ATOM_SHADER_MANAGEMENT_CONSOLE_APPLICATION_SUPPORTED)
    return()
endif()

o3de_add_target(
    NAME ShaderManagementConsole APPLICATION
    NAMESPACE Gem
    AUTOMOC
    AUTORCC
    FILES_CMAKE
        shadermanagementconsole_files.cmake
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
            Gem::AtomToolsFramework.Static
            Gem::AtomToolsFramework.Editor
            Gem::AtomShader.Static
    RUNTIME_DEPENDENCIES
        Gem::AtomToolsFramework.Editor
)

if(O3DE_PAL_TRAIT_BUILD_EXTERNAL_CRASH_HANDLER_SUPPORTED)
    ly_target_link_libraries(ShaderManagementConsole PRIVATE AZ::ToolsCrashHandler)
endif()

o3de_set_gem_variant_to_load(TARGETS ShaderManagementConsole VARIANTS Tools)

# Add a 'builders' alias to allow the ShaderManagementConsole root gem path to be added to the generated
# cmake_dependencies.<project>.assetprocessor.setreg to allow the asset scan folder for it to be added
o3de_create_alias(NAME ShaderManagementConsole.Builders NAMESPACE Gem)

# Add build dependency to Editor for the ShaderManagementConsole application since
# Editor opens up the ShaderManagementConsole
o3de_add_dependencies(Editor Gem::ShaderManagementConsole)

# Inject the project path into the ShaderManagementConsole VS debugger command arguments if the build system being invoked
# in a project centric view
if(NOT PROJECT_NAME STREQUAL "O3DE")
    set_property(TARGET ShaderManagementConsole APPEND PROPERTY VS_DEBUGGER_COMMAND_ARGUMENTS "--project-path=\"${CMAKE_SOURCE_DIR}\"")
endif()

# Adds the ShaderManagementConsole target as a C preprocessor define so that it can be used as a Settings Registry
# specialization in order to look up the generated .setreg which contains the dependencies
# specified for the target.
if(TARGET ShaderManagementConsole)
    set_source_files_properties(
        Source/ShaderManagementConsoleApplication.cpp
        PROPERTIES
            COMPILE_DEFINITIONS
                O3DE_CMAKE_TARGET="ShaderManagementConsole"
    )
else()
    message(FATAL_ERROR "Cannot set O3DE_CMAKE_TARGET define to ShaderManagementConsole as the target doesn't exist anymore."
        " Perhaps it has been renamed")
endif()
