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

add_subdirectory(Plugins)

set(pal_core_editor_path ${O3DE_ENGINE_PATH}/Code/Editor/Platform/${O3DE_PAL_PLATFORM_NAME})
set(common_core_editor_path ${O3DE_ENGINE_PATH}/Code/Editor/Platform/Common)

o3de_add_target(
    NAME EditorCore SHARED
    NAMESPACE Legacy
    AUTOMOC
    AUTOUIC
    FILES_CMAKE
        editor_core_files.cmake
        ${pal_core_editor_path}/editor_core_files_${O3DE_PAL_PLATFORM_WART}.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            Include
            .
            ..
    COMPILE_DEFINITIONS
        PRIVATE
            EDITOR_CORE
        PUBLIC
            EDITOR
    BUILD_DEPENDENCIES
        PRIVATE
            Legacy::CryCommon
        PUBLIC
            3rdParty::Qt::Core
            3rdParty::Qt::Gui
            3rdParty::Qt::Widgets
            AZ::AzToolsFramework
)

# Header only target to prevent linkage against editor libraries when is not needed. Eventually the targets that depend
# on editor headers should cleanup dependencies and interact with the editor through buses or other mechanisms
o3de_add_target(
    NAME Editor.Headers HEADERONLY
    NAMESPACE Legacy
    FILES_CMAKE
        editor_headers_files.cmake
    INCLUDE_DIRECTORIES
        INTERFACE
            Include
            .
            ..
)

################################################################################
# EditorLib
################################################################################
set(pal_tool_paths "")
set(pal_tool_files "")
foreach(enabled_platform ${O3DE_PAL_TOOLS_ENABLED})
    o3de_pal_platform_name_wart(${enabled_platform} pal_wart)
    set(pal_tool_path ${O3DE_ENGINE_PATH}/Code/Editor/Platform/${enabled_platform})
    list(APPEND pal_tool_paths ${pal_tool_path})
    list(APPEND pal_tool_files ${pal_tool_path}/editor_lib_${pal_wart}_files.cmake})
endforeach()

