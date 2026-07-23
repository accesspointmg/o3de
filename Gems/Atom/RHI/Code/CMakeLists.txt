#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

o3de_pal_path_object_json(${gem_json_path} ${CMAKE_CURRENT_LIST_DIR}/Platform/${O3DE_PAL_PLATFORM_NAME} pal_code_path)
#set(pal_common_code_path ${CMAKE_CURRENT_LIST_DIR}/Platform/Common)

o3de_pal_path_object_json(${gem_json_path} ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/${O3DE_PAL_PLATFORM_NAME} pal_code_source_path)
#set(pal_common_code_source_path ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/Common)

include(${pal_code_path}/AtomRHITests_traits_${O3DE_PAL_PLATFORM_WART}.cmake)

o3de_add_target(
    NAME ${gem_name}.Profiler STATIC
    NAMESPACE Gem
    FILES_CMAKE
        atom_rhi_profiler_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            AZ::AzFramework
)

if(O3DE_PAL_TRAIT_BUILD_RENDERDOC_SUPPORTED)  
    set(O3DE_RENDERDOC_ENABLED OFF CACHE BOOL "Enable RenderDoc integration. Use O3DE_RENDERDOC_PATH to specific the path to RenderDoc.")
    if(O3DE_RENDERDOC_ENABLED)
        message(STATUS "Renderdoc found, enabling as a graphics debugger")
        o3de_add_target(
            NAME ${gem_name}.Profiler.RenderDoc ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
            NAMESPACE Gem
            FILES_CMAKE
                atom_rhi_profiler_renderdoc_shared_files.cmake
            INCLUDE_DIRECTORIES
                PRIVATE
                    Source
                    ${pal_code_source_path}
                PUBLIC
                    Include
            BUILD_DEPENDENCIES
                PRIVATE
                    AZ::AzCore
                    AZ::AzFramework
                    Gem::${gem_name}.Profiler
                    3rdParty::renderdoc
        )

        list(APPEND PROFILER_DEPENDENCIES ${gem_name}.Profiler.RenderDoc)
    endif()
endif()

if(O3DE_PAL_TRAIT_PROF_PIX_SUPPORTED)
    if(O3DE_PIX_ENABLED)
        o3de_add_target(
            NAME ${gem_name}.Profiler.PIX ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
            NAMESPACE Gem
            FILES_CMAKE
                atom_rhi_profiler_pix_shared_files.cmake
                ${pal_code_source_path}/platform_pix_${O3DE_PAL_PLATFORM_WART}_files.cmake
            INCLUDE_DIRECTORIES
                PRIVATE
                    Source
                    ${pal_code_source_path}
                PUBLIC
                    Include
            BUILD_DEPENDENCIES
                PRIVATE
                    AZ::AzCore
                    AZ::AzFramework
                    Gem::${gem_name}.Profiler
                    3rdParty::pix
        )

        list(APPEND PROFILER_DEPENDENCIES ${gem_name}.Profiler.PIX)
    endif()
endif()

o3de_add_target(
    NAME ${gem_name}.Reflect ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_LIBRARY_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        atom_rhi_reflect_files.cmake
    COMPILE_DEFINITIONS
        PRIVATE
            ATOM_RHI_REFLECT_EXPORTS
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            AZ::AzFramework
        PUBLIC
            AZ::AtomCore
)

o3de_add_target(
    NAME ${gem_name}.Public ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_LIBRARY_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        atom_rhi_public_files.cmake
        ../Assets/atom_rhi_asset_files.cmake
        ${pal_code_source_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
    COMPILE_DEFINITIONS
        PRIVATE
            ATOM_RHI_PUBLIC_EXPORTS
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
            ${pal_code_source_path}
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            AZ::AzFramework
        PUBLIC
            Gem::${gem_name}.Reflect
)

o3de_add_target(
    NAME ${gem_name}.Private.Object OBJECT
    NAMESPACE Gem
    FILES_CMAKE
        atom_rhi_private_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            AZ::AzFramework
            AZ::AtomCore
            Gem::${gem_name}.Public
)

o3de_add_target(
    NAME ${gem_name}.Private ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        atom_rhi_private_shared_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            Gem::${gem_name}.Public
            Gem::${gem_name}.Private.Object
            Gem::${gem_name}.Profiler
    RUNTIME_DEPENDENCIES
        ${PROFILER_DEPENDENCIES}            
)

# Inject the gem name into the Module source file
o3de_add_source_properties(
    SOURCES
        Source/Module.cpp
    PROPERTY COMPILE_DEFINITIONS
        VALUES
            O3DE_GEM_NAME=${gem_name}
            O3DE_GEM_VERSION=${gem_version})

if(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    if (ATOM_RHI_TRAIT_BUILD_SUPPORTS_EDIT)
        o3de_add_target(
            NAME ${gem_name}.Edit STATIC
            NAMESPACE Gem
            FILES_CMAKE
                atom_rhi_edit_files.cmake
            INCLUDE_DIRECTORIES
                PRIVATE
                    Source
                PUBLIC
                    Include
            BUILD_DEPENDENCIES
                PRIVATE
                    AZ::AzToolsFramework
                    AZ::AtomCore
                    Gem::${gem_name}.Public
        )
    endif()
endif()

################################################################################
# Tests
################################################################################
if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)

    if (ATOM_RHI_TRAIT_BUILD_SUPPORTS_TEST)
        o3de_add_target(
            NAME ${gem_name}.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
            NAMESPACE Gem
            FILES_CMAKE
                atom_rhi_tests_files.cmake
            INCLUDE_DIRECTORIES
                PRIVATE
                    .
                    Tests
            BUILD_DEPENDENCIES
                PRIVATE
                    AZ::AzTest
                    AZ::AzFramework
                    Gem::${gem_name}.Edit
                    Gem::${gem_name}.Public
                    Gem::Atom_Feature_Common.Public
        )
        o3de_add_googletest(
            NAME Gem::${gem_name}.Tests
            LABELS REQUIRES_tiaf
        )

        o3de_add_target_files(
            TARGETS
                ${gem_name}.Tests
            FILES
                ${CMAKE_CURRENT_SOURCE_DIR}/Tests/UtilsTestsData/DummyTransformColor.MainPS.dx12.dxil.txt
                ${CMAKE_CURRENT_SOURCE_DIR}/Tests/UtilsTestsData/DummyTransformColor.MainPS.vulkan.spirv.txt
                ${CMAKE_CURRENT_SOURCE_DIR}/Tests/UtilsTestsData/HelloWorld.txt
            OUTPUT_SUBDIRECTORY
                Gems/Atom/RHI/Code/Tests/UtilsTestsData
        )
    endif()
endif()
