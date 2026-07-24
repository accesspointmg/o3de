#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

o3de_pal_path(${CMAKE_CURRENT_LIST_DIR}/Include/Platform/${O3DE_PAL_PLATFORM_NAME} pal_code_include_path)
set(pal_common_code_include_path ${CMAKE_CURRENT_LIST_DIR}/Include/Platform/Common)

o3de_pal_path(${CMAKE_CURRENT_LIST_DIR}/Source/Platform/${O3DE_PAL_PLATFORM_NAME} pal_code_source_path)
set(pal_common_code_source_path ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/Common)

o3de_add_target(
    NAME ${gem_name}.Reflect STATIC
    NAMESPACE Gem
    FILES_CMAKE
        atom_rhi_null_reflect_common_files.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            Include
            ${pal_code_include_path}
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            Gem::Atom_RHI.Reflect
)

o3de_add_target(
    NAME ${gem_name}.Private.Static STATIC
    NAMESPACE Gem
    FILES_CMAKE
        atom_rhi_null_private_common_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            .
            Source
            ${pal_code_source_path}
        PUBLIC
            Include
            ${pal_code_include_path}
    BUILD_DEPENDENCIES
        PUBLIC
            AZ::AzCore
            AZ::AzFramework
            AZ::AtomCore
            Gem::Atom_RHI.Public
)

o3de_add_target(
    NAME ${gem_name}.Private ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        atom_rhi_null_private_common_shared_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            .
            Source
            ${pal_code_source_path}
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::${gem_name}.Reflect
            Gem::${gem_name}.Private.Static
)

# Inject the gem name into the Module source file
o3de_add_source_properties(
    SOURCES
        Source/RHI/Module.cpp
    PROPERTY COMPILE_DEFINITIONS
        VALUES
            O3DE_GEM_NAME=${gem_name}
            O3DE_GEM_VERSION=${gem_version})

if (O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)

    o3de_add_target(
        NAME ${gem_name}.Builders.Static STATIC
        NAMESPACE Gem
        FILES_CMAKE
            atom_rhi_null_builders_common_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                .
                Source
                ${pal_code_source_path}
            PUBLIC
                Include
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AssetBuilderSDK
                Gem::Atom_RHI.Edit
                Gem::Atom_RHI.Reflect
                Gem::${gem_name}.Reflect
    )

   o3de_add_target(
        NAME ${gem_name}.Builders GEM_MODULE
        NAMESPACE Gem
        FILES_CMAKE
            atom_rhi_null_builders_shared_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Source
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AssetBuilderSDK
                Gem::Atom_RHI.Edit
                Gem::Atom_RHI.Reflect
                Gem::${gem_name}.Builders.Static
    )

    # Inject the gem name into the Module source file
    o3de_add_source_properties(
        SOURCES
            Source/RHI.Builders/BuilderModule.cpp
        PROPERTY COMPILE_DEFINITIONS
            VALUES
                O3DE_GEM_NAME=${gem_name}
                O3DE_GEM_VERSION=${gem_version})
endif()