o3de_add_target(
    NAME EditorLib SHARED
    NAMESPACE Legacy
    AUTOMOC
    AUTOUIC
    AUTORCC
    FILES_CMAKE
        editor_lib_files.cmake
        ${pal_core_editor_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
    PLATFORM_INCLUDE_FILES
        ${pal_core_editor_path}/editor_lib_${O3DE_PAL_PLATFORM_WART}.cmake
        ${common_core_editor_path}/${O3DE_PAL_TRAIT_COMPILER_ID}/editor_lib_${O3DE_PAL_TRAIT_COMPILER_ID_LOWERCASE}.cmake
        ${pal_tool_files}
    INCLUDE_DIRECTORIES
        PUBLIC
            Include
        PRIVATE
            .
            ..
            AssetBrowser/AssetTypes/Character
            ${pal_tool_paths}
    COMPILE_DEFINITIONS
        PRIVATE
            SANDBOX_EXPORTS
            ${O3DE_LEGACY_TERRAIN_EDITOR_DEFINES}
        INTERFACE
            SANDBOX_IMPORTS
    BUILD_DEPENDENCIES
        PRIVATE
            3rdParty::Qt::Core
            3rdParty::Qt::Gui
            3rdParty::Qt::Widgets
            3rdParty::Qt::Concurrent
            3rdParty::TIFF
            Legacy::CryCommon
            Legacy::EditorCommon
            AZ::AzCore
            AZ::AzToolsFramework
            Gem::LmbrCentral.Static
            AZ::AtomCore
            Gem::Atom_RPI.Edit
            Gem::Atom_RPI.Public
            Gem::Atom_Feature_Common.Public
            Gem::AtomToolsFramework.Static
            Gem::AtomViewportDisplayInfo
            Gem::EditorModeFeedback.Editor.Static
            ${additional_dependencies}
        PUBLIC
            3rdParty::Qt::Network
            Legacy::EditorCore
    RUNTIME_DEPENDENCIES
        Legacy::EditorCommon
)

if(O3DE_PAL_TRAIT_BUILD_EXTERNAL_CRASH_HANDLER_SUPPORTED)
    o3de_target_link_libraries(EditorLib PRIVATE AZ::ToolsCrashHandler)
endif()

# O3DE_COPYRIGHT_YEAR / O3DE_INSTALL_BUILD_VERSION are only set by installer
# builds; fall back to the engine globals, then sane defaults, so the compile
# definitions below never expand empty (empty defines break CryEdit.cpp).
if(NOT O3DE_COPYRIGHT_YEAR)
    get_property(O3DE_COPYRIGHT_YEAR GLOBAL PROPERTY O3DE_ENGINE_COPYRIGHT_YEAR)
endif()
if(NOT O3DE_COPYRIGHT_YEAR)
    string(TIMESTAMP O3DE_COPYRIGHT_YEAR "%Y")
endif()
if(NOT O3DE_INSTALL_BUILD_VERSION)
    get_property(O3DE_INSTALL_BUILD_VERSION GLOBAL PROPERTY O3DE_ENGINE_BUILD)
endif()
if(NOT O3DE_INSTALL_BUILD_VERSION)
    set(O3DE_INSTALL_BUILD_VERSION 0)
endif()
o3de_add_source_properties(
    SOURCES CryEdit.cpp
    PROPERTY COMPILE_DEFINITIONS 
    VALUES 
        O3DE_COPYRIGHT_YEAR=${O3DE_COPYRIGHT_YEAR}
        O3DE_BUILD_VERSION=${O3DE_INSTALL_BUILD_VERSION}
        ${O3DE_PAL_TOOLS_DEFINES}
)
o3de_add_source_properties(
    SOURCES
        MainWindow.cpp
    PROPERTY COMPILE_DEFINITIONS 
    VALUES ${O3DE_PAL_TOOLS_DEFINES}
)

get_property(editor_plugins GLOBAL PROPERTY O3DE_EDITOR_PLUGINS)
string (REPLACE ";" "," editor_plugins "${editor_plugins}")
o3de_add_source_properties(
    SOURCES PluginManager.cpp
    PROPERTY COMPILE_DEFINITIONS 
    VALUES O3DE_EDITOR_PLUGINS="${editor_plugins}"
)

################################################################################
# Editor
################################################################################
o3de_add_target(
    NAME Editor APPLICATION
    NAMESPACE Legacy
    AUTORCC
    FILES_CMAKE
        editor_files.cmake
    PLATFORM_INCLUDE_FILES
        ${pal_core_editor_path}/editor_${O3DE_PAL_PLATFORM_WART}.cmake
    TARGET_PROPERTIES
        O3DE_INSTALL_GENERATE_RUN_TARGET TRUE
    BUILD_DEPENDENCIES
        PRIVATE
            3rdParty::Qt::Core
            Legacy::CryCommon
    RUNTIME_DEPENDENCIES
        Legacy::CrySystem
        Legacy::EditorLib
        ProjectManager
)

o3de_set_gem_variant_to_load(TARGETS Editor VARIANTS Tools)
set_property(SOURCE
    CryEdit.cpp
    APPEND PROPERTY
        COMPILE_DEFINITIONS O3DE_CMAKE_TARGET="Editor"
)
# o3de_add_translations is not implemented (dead code upstream too —
# ly_add_translations is commented out in upstream Editor/CMakeLists.txt)
# o3de_add_translations(
#     TARGETS Editor
#     PREFIX Translations
#     FILES
#         Translations/editor_en-us.ts 
#         Translations/assetbrowser_en-us.ts 
# )
o3de_add_dependencies(Editor AssetProcessor)

if(O3DE_DEFAULT_PROJECT_PATH)
    set_property(TARGET Editor APPEND PROPERTY VS_DEBUGGER_COMMAND_ARGUMENTS "--project-path=\"${O3DE_DEFAULT_PROJECT_PATH}\"")
endif()

################################################################################
# Tests
################################################################################
if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)

    o3de_add_target(
        NAME EditorCore.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
        NAMESPACE Legacy
        AUTOMOC
        FILES_CMAKE
            editor_core_test_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                .
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzTest
                3rdParty::Qt::Gui
                3rdParty::Qt::Widgets
                Legacy::EditorCore
                Legacy::CryCommon
                AZ::AzCore
    )
    o3de_add_googletest(
        NAME Legacy::EditorCore.Tests
        LABELS REQUIRES_tiaf
    )

    o3de_add_target(
        NAME EditorLib.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
        NAMESPACE Legacy
        AUTOMOC
        FILES_CMAKE
            editor_lib_test_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Include
                .
        COMPILE_DEFINITIONS
            PRIVATE
                ${O3DE_LEGACY_TERRAIN_EDITOR_DEFINES}
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzTest
                AZ::AzCoreTestCommon
                3rdParty::Qt::Core
                3rdParty::Qt::Gui
                3rdParty::Qt::Widgets
                3rdParty::Qt::Test
                Legacy::CryCommon
                AZ::AzToolsFramework
                AZ::AzToolsFramework.Tests
                AZ::AzFrameworkTestShared
                AZ::AzToolsFrameworkTestCommon
                Legacy::EditorLib
                Gem::AtomToolsFramework.Static
        RUNTIME_DEPENDENCIES
            Gem::LmbrCentral
    )

    o3de_add_googletest(
        NAME Legacy::EditorLib.Tests
        LABELS REQUIRES_tiaf
    )

endif()
