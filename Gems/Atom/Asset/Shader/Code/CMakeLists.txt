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

set(pal_code_source_path ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/${O3DE_PAL_PLATFORM_NAME})
set(common_code_source_path ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/Common)

include(${pal_code_source_path}/PAL_${O3DE_PAL_PLATFORM_WART}.cmake) #for O3DE_PAL_TRAIT_BUILD_ATOM_ASSET_SHADER_SUPPORTED

if(NOT O3DE_PAL_TRAIT_BUILD_ATOM_ASSET_SHADER_SUPPORTED)

    # Create a stub
    o3de_add_target(
        NAME ${gem_name}.Builders GEM_MODULE

        NAMESPACE Gem
        FILES_CMAKE
            atom_asset_shader_builders_stub_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Source
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
    
    # Create an alias to the old Atom_Asset_Shader.Builders target for backwards compatibility
    o3de_create_alias(NAME Atom_Asset_Shader.Builders NAMESPACE Gem TARGETS Gem::${gem_name}.Builders)
    return()

endif()

o3de_add_target(
    NAME ${gem_name}.Static STATIC
    NAMESPACE Gem
    FILES_CMAKE
        atom_asset_shader_builders_files.cmake
        ${pal_code_source_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
    PLATFORM_INCLUDE_FILES
        ${pal_code_source_path}/platform_${O3DE_PAL_PLATFORM_WART}.cmake
        ${common_code_source_path}/${O3DE_PAL_TRAIT_COMPILER_ID}/atom_asset_shader_static_${O3DE_PAL_TRAIT_COMPILER_ID_LOWERCASE}.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
            ${pal_code_source_path}
        PUBLIC
            Source/Editor
    COMPILE_DEFINITIONS
        PRIVATE
            _SCL_SECURE_NO_WARNINGS
    BUILD_DEPENDENCIES
        PUBLIC
            3rdParty::mcpp
            AZ::AssetBuilderSDK
            AZ::AtomCore
            AZ::AzCore
            AZ::AzFramework
            AZ::AzFramework
            AZ::AzToolsFramework
            Gem::Atom_RHI.Edit
            Gem::Atom_RPI.Edit
            Gem::Atom_RPI.Public
)

set(pal_builder_tools_include_files)
foreach(enabled_platform ${O3DE_PAL_TOOLS_ENABLED})
    o3de_pal_platform_name_wart(enabled_platform_wart ${enabled_platform})
    set(pal_builder_code_source_path ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/${enabled_platform})
    list(APPEND pal_builder_tools_include_files ${pal_builder_code_source_path}/platform_builders_${enabled_platform_wart}.cmake)
endforeach()

o3de_add_target(
    NAME ${gem_name}.Builders GEM_MODULE

    NAMESPACE Gem
    FILES_CMAKE
        atom_asset_shader_builders_shared_files.cmake
    PLATFORM_INCLUDE_FILES
        ${pal_code_source_path}/platform_builders_${O3DE_PAL_PLATFORM_WART}.cmake
        ${pal_builder_tools_include_files}
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
            Source/Editor
    BUILD_DEPENDENCIES
        PRIVATE
            3rdParty::mcpp
            Gem::${gem_name}.Static
            Gem::Atom_RPI.Edit
    RUNTIME_DEPENDENCIES
        3rdParty::DirectXShaderCompilerDxc
        3rdParty::SPIRVCross
        3rdParty::azslc
)

# Inject the gem name into the Module source file
o3de_add_source_properties(
    SOURCES
        Source/Editor/AzslShaderBuilderModule.cpp
    PROPERTY COMPILE_DEFINITIONS
        VALUES
            O3DE_GEM_NAME=${gem_name}
            O3DE_GEM_VERSION=${gem_version})

# Create an alias to the old Atom_Asset_Shader.Builders target for backwards compatibility
o3de_create_alias(NAME Atom_Asset_Shader.Builders NAMESPACE Gem TARGETS Gem::${gem_name}.Builders)

################################################################################
# Tests
################################################################################
if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)

    o3de_add_target(
        NAME ${gem_name}.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
        NAMESPACE Gem
        FILES_CMAKE
            atom_asset_shader_builders_tests_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                .
                Source/Editor
                Tests
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AtomCore
                AZ::AzTest
                AZ::AzFramework
                AZ::AzToolsFramework
                Legacy::CryCommon
                Gem::Atom_RPI.Public
                Gem::Atom_RHI.Public
                Gem::Atom_RPI.Edit
                Gem::${gem_name}.Static
    )
    o3de_add_googletest(
        NAME Gem::${gem_name}.Tests
        LABELS REQUIRES_tiaf
    )

endif()
