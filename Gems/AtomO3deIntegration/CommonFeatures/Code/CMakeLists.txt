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
    NAME ${gem_name}.Public HEADERONLY
    NAMESPACE Gem
    FILES_CMAKE
        atomo3deintegration_commonfeatures_public_files.cmake
    INCLUDE_DIRECTORIES
        INTERFACE
            Include
    BUILD_DEPENDENCIES
        INTERFACE
            Gem::Atom_Feature_Common.Public
            Gem::AtomImGuiTools.Public
)

# Add alias that references the "AtomO3deIntegration_CommonFeatures.Public" for backwards compatibility
o3de_create_alias(NAME AtomO3deIntegration_CommonFeatures.Public NAMESPACE Gem
    TARGETS ${gem_name}.Public)

o3de_add_target(
    NAME ${gem_name}.Static STATIC
    NAMESPACE Gem
    FILES_CMAKE
        atomo3deintegration_commonfeatures_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            .
            Source
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PUBLIC
            AZ::AzCore
            AZ::AzFramework
            Gem::${gem_name}.Public
            Gem::LmbrCentral.Static
            Gem::GradientSignal.Static
            Gem::SurfaceData.Static
            Gem::Atom_Feature_Common.Public
            Gem::Atom_Bootstrap.Headers
)

# Add alias that references the "AtomO3deIntegration_CommonFeatures.Static" name for backwards compatibility
o3de_create_alias(NAME AtomO3deIntegration_CommonFeatures.Static NAMESPACE Gem
    TARGETS ${gem_name}.Static)

o3de_add_target(
    NAME ${gem_name} ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        atomo3deintegration_commonfeatures_shared_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::${gem_name}.Static
    RUNTIME_DEPENDENCIES
        Gem::Atom_RPI.Private
)

# Add alias that references the "AtomO3deIntegration_CommonFeatures" name for backwards compatibility
o3de_create_alias(NAME AtomO3deIntegration_CommonFeatures NAMESPACE Gem
    TARGETS ${gem_name})

# Inject the gem name into the Module source file
o3de_add_source_properties(
    SOURCES
        Source/Module.cpp
    PROPERTY COMPILE_DEFINITIONS
        VALUES
            O3DE_GEM_NAME=${gem_name}
            O3DE_GEM_VERSION=${gem_version})

# The ${gem_name} module is used for Clients and Servers
o3de_create_alias(NAME ${gem_name}.Clients NAMESPACE Gem
    TARGETS
        Gem::${gem_name}
        Gem::GradientSignal.Clients
)
o3de_create_alias(NAME ${gem_name}.Servers NAMESPACE Gem
    TARGETS
        Gem::${gem_name}
        Gem::GradientSignal.Servers
)
o3de_create_alias(NAME ${gem_name}.Unified NAMESPACE Gem
    TARGETS
        Gem::${gem_name}
        Gem::GradientSignal.Unified
)

# Add aliases that references the legacy "AtomO3deIntegration_CommonFeatures" name
# using the real name of the Gem through the ${gem_name} variable
o3de_create_alias(NAME Gem::AtomO3deIntegration_CommonFeatures.Clients NAMESPACE Gem
    TARGETS
        ${gem_name}
)
o3de_create_alias(NAME Gem::AtomO3deIntegration_CommonFeatures.Servers NAMESPACE Gem
    TARGETS
        ${gem_name}
)
o3de_create_alias(NAME Gem::AtomO3deIntegration_CommonFeatures.Unified NAMESPACE Gem
    TARGETS
        ${gem_name}
)

