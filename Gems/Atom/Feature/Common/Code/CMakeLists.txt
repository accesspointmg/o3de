#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(pal_common_code_path ${CMAKE_CURRENT_LIST_DIR}/Platform/Common)

o3de_pal_path_object_json(${gem_json_path} ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/${O3DE_PAL_PLATFORM_NAME} pal_common_code_source_path)
# NOTE: all per-platform files (platform_*_files.cmake, runtime_dependencies_*.cmake)
# live in Source/Platform/<PlatformName>/ — do not clobber this with the Common dir

# TODO(OBJECT-library): Change this target to an object library after Gradle was updated
o3de_add_target(
    NAME ${gem_name}.Private.Object STATIC
    NAMESPACE Gem
    FILES_CMAKE
        atom_feature_common_files.cmake
        ${pal_common_code_source_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
    PLATFORM_INCLUDE_FILES
        ${pal_common_code_source_path}/platform_${O3DE_PAL_PLATFORM_WART}.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Include
            Source
            ${pal_common_code_source_path}
            3rdParty/ACES
            ../Assets/ShaderLib  # allow including .azsli - files from ShaderLib in c++
    COMPILE_DEFINITIONS
        PRIVATE
            IMGUI_DISABLE_OBSOLETE_FUNCTIONS
    BUILD_DEPENDENCIES
        PUBLIC
            AZ::AzCore
            AZ::AzFramework
            Gem::Atom_RPI.Public
            Gem::Atom_Utils.Static
            Gem::ImGui.imguilib
            3rdParty::TIFF
    RUNTIME_DEPENDENCIES
        Gem::ImGui.imguilib
)

o3de_add_target(
    NAME ${gem_name}.Public ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_LIBRARY_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        atom_feature_common_public_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
            ${pal_common_code_source_path}
        PUBLIC
            Include
            3rdParty/ACES
    COMPILE_DEFINITIONS
        PRIVATE
            ATOM_FEATURE_COMMON_EXPORTS
            IMGUI_DISABLE_OBSOLETE_FUNCTIONS
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            AZ::AzFramework
            ${gem_name}.Private.Object
        PUBLIC
            Gem::Atom_RPI.Public
            Gem::Atom_Utils.Static
)

o3de_add_target(
    NAME ${gem_name} ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        atom_feature_common_shared_files.cmake
        ../Assets/atom_feature_common_asset_files.cmake
        ../Editor/atom_feature_common_editor_script_files.cmake
    PLATFORM_INCLUDE_FILES
        ${pal_common_code_source_path}/runtime_dependencies_clients.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
            ${pal_common_code_source_path}
    BUILD_DEPENDENCIES
        PUBLIC
            Gem::${gem_name}.Public
        PRIVATE
            Gem::${gem_name}.Private.Object
)

o3de_add_target(
    NAME ${gem_name}.Headless ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        atom_feature_common_shared_files.cmake
        ../Assets/atom_feature_common_asset_files.cmake
        ../Editor/atom_feature_common_editor_script_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
            ${pal_common_code_source_path}
        PUBLIC
            Include
    COMPILE_DEFINITIONS
        PRIVATE
            O3DE_HEADLESS_SERVER=1
    BUILD_DEPENDENCIES
        PUBLIC
            Gem::${gem_name}.Public
        PRIVATE
            AZ::AzCore
            AZ::AzFramework
            Gem::${gem_name}.Private.Object
)

# Inject the gem name into the Module source file
o3de_add_source_properties(
    SOURCES
        Source/CommonModule.cpp
    PROPERTY COMPILE_DEFINITIONS
        VALUES
            O3DE_GEM_NAME=${gem_name}
            O3DE_GEM_VERSION=${gem_version})

if(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)

    set(runtime_dependencies_tools ${pal_common_code_source_path}/runtime_dependencies_tools.cmake)
    foreach(pal_tools_platform ${O3DE_PAL_TOOLS_ENABLED})
        o3de_pal_path_object_json(${gem_json_path} ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/${pal_tools_platform} pal_tools_path)
        o3de_get_list_relative_pal_filename(pal_runtime_dependencies_source_dir ${pal_tools_path})
        list(APPEND runtime_dependencies_tools ${pal_runtime_dependencies_source_dir}/runtime_dependencies_tools.cmake)
    endforeach()

    o3de_add_target(
        NAME ${gem_name}.Editor GEM_MODULE

        NAMESPACE Gem
        FILES_CMAKE
            atom_feature_common_editor_files.cmake
        PLATFORM_INCLUDE_FILES
            ${runtime_dependencies_tools}
        INCLUDE_DIRECTORIES
            PRIVATE
                Source
                ${pal_common_code_source_path}
            PUBLIC
                Include
        COMPILE_DEFINITIONS
            PRIVATE
                ATOM_FEATURE_COMMON_EDITOR
                ATOM_FEATURE_CORELIGHTS_EDITOR
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzCore
                AZ::AzFramework
                AZ::AzToolsFramework
                AZ::AssetBuilderSDK
                AZ::SceneCore
                Gem::Atom_RPI.Edit
                Gem::Atom_RPI.Public
                Gem::Atom_Utils.Static
                Gem::${gem_name}.Private.Object
                Gem::${gem_name}.Public
    )

    set(runtime_dependencies_builders ${pal_common_code_source_path}/runtime_dependencies_builders.cmake)
    o3de_add_target(
        NAME ${gem_name}.Builders GEM_MODULE

        NAMESPACE Gem
        FILES_CMAKE
            atom_feature_common_builders_files.cmake
        PLATFORM_INCLUDE_FILES
            ${runtime_dependencies_builders}
        INCLUDE_DIRECTORIES
            PRIVATE
                Source/Builders
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzCore
        RUNTIME_DEPENDENCIES
            Gem::Atom_RHI.Private
    )

    # Inject the gem name into the Module source file
    o3de_add_source_properties(
        SOURCES
            Source/Builders/BuilderModule.cpp
        PROPERTY COMPILE_DEFINITIONS
            VALUES
                O3DE_GEM_NAME=${gem_name}
                O3DE_GEM_VERSION=${gem_version})
endif()

################################################################################
# Tests
################################################################################
if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
    o3de_add_target(
        NAME ${gem_name}.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
        NAMESPACE Gem
        FILES_CMAKE
            atom_feature_common_tests_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Source
                Tests
            PUBLIC
                Mocks
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzFramework
                AZ::AzTest
                Gem::${gem_name}.Private.Object
                Gem::${gem_name}.Public
    )
    o3de_add_googletest(
        NAME Gem::${gem_name}.Tests
        LABELS REQUIRES_tiaf
    )
endif()
