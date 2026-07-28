#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(pal_code_source_path ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/${O3DE_PAL_PLATFORM_NAME})
set(pal_common_code_source_path ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/Common)

#for O3DE_PAL_TRAIT_BUILD_ATOM_RPI_ASSETS_SUPPORTED and O3DE_PAL_TRAIT_BUILD_ATOM_RPI_MASKED_OCCLUSION_CULLING_SUPPORTED
include(${pal_code_source_path}/PAL_${O3DE_PAL_PLATFORM_WART}.cmake)

if(O3DE_PAL_TRAIT_BUILD_ATOM_RPI_MASKED_OCCLUSION_CULLING_SUPPORTED)
    set(MASKED_OCCLUSION_CULLING_FILES "atom_rpi_masked_occlusion_files.cmake")
else()
    set(MASKED_OCCLUSION_CULLING_FILES "")
endif()

# ComputePass.cpp includes IndirectRendering.azsli from the
# Atom_Feature_Common gem's ShaderLib.  Resolve the gem root through
# the manifest so the include works in both source-tree and composed
# workspace layouts (the gems are not siblings in a workspace).
o3de_find_gem("Atom_Feature_Common" atom_feature_common_gem_root)

o3de_add_target(
    NAME ${gem_name}.Public ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_LIBRARY_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        atom_rpi_reflect_files.cmake
        atom_rpi_public_files.cmake
        ../Assets/atom_rpi_asset_files.cmake
        ${pal_code_source_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
        ${MASKED_OCCLUSION_CULLING_FILES}
    COMPILE_DEFINITIONS
        PRIVATE
            ATOM_RPI_PUBLIC_EXPORTS
            ATOM_RPI_REFLECT_EXPORTS
    PLATFORM_INCLUDE_FILES
        ${pal_common_code_source_path}/${O3DE_PAL_TRAIT_COMPILER_ID}/atom_rpi_public_${O3DE_PAL_TRAIT_COMPILER_ID_LOWERCASE}.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
            ${pal_code_source_path}
            ${atom_feature_common_gem_root}/Assets/ShaderLib
        PUBLIC
            Include
            External
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            AZ::AzFramework
            3rdParty::meshoptimizer
        PUBLIC
            AZ::AtomCore
            Gem::Atom_RHI.Public
)

################################################################################
# Private
################################################################################
o3de_add_target(
    NAME ${gem_name}.Private ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        atom_rpi_private_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
            ${pal_code_source_path}
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AtomCore
            AZ::AzCore
            AZ::AzFramework
            Gem::${gem_name}.Public
            Gem::Atom_RHI.Public
            Gem::Atom_RHI.Reflect
    RUNTIME_DEPENDENCIES
        Gem::Atom_RHI.Private
)

# Inject the gem name into the Module source file
o3de_add_source_properties(
    SOURCES
        Source/RPI.Private/Module.cpp
    PROPERTY COMPILE_DEFINITIONS
        VALUES
            O3DE_GEM_NAME=${gem_name}
            O3DE_GEM_VERSION=${gem_version})

if(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)

    o3de_add_target(
        NAME ${gem_name}.Edit ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_LIBRARY_TYPE}
        NAMESPACE Gem
        FILES_CMAKE
            atom_rpi_edit_files.cmake
        COMPILE_DEFINITIONS
            PRIVATE
                ATOM_RPI_EDIT_EXPORTS
        INCLUDE_DIRECTORIES
            PRIVATE
                Source
            PUBLIC
                Include
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AtomCore
                AZ::AzToolsFramework
                Gem::Atom_RHI.Edit
                Gem::${gem_name}.Public
    )

    o3de_add_target(
        NAME ${gem_name}.Editor.Private.Object OBJECT
        NAMESPACE Gem
        FILES_CMAKE
            atom_rpi_private_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Source
            PUBLIC
                Include
        COMPILE_DEFINITIONS
            PUBLIC
                RPI_EDITOR # Compile RPI Editor module
        BUILD_DEPENDENCIES
            PUBLIC
                AZ::AtomCore
                AZ::AzCore
                AZ::AzFramework
                Gem::Atom_RHI.Public
                Gem::${gem_name}.Public
    )

    o3de_add_target(
        NAME ${gem_name}.Editor GEM_MODULE
        NAMESPACE Gem
        FILES_CMAKE
            atom_rpi_editor_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Source
            PUBLIC
                Include
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzToolsFramework
                Gem::${gem_name}.Edit
                Gem::${gem_name}.Editor.Private.Object
        RUNTIME_DEPENDENCIES
            Gem::Atom_RHI.Private
    )

    # Inject the gem name into the Module source file
    o3de_add_source_properties(
        SOURCES
            Source/RPI.Editor/EditorModule.cpp
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
        NAME ${gem_name}.TestUtils STATIC
        NAMESPACE Gem
        FILES_CMAKE
            atom_rpi_test_utils_files.cmake
        INCLUDE_DIRECTORIES
            PUBLIC
                Tests
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AtomCore
                AZ::AzTest
                AZ::AzTestShared
                AZ::AzFramework
                Gem::${gem_name}.Public
                Gem::Atom_RHI.Public
    )
