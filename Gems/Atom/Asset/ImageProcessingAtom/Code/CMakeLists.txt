#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

o3de_add_target(
    NAME ${gem_name}.Headers HEADERONLY
    NAMESPACE Gem
    FILES_CMAKE
        imageprocessingatom_headers_files.cmake
    INCLUDE_DIRECTORIES
        INTERFACE
            Include
)

if(NOT O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    return()
endif()

set(pal_tools_files)
set(pal_tools_include_files)
set(pal_tools_include_dirs)
foreach(enabled_platform ${O3DE_PAL_TOOLS_ENABLED})
    o3de_pal_platform_name_wart(enabled_platform_wart ${enabled_platform})
    o3de_pal_path_object_json(${gem_json_path} ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/${enabled_platform} pal_tools_source_dir)
    list(APPEND pal_tools_include_dirs ${pal_tools_source_dir})
    list(APPEND pal_tools_files ${pal_tools_source_dir}/pal_tools_${enabled_platform_wart}.cmake)
    list(APPEND pal_tools_include_files ${pal_tools_source_dir}/pal_tools_${enabled_platform_wart}_files.cmake)
endforeach()

o3de_pal_path_object_json(${gem_json_path} ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/${O3DE_PAL_PLATFORM_NAME} pal_code_source_path)
set(common_code_source_path ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/Common)

o3de_add_target(
    NAME ${gem_name}.Editor.Static STATIC
    NAMESPACE Gem
    AUTOMOC
    AUTOUIC
    AUTORCC
    FILES_CMAKE
        imageprocessing_files.cmake
        ${pal_tools_include_files}
        ${pal_code_source_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
    PLATFORM_INCLUDE_FILES
        ${pal_code_source_path}/platform_${O3DE_PAL_PLATFORM_WART}.cmake
        ${common_code_source_path}/${O3DE_PAL_TRAIT_COMPILER_ID}/imageprocessingatom_editor_static_${O3DE_PAL_TRAIT_COMPILER_ID_LOWERCASE}.cmake
        ${pal_tools_files}
    INCLUDE_DIRECTORIES
        PUBLIC
            Include
            ${pal_code_source_path}
            ${pal_tools_include_dirs}
            .
            Source
            ../External/CubeMapGen
    BUILD_DEPENDENCIES
        PUBLIC
            3rdParty::Qt::Core
            3rdParty::Qt::Widgets
            3rdParty::Qt::Gui
            3rdParty::astc-encoder
            3rdParty::squish-ccr
            3rdParty::TIFF
            3rdParty::ISPCTexComp
            3rdParty::OpenEXR
            AZ::AzFramework
            AZ::AzToolsFramework
            AZ::AzQtComponents
            AZ::AssetBuilderSDK
            AZ::AtomCore
            Gem::Atom_RPI.Public
            Gem::Atom_RHI.Reflect
            Gem::Atom_Utils.Static

)
o3de_add_source_properties(
    SOURCES
        Source/Processing/ImageConvert.cpp
        Source/BuilderSettings/BuilderSettingManager.cpp
    PROPERTY COMPILE_DEFINITIONS 
    VALUES ${O3DE_PAL_TOOLS_DEFINES}
)

o3de_add_target(
    NAME ${gem_name}.Editor GEM_MODULE

    NAMESPACE Gem
    FILES_CMAKE
        imageprocessingatom_shared_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::${gem_name}.Editor.Static
)

# Inject the gem name into the Module source file
o3de_add_source_properties(
    SOURCES
        Source/ImageProcessingModule.cpp
    PROPERTY COMPILE_DEFINITIONS
        VALUES
            O3DE_GEM_NAME=${gem_name}
            O3DE_GEM_VERSION=${gem_version})

################################################################################
# Tests
################################################################################
if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
    o3de_add_target(
        NAME ${gem_name}.Editor.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
        NAMESPACE Gem
        FILES_CMAKE
            imageprocessing_tests_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Tests
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzTest
                Gem::${gem_name}.Editor.Static
    )
    o3de_add_googletest(
        NAME Gem::${gem_name}.Editor.Tests
        LABELS REQUIRES_tiaf
    )
endif()
