#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(pal_code_include_path ${CMAKE_CURRENT_LIST_DIR}/Include/Platform/${O3DE_PAL_PLATFORM_NAME})
set(pal_common_code_include_path ${CMAKE_CURRENT_LIST_DIR}/Include/Platform/Common)

set(pal_code_source_path ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/${O3DE_PAL_PLATFORM_NAME})
set(pal_common_code_source_path ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/Common)

include(${pal_code_source_path}/PAL_${O3DE_PAL_PLATFORM_WART}.cmake) # O3DE_PAL_TRAIT_ATOM_RHI_VULKAN_SUPPORTED / O3DE_PAL_TRAIT_ATOM_RHI_VULKAN_TARGETS_ALREADY_DEFINED

if(O3DE_PAL_TRAIT_AFTERMATH_AVAILABLE)
    set(USE_NSIGHT_AFTERMATH_DEFINE $<IF:$<CONFIG:release>,"","USE_NSIGHT_AFTERMATH">)
    set(AFTERMATH_BUILD_DEPENDENCY "3rdParty::Aftermath")
else()
    set(USE_NSIGHT_AFTERMATH_DEFINE "")
    set(AFTERMATH_BUILD_DEPENDENCY "")
endif()

if(O3DE_PAL_TRAIT_ATOM_RHI_VULKAN_TARGETS_ALREADY_DEFINED)
    return() # Vulkan targets already defined in O3DE_PAL_${O3DE_PAL_PLATFORM_WART}.cmake
endif()

set(ANDROID_USE_OCULUS_OPENXR OFF CACHE BOOL "Allows for custom behavior in the RHI related with issues that only occur on Quest devices.")
if(ANDROID_USE_OCULUS_OPENXR)
    message(STATUS "Some quirks for Quest devices may apply in the Vulkan RHI.")
    # It was found that as of April 2024 using Timeline Semaphores on Quest devices crashes the app.
    set(DISABLE_TIMELINE_SEMAPHORES_DEFINE "DISABLE_TIMELINE_SEMAPHORES") # Disables Timeline Semaphores even if the device claims to support them. 
endif()

o3de_add_target(
    NAME ${gem_name}.Glad.Static STATIC
    NAMESPACE Gem
    FILES_CMAKE
        atom_rhi_vulkan_glad_files.cmake
        ${pal_code_include_path}/platform_glad_${O3DE_PAL_PLATFORM_WART}_files.cmake
        ${pal_code_source_path}/platform_glad_${O3DE_PAL_PLATFORM_WART}_files.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            Include
            Include/Atom/RHI.Loader/Glad
            ${pal_code_include_path}
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
        PUBLIC
            3rdParty::glad_vulkan
)

o3de_add_target(
    NAME ${gem_name}.Reflect STATIC
    NAMESPACE Gem
    FILES_CMAKE
        atom_rhi_vulkan_reflect_common_files.cmake
        ${pal_code_source_path}/platform_reflect_${O3DE_PAL_PLATFORM_WART}_files.cmake
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
            AZ::AzFramework
            Gem::Atom_RHI.Reflect
            Gem::${gem_name}.Glad.Static
)

if(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    o3de_add_target(
        NAME ${gem_name}.Builders.Static STATIC
        NAMESPACE Gem
        FILES_CMAKE
            atom_rhi_vulkan_builders_common_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Source
                ${pal_code_source_path}
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
            ${pal_code_source_path}/platform_builders_${O3DE_PAL_PLATFORM_WART}_files.cmake
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
                Gem::${gem_name}.Builders.Static
                Gem::Atom_RHI.Edit
        )

endif()

if(NOT O3DE_PAL_TRAIT_ATOM_RHI_VULKAN_SUPPORTED)

    # Create alias for Atom RHI Vulkan private Gem Module
    o3de_create_alias(NAME ${gem_name}.Private NAMESPACE Gem)

    return() # Do not create the rest of the targets

endif()



o3de_add_target(
    NAME ${gem_name}.Private.Static STATIC
    NAMESPACE Gem
    FILES_CMAKE
        atom_rhi_vulkan_private_common_files.cmake
        ${pal_code_source_path}/platform_private_${O3DE_PAL_PLATFORM_WART}_files.cmake
        ${pal_code_include_path}/platform_private_${O3DE_PAL_PLATFORM_WART}_files.cmake
    PLATFORM_INCLUDE_FILES
        ${pal_code_source_path}/platform_private_static_${O3DE_PAL_PLATFORM_WART}.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
            ${pal_code_source_path}
        PUBLIC
            Include
            ${pal_code_include_path}
    BUILD_DEPENDENCIES
        PUBLIC
            AZ::AzCore
            AZ::AzFramework
            AZ::AzFramework.NativeUI
            Gem::Atom_RHI.Reflect
            Gem::${gem_name}.Reflect
            Gem::${gem_name}.Glad.Static
            3rdParty::amd_vma
            ${AFTERMATH_BUILD_DEPENDENCY}
    COMPILE_DEFINITIONS 
        PRIVATE
            ${USE_NSIGHT_AFTERMATH_DEFINE}
            ${DISABLE_TIMELINE_SEMAPHORES_DEFINE}
)

o3de_add_target(
    NAME ${gem_name}.Interface STATIC
    NAMESPACE Gem
    FILES_CMAKE
        atom_rhi_vulkan_interface_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
            ${pal_code_source_path}
        PUBLIC
            Include
            ${pal_code_include_path}
    BUILD_DEPENDENCIES
        PUBLIC
            Gem::${gem_name}.Private.Static
)

o3de_add_target(
    NAME ${gem_name}.Private ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        atom_rhi_vulkan_private_common_shared_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
            ${pal_code_source_path}
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::${gem_name}.Private.Static
            Gem::Atom_RHI.Public
            ${VULKAN_VALIDATION_LAYER}
)

# Inject the gem name into the Module source file
o3de_add_source_properties(
    SOURCES
        Source/RHI/Module.cpp
    PROPERTY COMPILE_DEFINITIONS
        VALUES
            O3DE_GEM_NAME=${gem_name}
            O3DE_GEM_VERSION=${gem_version})
