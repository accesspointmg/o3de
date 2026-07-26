#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(pal_code_legacy_crysystem_path ${O3DE_ENGINE_PATH}/Code/Legacy/CrySystem/Platform/${O3DE_PAL_PLATFORM_NAME})
#set(common_code_legacy_crysystem_path ${O3DE_ENGINE_PATH}/Code/Legacy/CrySystem/Platform/Common)

add_subdirectory(XML)

o3de_add_target(
    NAME CrySystem.Static STATIC
    NAMESPACE Legacy
    FILES_CMAKE
        crysystem_files.cmake
        ${pal_code_legacy_crysystem_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
    PLATFORM_INCLUDE_FILES
        ${pal_code_legacy_crysystem_path}/platform_${O3DE_PAL_PLATFORM_WART}.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            .
            ${pal_code_legacy_crysystem_path}
    BUILD_DEPENDENCIES
        PRIVATE
            3rdParty::expat
            3rdParty::lz4
            3rdParty::TIFF
            3rdParty::zstd
            Legacy::CryCommon
            Legacy::CrySystem.XMLBinary
            Legacy::RemoteConsoleCore
            AZ::AzFramework
        PUBLIC
            Gem::AudioSystem.API
)

o3de_add_source_properties(
    SOURCES SystemInit.cpp
    PROPERTY COMPILE_DEFINITIONS 
    VALUES ${O3DE_PAL_TOOLS_DEFINES}
)

o3de_add_target(
    NAME CrySystem ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_LIBRARY_TYPE}
    NAMESPACE Legacy
    FILES_CMAKE
        crysystem_shared_files.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            .
    BUILD_DEPENDENCIES
        PRIVATE
            Legacy::CrySystem.Static
            AZ::AzCore
            Legacy::CryCommon
)
