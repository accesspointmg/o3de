#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(pal_code_include_path ${CMAKE_CURRENT_LIST_DIR}/Include/Platform/${O3DE_PAL_PLATFORM_NAME})
set(pal_common_include_path ${CMAKE_CURRENT_LIST_DIR}/Include/Platform/Common)

set(pal_code_source_path ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/${O3DE_PAL_PLATFORM_NAME})
set(pal_common_code_source_path ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/Common)

include(${pal_code_source_path}/PAL_${O3DE_PAL_PLATFORM_WART}.cmake) # O3DE_PAL_TRAIT_ATOM_RHI_DX12_SUPPORTED

if(O3DE_PAL_TRAIT_AFTERMATH_AVAILABLE)
    set(USE_NSIGHT_AFTERMATH_DEFINE $<IF:$<CONFIG:release>,"","USE_NSIGHT_AFTERMATH">)
    set(AFTERMATH_BUILD_DEPENDENCY "3rdParty::Aftermath")
else()
    set(USE_NSIGHT_AFTERMATH_DEFINE "")
    set(AFTERMATH_BUILD_DEPENDENCY "")
endif()

set(pal_builder_tools_files)
set(pal_builder_tools_includes)
foreach(enabled_platform ${O3DE_PAL_TOOLS_ENABLED})
    o3de_pal_platform_name_wart(enabled_platform_wart ${enabled_platform})
    set(pal_builder_source_dir ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/${enabled_platform})
    list(APPEND pal_builder_tools_includes ${pal_builder_source_dir})
    list(APPEND pal_builder_tools_files ${pal_builder_source_dir}/platform_builders_${enabled_platform_wart}_tools_files.cmake)
endforeach()

if(O3DE_PIX_ENABLED)
    set(ATOM_RHI_DX12_RHI_BUILD_DEPENDENCIES 3rdParty::pix)
endif()

if(NOT O3DE_PAL_TRAIT_ATOM_RHI_DX12_SUPPORTED)
    
    # Create stub modules. Once we support gem loading configuration, we can remove this stubbed targets
    o3de_add_target(
        NAME ${gem_name}.Private ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
        NAMESPACE Gem
        FILES_CMAKE
            atom_rhi_dx12_stub_module.cmake
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzCore
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
                atom_rhi_dx12_reflect_common_files.cmake
            INCLUDE_DIRECTORIES
                PRIVATE
                    Include
                    ${pal_code_include_path}
                    Source
                    ${pal_code_source_path}
            BUILD_DEPENDENCIES
                PRIVATE
                    AZ::AzCore
                    AZ::AssetBuilderSDK
                    Gem::Atom_RHI.Edit
                    Gem::Atom_RHI.Reflect
        )
    endif()

    return() # Do not create the rest of the targets

endif()

o3de_add_target(
    NAME Amd_DX12MA STATIC
    NAMESPACE Gem
    FILES_CMAKE
        amd_dx12ma_files.cmake
    PLATFORM_INCLUDE_FILES
        ${pal_common_code_source_path}/${O3DE_PAL_TRAIT_COMPILER_ID}/amd_dx12ma_${O3DE_PAL_TRAIT_COMPILER_ID_LOWERCASE}.cmake
    INCLUDE_DIRECTORIES
        INTERFACE
            ../External/AMD_D3D12MemoryAllocator/v2.0.1
)

o3de_add_target(
    NAME OpenSSL_md5 STATIC
    NAMESPACE Gem
    FILES_CMAKE
        openssl_md5_files.cmake
    INCLUDE_DIRECTORIES
        INTERFACE
            ../External/md5
)

o3de_add_target(
    NAME ${gem_name}.Reflect STATIC
    NAMESPACE Gem
    FILES_CMAKE
        atom_rhi_dx12_reflect_common_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
            ${pal_code_source_path}
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
        atom_rhi_dx12_private_common_files.cmake
        ${pal_code_source_path}/platform_private_${O3DE_PAL_PLATFORM_WART}_files.cmake
    PLATFORM_INCLUDE_FILES
        ${pal_code_source_path}/platform_private_${O3DE_PAL_PLATFORM_WART}.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
            ${pal_code_source_path}
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PUBLIC
            AZ::AzCore
            AZ::AzFramework
            Gem::Atom_RHI.Reflect
            Gem::${gem_name}.Reflect
            Gem::Amd_DX12MA
            3rdParty::d3dx12
            ${AFTERMATH_BUILD_DEPENDENCY}
        PRIVATE
            Gem::OpenSSL_md5
            ${ATOM_RHI_DX12_RHI_BUILD_DEPENDENCIES}
    COMPILE_DEFINITIONS 
        PRIVATE
            ${USE_NSIGHT_AFTERMATH_DEFINE}
            
)

o3de_add_target(
    NAME ${gem_name}.Interface STATIC
    NAMESPACE Gem
    FILES_CMAKE
        atom_rhi_dx12_interface_common_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
            ${pal_code_source_path}
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PUBLIC
            Gem::${gem_name}.Private.Static
)

o3de_add_target(
    NAME ${gem_name}.Private ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        atom_rhi_dx12_private_common_shared_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
            ${pal_code_source_path}
        PUBLIC
            Include
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

if(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    o3de_add_target(
        NAME ${gem_name}.Builders.Static STATIC
        NAMESPACE Gem
        FILES_CMAKE
            ${pal_code_source_path}/platform_builders_${O3DE_PAL_PLATFORM_WART}_files.cmake
            ${pal_builder_tools_files}
        INCLUDE_DIRECTORIES
            PRIVATE
                Source
                ${pal_code_source_path}
                ${pal_builder_tools_includes}
            PUBLIC
                Include
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzCore
                AZ::AssetBuilderSDK
                Gem::Atom_RHI.Reflect
                Gem::${gem_name}.Reflect
    )

    o3de_add_target(
        NAME ${gem_name}.Builders GEM_MODULE

        NAMESPACE Gem
        FILES_CMAKE
            atom_rhi_dx12_builders_common_shared_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Source
                ${pal_code_source_path}
            PUBLIC
                Include
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzCore
                Gem::Atom_RHI.Edit
                Gem::Atom_RHI.Reflect
                Gem::Atom_RHI.Public
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
endif()
