#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

o3de_pal_path(${CMAKE_CURRENT_LIST_DIR}/Source/Platform/${O3DE_PAL_PLATFORM_NAME} pal_code_source_path)
set(pal_common_code_source_path ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/Common)

o3de_add_target(
    NAME ${gem_name}.Static STATIC
    NAMESPACE Gem
    FILES_CMAKE
        atombridge_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
        PUBLIC
            Include
    COMPILE_DEFINITIONS
        PRIVATE
            ENABLE_ATOM_DEBUG_DISPLAY=1
    BUILD_DEPENDENCIES
        PUBLIC
            AZ::AtomCore
            AZ::AzFramework
            Gem::Atom_RPI.Public
            Gem::Atom_Bootstrap.Headers
            Legacy::CryCommon
)

o3de_add_target(
    NAME ${gem_name} ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        atombridge_shared_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
        PUBLIC
            Include
    PLATFORM_INCLUDE_FILES
        ${pal_code_source_path}/additional_${O3DE_PAL_PLATFORM_WART}_runtime_deps.cmake
    COMPILE_DEFINITIONS
        PRIVATE
            ENABLE_ATOM_DEBUG_DISPLAY=1
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::${gem_name}.Static
    RUNTIME_DEPENDENCIES
        Gem::Atom_RHI.Private
        Gem::Atom_RPI.Private
        Gem::Atom_RHI_Null.Private
        Gem::Atom_Feature_Common
        Gem::Atom_Bootstrap
        Gem::Atom_Component_DebugCamera
        Gem::AtomImGuiTools
        Gem::CommonFeaturesAtom
        Gem::EMotionFX_Atom
        Gem::ImguiAtom
        Gem::AtomFont
        Gem::AtomViewportDisplayInfo
)

# Inject the gem name into the Module source file
o3de_add_source_properties(
    SOURCES
        Source/AtomBridgeModule.cpp
    PROPERTY COMPILE_DEFINITIONS
        VALUES
            O3DE_GEM_NAME=${gem_name}
            O3DE_GEM_VERSION=${gem_version})

o3de_add_target(
    NAME ${gem_name}.Headless ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        atombridge_shared_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
        PUBLIC
            Include
    COMPILE_DEFINITIONS
        PRIVATE
            ENABLE_ATOM_DEBUG_DISPLAY=1
            O3DE_HEADLESS_SERVER=1
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::${gem_name}.Static
    RUNTIME_DEPENDENCIES
        Gem::Atom_RHI.Private
        Gem::Atom_RPI.Private
        Gem::Atom_RHI_Null.Private
        Gem::Atom_Feature_Common.Headless
        Gem::Atom_Bootstrap
        Gem::Atom_Component_DebugCamera
        Gem::AtomImGuiTools
        Gem::CommonFeaturesAtom
        Gem::EMotionFX_Atom
        Gem::ImguiAtom
        Gem::AtomFont
        Gem::AtomViewportDisplayInfo
)

# Any 'runtime-like' applications should use Gem::${gem_name}:
o3de_create_alias(NAME ${gem_name}.Clients NAMESPACE Gem TARGETS Gem::${gem_name})
o3de_create_alias(NAME ${gem_name}.Servers NAMESPACE Gem TARGETS Gem::${gem_name})
o3de_create_alias(NAME ${gem_name}.Unified NAMESPACE Gem TARGETS Gem::${gem_name})
o3de_create_alias(NAME ${gem_name}.HeadlessServers NAMESPACE Gem TARGETS Gem::${gem_name}.Headless)

if(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)

    set(additional_tool_deps ${pal_code_source_path}/additional_${O3DE_PAL_PLATFORM_WART}_tool_deps.cmake)
    foreach(pal_tools_platform ${O3DE_PAL_TOOLS_ENABLED})
        o3de_pal_platform_name_wart(enabled_platform_wart ${pal_tools_platform})
        o3de_pal_path(${CMAKE_CURRENT_LIST_DIR}/Source/Platform/${enabled_platform} pal_tools_source_dir)
        o3de_get_list_relative_pal_filename(pal_runtime_dependencies_source_dir ${pal_tools_source_dir})
        list(APPEND additional_tool_deps ${pal_runtime_dependencies_source_dir}/additional_${enabled_platform_wart}_tool_deps.cmake)
    endforeach()

    o3de_add_target(
        NAME ${gem_name}.Editor ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
        NAMESPACE Gem
        FILES_CMAKE
            atombridge_editor_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Source
            PUBLIC
                Include
        PLATFORM_INCLUDE_FILES
           ${additional_tool_deps}
        COMPILE_DEFINITIONS
            PRIVATE
                EDITOR
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AssetBuilderSDK
                Gem::Atom_Utils.Static
                Gem::${gem_name}.Static
        RUNTIME_DEPENDENCIES
            Gem::Atom_RHI.Private
            Gem::Atom_RPI.Builders
            Gem::Atom_RPI.Editor
            Gem::Atom_RHI_Null.Private
            Gem::Atom_RHI_Null.Builders
            Gem::Atom_Feature_Common.Builders
            Gem::Atom_Feature_Common.Editor
            Gem::Atom_Bootstrap
            Gem::AtomShader.Builders
            Gem::Atom_Component_DebugCamera
            Gem::AtomImGuiTools
            Gem::AtomRenderOptions.Editor
            Gem::CommonFeaturesAtom.Editor
            Gem::EMotionFX_Atom.Editor
            Gem::ImageProcessingAtom.Editor
            Gem::ImguiAtom
            Gem::AtomFont
            Gem::AtomToolsFramework.Editor
            Gem::AtomViewportDisplayInfo
            Gem::AtomViewportDisplayIcons.Editor
            Gem::MaterialCanvas.Builders
            Gem::MaterialEditor.Builders
            Gem::PassCanvas.Builders
            Gem::ShaderManagementConsole.Builders
    )

    # Inject the gem name into the Module source file
    o3de_add_source_properties(
        SOURCES
            Source/AtomBridgeEditorModule.cpp
        PROPERTY COMPILE_DEFINITIONS
            VALUES
                O3DE_GEM_NAME=${gem_name}
                O3DE_GEM_VERSION=${gem_version})


    # Any 'tool' and 'builder' type applications should use Gem::${gem_name}.Editor:
    o3de_create_alias(NAME ${gem_name}.Builders NAMESPACE Gem TARGETS Gem::${gem_name}.Editor)
    o3de_create_alias(NAME ${gem_name}.Tools    NAMESPACE Gem TARGETS Gem::${gem_name}.Editor)
endif()