if(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    o3de_add_target(
        NAME ${gem_name}.Editor.Static STATIC
        NAMESPACE Gem
        AUTOUIC
        AUTOMOC
        AUTORCC
        FILES_CMAKE
            atomo3deintegration_commonfeatures_editor_files.cmake
            ${pal_code_source_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
        PLATFORM_INCLUDE_FILES
            ${pal_code_source_path}/platform_${O3DE_PAL_PLATFORM_WART}.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                .
                Source
            PUBLIC
                Include
        COMPILE_DEFINITIONS
            PRIVATE
                atomo3deINTEGRATION_FEATURE_COMMON_EDITOR
        BUILD_DEPENDENCIES
            PUBLIC
                Gem::${gem_name}.Static
                Gem::Atom_RPI.Edit
                Gem::AtomToolsFramework.Static
                Gem::AtomToolsFramework.Editor
                AZ::SceneCore
                AZ::SceneData
                Legacy::Editor.Headers
                Legacy::EditorCommon
                Legacy::CryCommon
        RUNTIME_DEPENDENCIES
            3rdParty::OpenImageIO::Tools::Binaries
            3rdParty::OpenImageIO::Tools::PythonPlugins
    )

    o3de_add_target(
        NAME ${gem_name}.Editor GEM_MODULE
        NAMESPACE Gem
        FILES_CMAKE
            atomo3deintegration_commonfeatures_shared_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Source
            PUBLIC
                Include
        COMPILE_DEFINITIONS
            PRIVATE
                atomo3deINTEGRATION_FEATURE_COMMON_EDITOR
        BUILD_DEPENDENCIES
            PRIVATE
                Gem::${gem_name}.Editor.Static
        RUNTIME_DEPENDENCIES
            Legacy::EditorCommon
    )

    # Add alias that references the "AtomO3deIntegration_CommonFeatures.Editor" for backwards compatibility
    o3de_create_alias(NAME AtomO3deIntegration_CommonFeatures.Editor NAMESPACE Gem
        TARGETS ${gem_name}.Editor)

    # The ${gem_name}.Editor module is used for Builders and Tools
    o3de_create_alias(NAME ${gem_name}.Builders NAMESPACE Gem
        TARGETS
            Gem::${gem_name}.Editor
            Gem::Atom_Feature_Common.Builders
            Gem::Atom_RPI.Builders
            Gem::GradientSignal.Builders
    )
    o3de_create_alias(NAME ${gem_name}.Tools NAMESPACE Gem
        TARGETS
            Gem::${gem_name}.Editor
            Gem::GradientSignal.Tools
    )

    # Add aliases that references the real name of the gem legacy name "AtomO3deIntegration_CommonFeatures"
    # Tools and Builders variants using the ${gem_name} variable
    o3de_create_alias(NAME Gem::AtomO3deIntegration_CommonFeatures.Builders NAMESPACE Gem
        TARGETS
            ${gem_name}
    )
    o3de_create_alias(NAME Gem::AtomO3deIntegration_CommonFeatures.Tools NAMESPACE Gem
        TARGETS
            ${gem_name}
    )

    ################################################################################
    # Tests
    ################################################################################
    if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
        o3de_add_target(
            NAME ${gem_name}.Editor.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
            NAMESPACE Gem
            FILES_CMAKE
                atomo3deintegration_commonfeatures_editor_test_files.cmake
            INCLUDE_DIRECTORIES
                PRIVATE
                    Tests
                    Source
            BUILD_DEPENDENCIES
                PRIVATE
                    AZ::AzTest
                    AZ::AzTestShared
                    AZ::AzToolsFramework
                    AZ::AzToolsFrameworkTestCommon
                    Gem::${gem_name}.Static
                    Gem::${gem_name}.Editor.Static
            RUNTIME_DEPENDENCIES
                Gem::LmbrCentral.Editor
        )
        o3de_add_googletest(
            NAME Gem::${gem_name}.Editor.Tests
            LABELS REQUIRES_tiaf
        )
    endif()
endif()

# AtomO3deIntegration_CommonFeatures gem targets are required as part of the Editor and AssetProcessor
# due to the AZ::Render::EditorDirectionalLightComponent, AZ::Render::EditorMeshComponent,
# AZ::Render::EditorGridComponent, AZ::Render::EditorHDRiSkyboxComponent,
# AZ::Render::EditorImageBasedLightComponent being saved as part of the DefaultLevel.prefab
