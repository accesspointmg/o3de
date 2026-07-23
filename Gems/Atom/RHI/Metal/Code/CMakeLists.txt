#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

o3de_pal_path_object_json(${gem_json_path} ${CMAKE_CURRENT_LIST_DIR}/Include/Platform/${O3DE_PAL_PLATFORM_NAME} pal_code_include_path)
set(pal_common_code_include_path ${CMAKE_CURRENT_LIST_DIR}/Include/Platform/Common)

o3de_pal_path_object_json(${gem_json_path} ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/${O3DE_PAL_PLATFORM_NAME} pal_code_source_path)
set(pal_common_code_source_path ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/Common)

include(${pal_code_source_path}/PAL2_${O3DE_PAL_PLATFORM_WART}.cmake)

if(NOT O3DE_PAL_TRAIT_ATOM_RHI_METAL_SUPPORTED)
    o3de_add_target(
        NAME ${gem_name}.Private ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
        NAMESPACE Gem
        FILES_CMAKE
            atom_rhi_metal_stub_module.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Include
                ${pal_code_include_path}
                Source
                ${pal_code_source_path}
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzCore
                Gem::Atom_RHI.Reflect
    )

    # Inject the gem name into the Module source file
    o3de_add_source_properties(
        SOURCES
        Source/Platform/Common/Unimplemented/ModuleStub_Unimplemented.cpp
        PROPERTY COMPILE_DEFINITIONS
            VALUES
                O3DE_GEM_NAME=${gem_name}
                O3DE_GEM_VERSION=${gem_version})

    if(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
        o3de_add_target(
            NAME ${gem_name}.Builders GEM_MODULE
            NAMESPACE Gem
            FILES_CMAKE
                ${pal_code_source_path}/platform_builders_${O3DE_PAL_PLATFORM_WART}_files.cmake
                atom_rhi_metal_reflect_common_files.cmake
            INCLUDE_DIRECTORIES
                PRIVATE
                    Include
                    ${pal_code_include_path}
                    Source
                    ${pal_code_source_path}
            BUILD_DEPENDENCIES
                PRIVATE
                    AZ::AzCore
                    Gem::Atom_RHI.Reflect
                    Gem::Atom_RHI.Public
        )
    endif()

    return()
endif()

o3de_add_target(
    NAME ${gem_name}.Reflect STATIC
    NAMESPACE Gem
    FILES_CMAKE
        atom_rhi_metal_reflect_common_files.cmake
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
        atom_rhi_metal_private_common_files.cmake
        ${pal_code_source_path}/platform_private_${O3DE_PAL_PLATFORM_WART}_files.cmake
    PLATFORM_INCLUDE_FILES
        ${pal_code_source_path}/platform_${O3DE_PAL_PLATFORM_WART}.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            .
            Source
            ${pal_code_source_path}
        PUBLIC
            Include
            ${pal_code_include_path}
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            AZ::AzFramework
            Gem::Atom_RHI.Reflect
            Gem::${gem_name}.Reflect
)

o3de_add_target(
    NAME ${gem_name}.Private ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        atom_rhi_metal_private_common_shared_files.cmake
    PLATFORM_INCLUDE_FILES
        ${pal_code_source_path}/platform_${O3DE_PAL_PLATFORM_WART}.cmake
        ${pal_code_source_path}/platform_shared_${O3DE_PAL_PLATFORM_WART}.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            .
            Source
            ${pal_code_source_path}
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            Gem::Atom_RHI.Reflect
            Gem::Atom_RHI.Public
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
            atom_rhi_metal_builders_common_files.cmake
            ${pal_code_include_path}/platform_builders_${O3DE_PAL_PLATFORM_WART}_files.cmake
            ${pal_code_source_path}/platform_builders_${O3DE_PAL_PLATFORM_WART}_files.cmake
        PLATFORM_INCLUDE_FILES
            ${pal_code_source_path}/platform_${O3DE_PAL_PLATFORM_WART}.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                .
                Source
                ${pal_code_source_path}
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
            atom_rhi_metal_builders_shared_files.cmake
        PLATFORM_INCLUDE_FILES
            ${pal_code_source_path}/platform_${O3DE_PAL_PLATFORM_WART}.cmake
            ${pal_code_source_path}/platform_shared_${O3DE_PAL_PLATFORM_WART}.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Source
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AssetBuilderSDK
                Gem::Atom_RHI.Edit
                Gem::Atom_RHI.Reflect
                Gem::${gem_name}.Reflect
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

    if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)

        o3de_add_target(
            NAME ${gem_name}.Builders.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
            NAMESPACE Gem
            FILES_CMAKE
                atom_rhi_metal_builders_tests_files.cmake
            PLATFORM_INCLUDE_FILES
                ${pal_code_source_path}/platform_${O3DE_PAL_PLATFORM_WART}.cmake
                ${pal_code_source_path}/platform_shared_${O3DE_PAL_PLATFORM_WART}.cmake
            INCLUDE_DIRECTORIES
                PRIVATE
                    Include
                    Source
                    ${pal_code_source_path}
            BUILD_DEPENDENCIES
                PRIVATE
                    AZ::AzTest
                    Gem::Atom_RHI.Reflect
                    Gem::${gem_name}.Reflect
                    Gem::${gem_name}.Builders.Static
        )

        o3de_add_googletest(
            NAME Gem::${gem_name}.Builders.Tests
        )
    endif()
endif()

if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
    o3de_add_target(
        NAME ${gem_name}.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
        NAMESPACE Gem
        FILES_CMAKE
            atom_rhi_metal_private_tests_files.cmake
        PLATFORM_INCLUDE_FILES
            ${pal_code_source_path}/platform_${O3DE_PAL_PLATFORM_WART}.cmake
            ${pal_code_source_path}/platform_shared_${O3DE_PAL_PLATFORM_WART}.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Include
                Source
                ${pal_code_source_path}
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzTest
                Gem::Atom_RHI.Reflect
                Gem::${gem_name}.Reflect
                Gem::${gem_name}.Private.Static
    )

    o3de_add_googletest(
        NAME Gem::${gem_name}.Tests
    )
endif()