endif()

if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED AND O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    o3de_add_target(
        NAME ${gem_name}.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
        NAMESPACE Gem
        FILES_CMAKE
            atom_rpi_tests_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                .
                Tests
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AtomCore
                AZ::AzTest
                AZ::AzTestShared
                AZ::AzFramework
                AZ::AzToolsFramework
                Legacy::CryCommon
                Gem::Atom_RHI.Public
                Gem::Atom_Utils.TestUtils.Static
                Gem::${gem_name}.Edit
                Gem::${gem_name}.Public
                Gem::${gem_name}.TestUtils
    )

    o3de_add_googletest(
        NAME Gem::${gem_name}.Tests
        LABELS REQUIRES_tiaf
    )

endif()


################################################################################
# Builders
################################################################################

if(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)

    if(NOT O3DE_PAL_TRAIT_BUILD_ATOM_RPI_ASSETS_SUPPORTED)

        # Create a stub
        o3de_add_target(
            NAME ${gem_name}.Builders GEM_MODULE
            NAMESPACE Gem
            FILES_CMAKE
                atom_rpi_builders_stub_files.cmake
            INCLUDE_DIRECTORIES
                PRIVATE
                    Source
                PUBLIC
                    Include
            BUILD_DEPENDENCIES
                PRIVATE
                    AZ::AzCore
        )

        # Inject the gem name into the Module source file
        o3de_add_source_properties(
            SOURCES
                ${pal_common_code_source_path}/Unimplemented/BuilderModule_Stub.cpp
            PROPERTY COMPILE_DEFINITIONS
                VALUES
                    O3DE_GEM_NAME=${gem_name}
                    O3DE_GEM_VERSION=${gem_version})

        return()

    endif()
    
    o3de_add_target(
        NAME ${gem_name}.Builders.Private.Object OBJECT
        NAMESPACE Gem
        FILES_CMAKE
            atom_rpi_builders_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Source
                Source/RPI.Builders
            PUBLIC
                Include
        BUILD_DEPENDENCIES
            PUBLIC
                AZ::AtomCore
                AZ::AzCore
                AZ::AzFramework
                AZ::SceneCore
                AZ::SceneData
                AZ::AssetBuilderSDK
                Gem::Atom_RHI.Public
                Gem::${gem_name}.Edit
                Gem::${gem_name}.Public
                3rdParty::meshoptimizer
    )

    o3de_add_target(
        NAME ${gem_name}.Builders GEM_MODULE
        NAMESPACE Gem
        FILES_CMAKE
            atom_rpi_builders_shared_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Source
                Source/RPI.Builders
            PUBLIC
                Include
        BUILD_DEPENDENCIES
            PRIVATE
                Gem::${gem_name}.Builders.Private.Object
    )

     # Inject the gem name into the Module source file
     o3de_add_source_properties(
        SOURCES
            Source/RPI.Builders/BuilderModule.cpp
        PROPERTY COMPILE_DEFINITIONS
            VALUES
                O3DE_GEM_NAME=${gem_name}
                O3DE_GEM_VERSION=${gem_version})

    if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)

        o3de_add_target(
            NAME ${gem_name}.Builders.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
            NAMESPACE Gem
            FILES_CMAKE
                atom_rpi_builders_tests_files.cmake
            INCLUDE_DIRECTORIES
                PRIVATE
                    .
                    Tests
                    Source/RPI.Builders
            BUILD_DEPENDENCIES
                PRIVATE
                    AZ::AzTest
                    AZ::AzFramework
                    Gem::${gem_name}.Builders.Private.Object
        )
        o3de_add_googletest(
            NAME Gem::${gem_name}.Builders.Tests
            LABELS REQUIRES_tiaf
        )
    endif()
endif()
